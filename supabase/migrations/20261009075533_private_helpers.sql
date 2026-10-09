-- OCTAVA v1: move internal helper functions out of the API.
--
-- Supabase grants EXECUTE on new public functions to signed-in users, which
-- exposes every public function as /rest/v1/rpc/<name>. Helpers now live in a
-- "private" schema the API doesn't expose. Only the intended actions stay
-- public: get_deck, record_swipe, set_my_location.
-- Also splits "Manage own ..." policies so SELECT has a single policy.

create schema if not exists private;
grant usage on schema private to authenticated;

-- Policies point at functions by id, so they follow the move.
alter function public.age_of(uuid) set schema private;
alter function public.same_age_group(uuid) set schema private;
alter function public.is_blocked_between(uuid, uuid) set schema private;
alter function public.can_message(uuid) set schema private;
alter function public.distance_km(double precision, double precision, double precision, double precision) set schema private;
alter function public.clip_owner(text) set schema private;

-- Function bodies name other helpers, so recreate them with the new names.
create or replace function private.same_age_group(other uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (private.age_of(auth.uid()) >= 18) = (private.age_of(other) >= 18),
    false
  );
$$;

create or replace function private.can_message(target_match uuid)
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
      and not private.is_blocked_between(m.user_a, m.user_b)
      and private.same_age_group(case when m.user_a = auth.uid() then m.user_b else m.user_a end)
  );
$$;

create or replace function public.record_swipe(target uuid, decision public.swipe_decision)
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
     or not private.same_age_group(target)
     or private.is_blocked_between(me, target) then
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

create or replace function public.get_deck(
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
        then private.distance_km(me.lat, me.lng, p.lat, p.lng) end as km
    from public.profiles p, me
    where p.id <> me.id
      and private.same_age_group(p.id)
      and not private.is_blocked_between(me.id, p.id)
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
    c.id, c.display_name, private.age_of(c.id), c.area,
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

-- Helpers: no direct calls. Signed-in users keep EXECUTE only on the ones
-- that row-level policies call (policies run with the caller's rights).
revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text)
  to authenticated;

-- Trigger functions never need to be called directly either.
revoke execute on function public.check_birth_date(), public.profiles_before_write(),
  public.limit_audio_clips()
  from public, anon, authenticated;

-- The public API: exactly these three.
revoke execute on function public.get_deck(double precision, text[], public.skill_level, text[], public.goal[], public.rehearsal_frequency[], int),
  public.record_swipe(uuid, public.swipe_decision),
  public.set_my_location(double precision, double precision)
  from public, anon;
grant execute on function public.get_deck(double precision, text[], public.skill_level, text[], public.goal[], public.rehearsal_frequency[], int),
  public.record_swipe(uuid, public.swipe_decision),
  public.set_my_location(double precision, double precision)
  to authenticated;

-- ---------------------------------------------------------------- one SELECT policy per table
-- "for all" policies also covered SELECT, overlapping the age-group read policy.

drop policy "Manage own instruments" on public.profile_instruments;
create policy "Add own instruments" on public.profile_instruments
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Edit own instruments" on public.profile_instruments
  for update to authenticated using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));
create policy "Remove own instruments" on public.profile_instruments
  for delete to authenticated using (profile_id = (select auth.uid()));

drop policy "Manage own links" on public.profile_links;
create policy "Add own links" on public.profile_links
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Edit own links" on public.profile_links
  for update to authenticated using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));
create policy "Remove own links" on public.profile_links
  for delete to authenticated using (profile_id = (select auth.uid()));

drop policy "Manage own clips" on public.audio_clips;
create policy "Add own clips" on public.audio_clips
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Edit own clips" on public.audio_clips
  for update to authenticated using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));
create policy "Remove own clips" on public.audio_clips
  for delete to authenticated using (profile_id = (select auth.uid()));
