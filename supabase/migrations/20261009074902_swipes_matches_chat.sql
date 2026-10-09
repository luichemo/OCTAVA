-- OCTAVA v1: swipes, matches, one-on-one chat, blocks, reports, and the swipe deck.
--
-- Clients never write swipes or matches directly: record_swipe() checks the
-- rules and creates a match when both people chose "jam". get_deck() builds
-- the list of people to swipe on, applying age group, blocks and filters.

create type public.swipe_decision as enum ('pass', 'jam');
create type public.report_reason as enum ('spam', 'harassment', 'inappropriate', 'fake_profile', 'underage', 'other');

-- ---------------------------------------------------------------- tables

create table public.swipes (
  swiper_id uuid not null references public.profiles (id) on delete cascade,
  target_id uuid not null references public.profiles (id) on delete cascade,
  decision public.swipe_decision not null,
  created_at timestamptz not null default now(),
  primary key (swiper_id, target_id),
  check (swiper_id <> target_id)
);
create index swipes_target_idx on public.swipes (target_id, swiper_id);

-- One row per pair; user_a is always the smaller id.
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_a, user_b),
  check (user_a < user_b)
);
create index matches_user_b_idx on public.matches (user_b);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches (id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index messages_match_idx on public.messages (match_id, created_at);
create index messages_sender_idx on public.messages (sender_id);

create table public.blocks (
  blocker_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  reported_id uuid not null references public.profiles (id) on delete cascade,
  reason public.report_reason not null,
  details text check (char_length(details) <= 1000),
  created_at timestamptz not null default now(),
  check (reporter_id <> reported_id)
);
create index reports_reporter_idx on public.reports (reporter_id);
create index reports_reported_idx on public.reports (reported_id);

-- ---------------------------------------------------------------- helpers

create function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  );
$$;

-- The caller may send messages in this match: they're in it, nobody has
-- blocked anyone, and both are still in the same age group (a teen who
-- matched another teen can't keep chatting one-on-one once one turns 18).
create function public.can_message(target_match uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.matches m
    where m.id = target_match
      and auth.uid() in (m.user_a, m.user_b)
      and not public.is_blocked_between(m.user_a, m.user_b)
      and public.same_age_group(case when m.user_a = auth.uid() then m.user_b else m.user_a end)
  );
$$;

create function public.distance_km(lat1 double precision, lng1 double precision,
                                   lat2 double precision, lng2 double precision)
returns double precision
language sql
immutable
set search_path = ''
as $$
  select 2 * 6371 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2)
    + cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

-- ---------------------------------------------------------------- swiping

-- Records a Jam or Pass. Returns the match id when both people chose Jam,
-- otherwise null. Swiping again on the same person replaces the old choice.
create function public.record_swipe(target uuid, decision public.swipe_decision)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
  match_id uuid;
begin
  if me is null then
    raise exception 'Sign in first' using errcode = 'insufficient_privilege';
  end if;
  if target = me then
    raise exception 'You can''t swipe on yourself' using errcode = 'check_violation';
  end if;
  if not exists (select 1 from public.profiles where id = target)
     or not public.same_age_group(target)
     or public.is_blocked_between(me, target) then
    raise exception 'This person isn''t available' using errcode = 'check_violation';
  end if;

  insert into public.swipes (swiper_id, target_id, decision)
  values (me, target, record_swipe.decision)
  on conflict (swiper_id, target_id)
  do update set decision = excluded.decision, created_at = now();

  if record_swipe.decision = 'jam' and exists (
    select 1 from public.swipes s
    where s.swiper_id = target and s.target_id = me and s.decision = 'jam'
  ) then
    insert into public.matches (user_a, user_b)
    values (least(me, target), greatest(me, target))
    on conflict (user_a, user_b) do nothing;

    select m.id into match_id from public.matches m
    where m.user_a = least(me, target) and m.user_b = greatest(me, target);
  end if;

  return match_id;
end;
$$;

