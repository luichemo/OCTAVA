-- OCTAVA v1: profiles, private birth dates (16+), instruments, links, audio clips.
--
-- Privacy model:
--   * Birth dates live in profile_private, readable only by their owner.
--     Others see an age (via functions), never the date.
--   * Locations are rounded to ~1 km and are not readable by clients at all;
--     only distances come back, from the deck function (migration 002).
--   * 16-17 year olds and adults can't see each other's profiles in v1
--     (one-on-one matching only; teens meet adults through bands in v2).

-- ---------------------------------------------------------------- types

create type public.skill_level as enum ('beginner', 'intermediate', 'advanced', 'pro');
create type public.goal as enum ('fun', 'gigging', 'recording', 'paid');
create type public.rehearsal_frequency as enum ('occasionally', 'monthly', 'weekly', 'several_a_week');
create type public.link_kind as enum ('youtube', 'tiktok', 'instagram', 'spotify', 'soundcloud', 'bandcamp', 'other');

-- ---------------------------------------------------------------- instruments
-- Fixed list so swipe filters work. Display names are translated in the app.

create table public.instruments (
  id text primary key check (id ~ '^[a-z_]+$'),
  sort_order int not null
);

insert into public.instruments (id, sort_order) values
  ('vocals', 1), ('guitar', 2), ('bass', 3), ('drums', 4), ('keys', 5),
  ('percussion', 6), ('violin', 7), ('cello', 8), ('saxophone', 9),
  ('trumpet', 10), ('trombone', 11), ('flute', 12), ('clarinet', 13),
  ('dj', 14), ('production', 15), ('other', 99);

-- ---------------------------------------------------------------- private data

create table public.profile_private (
  id uuid primary key references auth.users (id) on delete cascade,
  birth_date date not null,
  created_at timestamptz not null default now()
);

-- 16+ only. A trigger (not a CHECK) because "today" changes.
create function public.check_birth_date()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.birth_date > (current_date - interval '16 years')::date then
    raise exception 'OCTAVA is for people aged 16 and over' using errcode = 'check_violation';
  end if;
  if new.birth_date < date '1900-01-01' then
    raise exception 'Enter a real date of birth' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger profile_private_check_birth_date
  before insert or update on public.profile_private
  for each row execute function public.check_birth_date();

-- ---------------------------------------------------------------- helpers
-- security definer: they read birth dates, which RLS hides from everyone else.

create function public.age_of(uid uuid)
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select extract(year from age(p.birth_date))::int
  from public.profile_private p
  where p.id = uid;
$$;

-- True when both people are adults, or both are 16-17.
create function public.same_age_group(other uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (public.age_of(auth.uid()) >= 18) = (public.age_of(other) >= 18),
    false
  );
$$;

-- ---------------------------------------------------------------- profiles

create table public.profiles (
  id uuid primary key references public.profile_private (id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 40),
  looking_for text check (char_length(looking_for) <= 300),
  area text check (char_length(area) <= 60),
  -- Rounded to 2 decimals (~1 km) by trigger; hidden from clients by column grants.
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  genres text[] not null default '{}' check (cardinality(genres) <= 10),
  influences text[] not null default '{}' check (cardinality(influences) <= 10),
  goals public.goal[] not null default '{}',
  rehearsal_frequency public.rehearsal_frequency,
  availability_note text check (char_length(availability_note) <= 120),
  has_own_gear boolean not null default false,
  has_car boolean not null default false,
  has_rehearsal_space boolean not null default false,
  has_home_studio boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create function public.profiles_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.lat := round(new.lat::numeric, 2)::double precision;
  new.lng := round(new.lng::numeric, 2)::double precision;
  new.genres := array(select distinct lower(btrim(g)) from unnest(new.genres) g where btrim(g) <> '');
  new.influences := array(select distinct btrim(i) from unnest(new.influences) i where btrim(i) <> '');
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_before_write
  before insert or update on public.profiles
  for each row execute function public.profiles_before_write();

-- Clients set their location only through this, so it is always rounded.
create function public.set_my_location(lat double precision, lng double precision)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.profiles
  set lat = set_my_location.lat, lng = set_my_location.lng
  where id = auth.uid();
$$;

-- ---------------------------------------------------------------- profile details

create table public.profile_instruments (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  instrument_id text not null references public.instruments (id),
  skill public.skill_level not null,
  is_primary boolean not null default false,
  primary key (profile_id, instrument_id)
);
create index profile_instruments_instrument_idx on public.profile_instruments (instrument_id);

create table public.profile_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind public.link_kind not null,
  url text not null check (url ~ '^https://' and char_length(url) <= 300)
);
create index profile_links_profile_idx on public.profile_links (profile_id);

