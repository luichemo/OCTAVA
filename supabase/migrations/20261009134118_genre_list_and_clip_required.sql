-- OCTAVA: genres from a fixed list, and only musicians with a clip in decks.
-- * genres table: the ids the app offers (labels are translated in the app).
--   profiles.genres must only contain these; existing free-text genres are
--   converted (spaces -> hyphens, "bloose" -> blues) and unknown ones dropped.
-- * get_deck skips people without at least one audio clip.

create table public.genres (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  sort_order int not null
);
insert into public.genres (id, sort_order) values
  ('rock', 1),
  ('pop', 2),
  ('indie', 3),
  ('alt-rock', 4),
  ('punk', 5),
  ('post-punk', 6),
  ('hardcore', 7),
  ('metal', 8),
  ('grunge', 9),
  ('math-rock', 10),
  ('post-rock', 11),
  ('shoegaze', 12),
  ('dream-pop', 13),
  ('synth-pop', 14),
  ('city-pop', 15),
  ('disco', 16),
  ('funk', 17),
  ('soul', 18),
  ('neo-soul', 19),
  ('r-and-b', 20),
  ('hip-hop', 21),
  ('rap', 22),
  ('jazz', 23),
  ('blues', 24),
  ('gospel', 25),
  ('electronic', 26),
  ('techno', 27),
  ('house', 28),
  ('ambient', 29),
  ('lo-fi', 30),
  ('experimental', 31),
  ('folk', 32),
  ('indie-folk', 33),
  ('georgian-folk', 34),
  ('singer-songwriter', 35),
  ('country', 36),
  ('reggae', 37),
  ('ska', 38),
  ('latin', 39),
  ('world', 40),
  ('classical', 41),
  ('soundtrack', 42);

alter table public.genres enable row level security;
create policy "Genres are readable by signed-in users"
  on public.genres for select to authenticated using (true);
revoke all on public.genres from anon;

update public.profiles p
set genres = coalesce(array(
  select distinct m.id
  from unnest(p.genres) g
  cross join lateral (
    select case lower(btrim(g)) when 'bloose' then 'blues' when 'blues rock' then 'blues'
           else replace(lower(btrim(g)), ' ', '-') end as id
  ) m
  where m.id in (select id from public.genres)
), '{}');

create function public.check_genres()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if exists (select 1 from unnest(new.genres) g where g not in (select id from public.genres)) then
    raise exception 'Pick genres from the list' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

-- Runs after profiles_before_write (triggers fire in name order), which
-- lower-cases and de-duplicates the genres first.
create trigger profiles_check_genres
  before insert or update of genres on public.profiles
  for each row execute function public.check_genres();

revoke execute on function public.check_genres() from public, anon, authenticated;

-- Same as before, plus: only people with at least one clip.
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
  avatar_path text,
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
      -- Only people others can hear: at least one audio clip.
      and exists (select 1 from public.audio_clips a where a.profile_id = p.id)
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
    c.avatar_path,
    coalesce((select jsonb_agg(jsonb_build_object('instrument', pi.instrument_id, 'skill', pi.skill, 'is_primary', pi.is_primary)
                               order by pi.is_primary desc, pi.instrument_id)
              from public.profile_instruments pi where pi.profile_id = c.id), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('kind', l.kind, 'url', l.url))
              from public.profile_links l where l.profile_id = c.id), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'path', a.storage_path, 'title', a.title, 'seconds', a.duration_seconds)
                               order by (a.id = c.featured_clip_id) desc, a.created_at)
              from public.audio_clips a where a.profile_id = c.id), '[]'::jsonb)
  from candidates c
  where max_km is null or c.km is null or c.km <= max_km
  order by c.km asc nulls last, c.created_at desc
  limit least(greatest(max_results, 1), 50);
$$;