-- People to swipe on, nearest first. Every filter is optional (null = any).
-- Skips: yourself, people you've already swiped, blocks in either direction,
-- and anyone outside your age group. Distances are whole km (minimum 1), so
-- exact locations can't be worked out.
create function public.get_deck(
  max_km double precision default 25,
  instrument_ids text[] default null,
  min_skill public.skill_level default null,
  genre_filter text[] default null,
  goal_filter public.goal[] default null,
  frequency_filter public.rehearsal_frequency[] default null,
  max_results int default 20
)
returns table (
  id uuid,
  display_name text,
  age int,
  area text,
  distance_km int,
  looking_for text,
  genres text[],
  influences text[],
  goals public.goal[],
  rehearsal_frequency public.rehearsal_frequency,
  availability_note text,
  has_own_gear boolean,
  has_car boolean,
  has_rehearsal_space boolean,
  has_home_studio boolean,
  instruments jsonb,
  links jsonb,
  clips jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  with me as (
    select p.id, p.lat, p.lng from public.profiles p where p.id = auth.uid()
  ),
  candidates as (
    select p.*,
      case when me.lat is not null and p.lat is not null
        then public.distance_km(me.lat, me.lng, p.lat, p.lng) end as km
    from public.profiles p, me
    where p.id <> me.id
      and public.same_age_group(p.id)
      and not public.is_blocked_between(me.id, p.id)
      and not exists (select 1 from public.swipes s where s.swiper_id = me.id and s.target_id = p.id)
      and (genre_filter is null or p.genres && (select array_agg(lower(g)) from unnest(genre_filter) g))
      and (goal_filter is null or p.goals && goal_filter)
      and (frequency_filter is null or p.rehearsal_frequency = any (frequency_filter))
      and (instrument_ids is null or exists (
        select 1 from public.profile_instruments pi
        where pi.profile_id = p.id
          and pi.instrument_id = any (instrument_ids)
          and (min_skill is null or pi.skill >= min_skill)
      ))
  )
  select
    c.id, c.display_name, public.age_of(c.id), c.area,
    case when c.km is not null then greatest(1, round(c.km))::int end,
    c.looking_for, c.genres, c.influences, c.goals, c.rehearsal_frequency,
    c.availability_note, c.has_own_gear, c.has_car, c.has_rehearsal_space, c.has_home_studio,
    coalesce((select jsonb_agg(jsonb_build_object('instrument', pi.instrument_id, 'skill', pi.skill, 'is_primary', pi.is_primary)
                               order by pi.is_primary desc, pi.instrument_id)
              from public.profile_instruments pi where pi.profile_id = c.id), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('kind', l.kind, 'url', l.url))
              from public.profile_links l where l.profile_id = c.id), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'path', a.storage_path, 'title', a.title, 'seconds', a.duration_seconds)
                               order by a.created_at)
              from public.audio_clips a where a.profile_id = c.id), '[]'::jsonb)
  from candidates c
  where max_km is null or c.km is null or c.km <= max_km
  order by c.km asc nulls last, c.created_at desc
  limit least(greatest(max_results, 1), 50);
$$;

-- ---------------------------------------------------------------- row level security

alter table public.swipes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;

-- Swipes: you can see your own; writes go through record_swipe().
create policy "Read own swipes"
  on public.swipes for select to authenticated using (swiper_id = (select auth.uid()));

-- Matches: visible to the two people; either can unmatch. Created by record_swipe().
create policy "Read own matches"
  on public.matches for select to authenticated
  using ((select auth.uid()) in (user_a, user_b));
create policy "Unmatch"
  on public.matches for delete to authenticated
  using ((select auth.uid()) in (user_a, user_b));

-- Messages: readable by the two people in the match; sending also requires
-- no blocks and the same age group (see can_message).
create policy "Read messages in own matches"
  on public.messages for select to authenticated
  using (exists (
    select 1 from public.matches m
    where m.id = match_id and (select auth.uid()) in (m.user_a, m.user_b)
  ));
create policy "Send messages in own matches"
  on public.messages for insert to authenticated
  with check (sender_id = (select auth.uid()) and public.can_message(match_id));

-- Blocks: manage your own list.
create policy "Read own blocks"
  on public.blocks for select to authenticated using (blocker_id = (select auth.uid()));
create policy "Block someone"
  on public.blocks for insert to authenticated with check (blocker_id = (select auth.uid()));
create policy "Unblock"
  on public.blocks for delete to authenticated using (blocker_id = (select auth.uid()));

-- Reports: anyone can file one; only the admin (dashboard) can read them.
create policy "File a report"
  on public.reports for insert to authenticated with check (reporter_id = (select auth.uid()));

-- ---------------------------------------------------------------- grants

revoke all on public.swipes, public.matches, public.messages, public.blocks, public.reports from anon;
revoke insert, update, delete on public.swipes from authenticated;
revoke insert, update on public.matches from authenticated;
revoke update, delete on public.messages from authenticated;
revoke update on public.blocks from authenticated;
revoke select, update, delete on public.reports from authenticated;

revoke execute on function public.is_blocked_between(uuid, uuid), public.can_message(uuid),
  public.distance_km(double precision, double precision, double precision, double precision),
  public.record_swipe(uuid, public.swipe_decision),
  public.get_deck(double precision, text[], public.skill_level, text[], public.goal[], public.rehearsal_frequency[], int)
  from public, anon;
grant execute on function public.record_swipe(uuid, public.swipe_decision),
  public.get_deck(double precision, text[], public.skill_level, text[], public.goal[], public.rehearsal_frequency[], int),
  public.can_message(uuid)
  to authenticated;
-- is_blocked_between stays private: it would let anyone check whether two
-- other people have blocked each other. The functions above use it internally.

-- ---------------------------------------------------------------- realtime
-- New matches and messages are pushed to the app (RLS still applies).
alter publication supabase_realtime add table public.matches, public.messages;