create table public.audio_clips (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  -- Path in the "clips" storage bucket: <profile_id>/<file>
  storage_path text not null unique,
  title text check (char_length(title) <= 60),
  duration_seconds int not null check (duration_seconds between 1 and 120),
  created_at timestamptz not null default now(),
  check (storage_path like profile_id::text || '/%')
);
create index audio_clips_profile_idx on public.audio_clips (profile_id);

create function public.limit_audio_clips()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.audio_clips where profile_id = new.profile_id) >= 5 then
    raise exception 'You can upload up to 5 clips' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger audio_clips_limit
  before insert on public.audio_clips
  for each row execute function public.limit_audio_clips();

-- ---------------------------------------------------------------- row level security

alter table public.instruments enable row level security;
alter table public.profile_private enable row level security;
alter table public.profiles enable row level security;
alter table public.profile_instruments enable row level security;
alter table public.profile_links enable row level security;
alter table public.audio_clips enable row level security;

create policy "Instruments are readable by signed-in users"
  on public.instruments for select to authenticated using (true);

create policy "Read own birth date"
  on public.profile_private for select to authenticated using (id = (select auth.uid()));
create policy "Set own birth date once"
  on public.profile_private for insert to authenticated with check (id = (select auth.uid()));
-- No update/delete policy: the birth date can't be changed from the app.

create policy "Read profiles in your age group"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.same_age_group(id));
create policy "Create own profile"
  on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy "Update own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "Delete own profile"
  on public.profiles for delete to authenticated using (id = (select auth.uid()));

-- Instruments, links and clips: visible like the profile, editable by the owner.
create policy "Read instruments in your age group"
  on public.profile_instruments for select to authenticated
  using (profile_id = (select auth.uid()) or public.same_age_group(profile_id));
create policy "Manage own instruments"
  on public.profile_instruments for all to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

create policy "Read links in your age group"
  on public.profile_links for select to authenticated
  using (profile_id = (select auth.uid()) or public.same_age_group(profile_id));
create policy "Manage own links"
  on public.profile_links for all to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

create policy "Read clips in your age group"
  on public.audio_clips for select to authenticated
  using (profile_id = (select auth.uid()) or public.same_age_group(profile_id));
create policy "Manage own clips"
  on public.audio_clips for all to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

-- ---------------------------------------------------------------- grants
-- Nothing is available without signing in.
revoke all on public.instruments, public.profile_private, public.profiles,
  public.profile_instruments, public.profile_links, public.audio_clips from anon;

-- Location columns are never readable or directly writable by clients.
revoke select, insert, update on public.profiles from authenticated;
grant select (id, display_name, looking_for, area, genres, influences, goals,
  rehearsal_frequency, availability_note, has_own_gear, has_car,
  has_rehearsal_space, has_home_studio, created_at, updated_at)
  on public.profiles to authenticated;
grant insert (id, display_name, looking_for, area, genres, influences, goals,
  rehearsal_frequency, availability_note, has_own_gear, has_car,
  has_rehearsal_space, has_home_studio)
  on public.profiles to authenticated;
grant update (display_name, looking_for, area, genres, influences, goals,
  rehearsal_frequency, availability_note, has_own_gear, has_car,
  has_rehearsal_space, has_home_studio)
  on public.profiles to authenticated;

revoke update, delete on public.profile_private from authenticated;

revoke execute on function public.age_of(uuid), public.same_age_group(uuid),
  public.set_my_location(double precision, double precision),
  public.check_birth_date(), public.profiles_before_write(), public.limit_audio_clips()
  from public, anon;
grant execute on function public.age_of(uuid), public.same_age_group(uuid),
  public.set_my_location(double precision, double precision)
  to authenticated;
