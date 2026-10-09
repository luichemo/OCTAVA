-- The roles your band needs (the "Your band" row), with how many of each.
-- No rows = not chosen yet: the default five (vocals, guitar, bass, drums,
-- keys) minus your own main instrument, one each.
create table public.band_roles (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  instrument_id text not null references public.instruments (id),
  slots smallint not null default 1 check (slots between 1 and 4),
  sort_order smallint not null default 0,
  primary key (profile_id, instrument_id)
);

alter table public.band_roles enable row level security;

create policy "Read own band roles" on public.band_roles
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "Add own band roles" on public.band_roles
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Change own band roles" on public.band_roles
  for update to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));
create policy "Remove own band roles" on public.band_roles
  for delete to authenticated using (profile_id = (select auth.uid()));

revoke all on public.band_roles from anon;
grant select, insert, update, delete on public.band_roles to authenticated;

-- At most 8 slots in a lineup (besides your own).
create function private.check_band_size() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (select coalesce(sum(r.slots), 0) from public.band_roles r
      where r.profile_id = new.profile_id and r.instrument_id <> new.instrument_id)
     + new.slots > 8 then
    raise exception 'A band lineup has room for 8 people besides you';
  end if;
  return new;
end;
$$;
revoke all on function private.check_band_size() from public, anon, authenticated;

create trigger band_roles_check_size
  before insert or update on public.band_roles
  for each row execute function private.check_band_size();

-- Someone's main instrument: the primary one, else the first.
create function private.main_instrument(person uuid) returns text
language sql stable set search_path = '' as $$
  select pi.instrument_id from public.profile_instruments pi
  where pi.profile_id = person
  order by pi.is_primary desc, pi.instrument_id
  limit 1;
$$;
revoke all on function private.main_instrument(uuid) from public, anon, authenticated;

-- Roles in a person's band that no match fills yet. A match fills a slot of
-- their main instrument (blocked matches don't count), like the app's lineup.
create function private.open_band_roles(person uuid) returns setof text
language sql stable set search_path = '' as $$
  with needs as (
    select r.instrument_id, r.slots from public.band_roles r where r.profile_id = person
    union all
    select d.id, 1 from unnest(array['vocals', 'guitar', 'bass', 'drums', 'keys']) d (id)
    where not exists (select 1 from public.band_roles r where r.profile_id = person)
      and d.id is distinct from private.main_instrument(person)
  ),
  members as (
    select private.main_instrument(case when m.user_a = person then m.user_b else m.user_a end) as role
    from public.matches m
    where person in (m.user_a, m.user_b)
      and not private.is_blocked_between(m.user_a, m.user_b)
  )
  select n.instrument_id from needs n
  where n.slots > (select count(*) from members mb where mb.role = n.instrument_id);
$$;
revoke all on function private.open_band_roles(uuid) from public, anon, authenticated;

-- Same as before, except people whose main instrument fills an open role in
-- your band come first.
create or replace function public.get_deck(
  max_km double precision default 25,
  instrument_ids text[] default null,
  min_skill public.skill_level default null,
  genre_filter text[] default null,
  goal_filter public.goal[] default null,
  frequency_filter public.rehearsal_frequency[] default null,
  max_results integer default 20
)
returns table (
  id uuid, display_name text, age integer, area text, distance_km integer,
  looking_for text, genres text[], influences text[], goals public.goal[],
  rehearsal_frequency public.rehearsal_frequency, availability_note text,
  has_own_gear boolean, has_car boolean, has_rehearsal_space boolean,
  has_home_studio boolean, avatar_path text, instruments jsonb, links jsonb, clips jsonb
)
language sql stable security definer set search_path = '' as $$
  with me as (
    select p.id, p.lat, p.lng from public.profiles p where p.id = auth.uid()
  ),
  open_roles as (
    select o.role from private.open_band_roles(auth.uid()) o (role)
  ),
  candidates as (
    select p.*,
      case when me.lat is not null and p.lat is not null
        then private.distance_km(me.lat, me.lng, p.lat, p.lng) end as km,
      private.main_instrument(p.id) in (select o.role from open_roles o) as fits
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
  order by c.fits desc nulls last, c.km asc nulls last, c.created_at desc
  limit least(greatest(max_results, 1), 50);
$$;
