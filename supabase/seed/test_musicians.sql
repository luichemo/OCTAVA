-- Adds the 8 sample musicians from the prototype as real (adult) profiles,
-- for trying swiping and matching during development.
-- * They can't sign in: no password, emails end in @test.octava.invalid.
-- * Nika, Luka, Tamar and Dato have already chosen "Jam" on every real adult
--   profile that exists when this runs, so a Jam back makes a match.
-- * Remove them with supabase/seed/remove_test_musicians.sql.
-- Run in the Supabase SQL editor (or via the MCP execute_sql tool). Safe to re-run.

with people (n, name, age, instrument, skill, area, lat, lng, genres, looking_for, freq, goals, likes_you) as (
  values
    (1, 'Nika',   24, 'drums',  'intermediate', 'Vera',        41.705, 44.780, '{post-punk,math rock}',   'A band that rehearses twice a week and actually plays shows.', 'several_a_week', '{gigging}',          true),
    (2, 'Mariam', 27, 'bass',   'advanced',     'Sololaki',    41.689, 44.802, '{funk,neo-soul}',         'Groove-first people. I have a car and a key to a rehearsal room.', 'weekly',     '{fun,gigging}',      false),
    (3, 'Luka',   22, 'vocals', 'intermediate', 'Saburtalo',   41.727, 44.751, '{alt rock,grunge}',       'I write lyrics in Georgian and English. I need a band to make them loud.', 'weekly', '{gigging,recording}', true),
    (4, 'Tamar',  30, 'keys',   'pro',          'Vake',        41.709, 44.760, '{jazz,synth-pop}',        'Classically trained, recovering. I want to play over a drum machine.', 'monthly',  '{recording}',        true),
    (5, 'Giorgi', 26, 'drums',  'advanced',     'Didube',      41.739, 44.778, '{metal,hardcore}',        'Double kick, my own kit, no excuses.', 'several_a_week',                       '{gigging,paid}',     false),
    (6, 'Ana',    25, 'vocals', 'beginner',     'Mtatsminda',  41.694, 44.789, '{indie folk,dream pop}',  'Harmonies are my favourite part of any song.', 'occasionally',                  '{fun}',              false),
    (7, 'Dato',   29, 'bass',   'intermediate', 'Nadzaladevi', 41.748, 44.793, '{post-rock,shoegaze}',    'Long songs, lots of pedals, quiet and then very loud.', 'weekly',               '{fun,recording}',    true),
    (8, 'Salome', 23, 'keys',   'intermediate', 'Avlabari',    41.692, 44.812, '{city pop,disco}',        'I want our first gig to be on a rooftop in June.', 'weekly',                    '{gigging}',          false)
),
ids as (
  select p.*, ('00000000-0000-4000-8000-0000000000a' || p.n)::uuid as id from people p
),
new_users as (
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, created_at, updated_at)
  select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
         lower(name) || '@test.octava.invalid', '', now(), now()
  from ids
  on conflict (id) do nothing
  returning id
),
new_private as (
  insert into public.profile_private (id, birth_date)
  select id, (current_date - make_interval(years => age) - interval '40 days')::date from ids
  where id in (select id from new_users)
  returning id
),
new_profiles as (
  insert into public.profiles (id, display_name, area, lat, lng, genres, looking_for, rehearsal_frequency, goals,
                               has_own_gear, has_car, has_rehearsal_space)
  select i.id, i.name, i.area, i.lat, i.lng, i.genres::text[], i.looking_for,
         i.freq::public.rehearsal_frequency, i.goals::public.goal[],
         true, i.name in ('Mariam', 'Giorgi'), i.name = 'Mariam'
  from ids i join new_private np on np.id = i.id
  returning id
),
new_instruments as (
  insert into public.profile_instruments (profile_id, instrument_id, skill, is_primary)
  select i.id, i.instrument, i.skill::public.skill_level, true
  from ids i join new_profiles np on np.id = i.id
  returning profile_id
)
select count(*) as musicians_added from new_instruments;

-- The four who already like you: a Jam from them to every real adult profile.
insert into public.swipes (swiper_id, target_id, decision)
select t.id, p.id, 'jam'
from public.profiles t
cross join public.profiles p
join auth.users u on u.id = p.id
where t.id in ('00000000-0000-4000-8000-0000000000a1', '00000000-0000-4000-8000-0000000000a3',
               '00000000-0000-4000-8000-0000000000a4', '00000000-0000-4000-8000-0000000000a7')
  and u.email not like '%@test.octava.invalid'
  and private.age_of(p.id) >= 18
on conflict (swiper_id, target_id) do nothing;
