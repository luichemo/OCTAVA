-- A full set of test data: 12 musicians with every profile field filled in
-- (10 adults and two 16–17 year olds), matches with chats between them, and
-- three bands with profiles, members, a join request and a proposal being
-- voted on, rehearsals with answers, songs, setlists and band chat.
--
-- * Emails end in @test.octava.invalid and there's no password, so nobody
--   can sign in until a temporary one is set (see "Test data" in CLAUDE.md).
-- * Files (voice clips, AI avatars, the band clips and song recordings) are
--   added afterwards by supabase/seed/test_world_files.py, which signs in as
--   each one. Nobody appears in the feed until they have a clip.
-- * Mariam, Luka, Tamar, Dato and Levan have already chosen "Jam" on every
--   real adult profile that exists when this runs, so a Jam back is a match.
-- * Ids: people ...0b01–...0b12, bands ...0c01–...0c03.
-- * Remove everything with supabase/seed/remove_test_world.sql.
-- Run in the Supabase SQL editor (or via the MCP execute_sql tool). It runs as
-- one transaction, so a failure leaves nothing half-done.

begin;

-- --------------------------------------------------------------- people

create temporary table tw_people (
  n int, id uuid, name text, age int, area text, lat float8, lng float8,
  genres text[], influences text[], goals public.goal[], freq public.rehearsal_frequency,
  looking_for text, availability text,
  own_gear bool, car bool, space bool, studio bool,
  instruments jsonb, links jsonb, needs jsonb
) on commit drop;

insert into tw_people values
  (1, '00000000-0000-4000-8000-000000000b01', 'Nika', 24, 'Vera', 41.705, 44.780,
   '{post-punk,math-rock,indie}', '{Fugazi,Battles,"Idles"}', '{gigging,recording}', 'several_a_week',
   'A band that rehearses twice a week and actually plays shows. Odd time signatures welcome.',
   'Weeknights after 19:00, Saturdays.', true, false, false, false,
   '[{"i":"drums","s":"advanced"},{"i":"percussion","s":"intermediate"}]',
   '[{"k":"youtube","u":"https://youtube.com/@nika-drums"},{"k":"instagram","u":"https://instagram.com/nika.drums"}]',
   '{"vocals":1,"keys":1}'),
  (2, '00000000-0000-4000-8000-000000000b02', 'Mariam', 27, 'Sololaki', 41.689, 44.802,
   '{neo-soul,funk,r-and-b}', '{"Erykah Badu",D''Angelo,"Hiatus Kaiyote"}', '{gigging,paid}', 'weekly',
   'Singer who loves groove-first players. I have a car and a key to a rehearsal room.',
   'Evenings, not Sundays.', false, true, true, false,
   '[{"i":"vocals","s":"pro"},{"i":"keys","s":"intermediate"}]',
   '[{"k":"spotify","u":"https://open.spotify.com/artist/mariam-sings"},{"k":"instagram","u":"https://instagram.com/mariam.sings"}]',
   null),
  (3, '00000000-0000-4000-8000-000000000b03', 'Luka', 22, 'Saburtalo', 41.727, 44.751,
   '{alt-rock,grunge,post-punk}', '{Nirvana,"The Strokes","Arctic Monkeys"}', '{gigging,recording}', 'weekly',
   'I write riffs and lyrics in Georgian and English. I need people to make them loud.',
   'Most evenings.', true, false, false, true,
   '[{"i":"guitar","s":"pro"},{"i":"bass","s":"advanced"},{"i":"vocals","s":"intermediate"}]',
   '[{"k":"soundcloud","u":"https://soundcloud.com/luka-riffs"},{"k":"tiktok","u":"https://tiktok.com/@luka.riffs"}]',
   '{"vocals":1,"keys":1}'),
  (4, '00000000-0000-4000-8000-000000000b04', 'Tamar', 30, 'Vake', 41.709, 44.760,
   '{jazz,synth-pop,classical}', '{"Herbie Hancock","Tigran Hamasyan",Kraftwerk}', '{recording,fun}', 'monthly',
   'Classically trained, recovering. I want to play over a drum machine and record an EP.',
   'Weekends.', true, true, false, true,
   '[{"i":"keys","s":"pro"},{"i":"vocals","s":"intermediate"}]',
   '[{"k":"bandcamp","u":"https://tamarkeys.bandcamp.com"}]',
   null),
  (5, '00000000-0000-4000-8000-000000000b05', 'Giorgi', 26, 'Didube', 41.739, 44.778,
   '{post-punk,punk,hardcore}', '{"Joy Division",Fugazi,"Bad Brains"}', '{gigging}', 'several_a_week',
   'Bass player who locks in with the drummer. Short songs, loud amps.',
   'Any evening.', true, true, false, false,
   '[{"i":"bass","s":"intermediate"},{"i":"guitar","s":"beginner"}]',
   '[{"k":"instagram","u":"https://instagram.com/giorgi.bass"}]',
   null),
  (6, '00000000-0000-4000-8000-000000000b06', 'Ana', 25, 'Mtatsminda', 41.694, 44.789,
   '{indie-folk,georgian-folk,classical}', '{"Andrew Bird",Bjork,"Nino Katamadze"}', '{fun,recording}', 'weekly',
   'Violinist who loves harmonies and old Georgian songs played new ways.',
   'Weekends and Tuesday evenings.', true, false, false, false,
   '[{"i":"violin","s":"pro"},{"i":"vocals","s":"beginner"}]',
   '[{"k":"youtube","u":"https://youtube.com/@ana-violin"}]',
   null),
  (7, '00000000-0000-4000-8000-000000000b07', 'Dato', 29, 'Nadzaladevi', 41.748, 44.793,
   '{jazz,funk,soul}', '{"Kamasi Washington","Maceo Parker"}', '{gigging,paid,fun}', 'weekly',
   'Sax player, happy to teach and to jam. I run a Sunday session for young players.',
   'Sundays, and evenings by arrangement.', true, true, true, false,
   '[{"i":"saxophone","s":"advanced"},{"i":"flute","s":"intermediate"}]',
   '[{"k":"youtube","u":"https://youtube.com/@dato-sax"},{"k":"other","u":"https://datosax.ge"}]',
   '{"drums":1,"bass":1}'),
  (8, '00000000-0000-4000-8000-000000000b08', 'Salome', 23, 'Avlabari', 41.692, 44.812,
   '{city-pop,disco,pop}', '{"Mariya Takeuchi",Chic,"Dua Lipa"}', '{gigging,fun}', 'weekly',
   'I want our first gig to be on a rooftop in June. Vocals and a bit of guitar.',
   'Weeknights.', false, false, false, false,
   '[{"i":"vocals","s":"advanced"},{"i":"guitar","s":"beginner"}]',
   '[{"k":"tiktok","u":"https://tiktok.com/@salome.sings"}]',
   null),
  (9, '00000000-0000-4000-8000-000000000b09', 'Levan', 31, 'Vake', 41.710, 44.755,
   '{electronic,techno,house}', '{Burial,"Four Tet","Bonobo"}', '{recording,paid}', 'occasionally',
   'Producer with a home studio. Looking for singers and players to record with.',
   'Flexible, mostly afternoons.', true, true, false, true,
   '[{"i":"production","s":"pro"},{"i":"dj","s":"advanced"},{"i":"keys","s":"intermediate"}]',
   '[{"k":"soundcloud","u":"https://soundcloud.com/levan-prod"},{"k":"spotify","u":"https://open.spotify.com/artist/levan-prod"}]',
   '{"vocals":2}'),
  (10, '00000000-0000-4000-8000-000000000b10', 'Nino', 28, 'Vera', 41.703, 44.783,
   '{classical,soundtrack,ambient}', '{"Max Richter","Hildur Gudnadottir"}', '{recording,paid}', 'monthly',
   'Cellist for film-score style projects and chamber pop.',
   'Weekday afternoons.', true, false, false, false,
   '[{"i":"cello","s":"advanced"}]',
   '[{"k":"instagram","u":"https://instagram.com/nino.cello"}]',
   null),
  (11, '00000000-0000-4000-8000-000000000b11', 'Saba', 17, 'Vake', 41.711, 44.762,
   '{rock,alt-rock,indie}', '{"Arctic Monkeys","The Black Keys"}', '{fun,gigging}', 'weekly',
   'Guitarist, 17. Looking for people my age to start a school band.',
   'After school and weekends.', true, false, false, false,
   '[{"i":"guitar","s":"intermediate"}]',
   '[{"k":"youtube","u":"https://youtube.com/@saba-guitar"}]',
   '{"drums":1,"bass":1,"vocals":1}'),
  (12, '00000000-0000-4000-8000-000000000b12', 'Elene', 16, 'Saburtalo', 41.725, 44.749,
   '{pop,rock,funk}', '{Paramore,"Red Hot Chili Peppers"}', '{fun}', 'weekly',
   'Drummer, 16, three years of lessons. Want to play real songs with a band.',
   'Weekends.', false, false, false, false,
   '[{"i":"drums","s":"beginner"},{"i":"percussion","s":"beginner"}]',
   '[]',
   null);

-- Auth users (no password; the token columns must be '' or sign-in fails).
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        confirmation_token, recovery_token, email_change, email_change_token_new,
                        email_change_token_current, phone_change, phone_change_token,
                        reauthentication_token, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
       lower(name) || '@test.octava.invalid', '', now(), '', '', '', '', '', '', '', '',
       '{"provider":"email","providers":["email"]}', '{}', now(), now()
from tw_people
on conflict (id) do nothing;

insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select id::text, id, jsonb_build_object('sub', id::text, 'email', lower(name) || '@test.octava.invalid'),
       'email', now(), now(), now()
from tw_people
on conflict do nothing;

-- Birth dates: the age today, give or take a few months.
insert into public.profile_private (id, birth_date)
select id, (current_date - make_interval(years => age, months => (n * 37) % 11))::date from tw_people
on conflict (id) do nothing;

insert into public.profiles (id, display_name, area, lat, lng, genres, influences, goals,
  rehearsal_frequency, looking_for, availability_note, has_own_gear, has_car,
  has_rehearsal_space, has_home_studio)
select id, name, area, lat, lng, genres, influences, goals, freq, looking_for, availability,
       own_gear, car, space, studio
from tw_people
on conflict (id) do nothing;

insert into public.profile_instruments (profile_id, instrument_id, skill, is_primary)
select p.id, i.value ->> 'i', (i.value ->> 's')::public.skill_level, i.ordinality = 1
from tw_people p, jsonb_array_elements(p.instruments) with ordinality i
on conflict do nothing;

insert into public.profile_links (profile_id, kind, url)
select p.id, (l.value ->> 'k')::public.link_kind, l.value ->> 'u'
from tw_people p, jsonb_array_elements(p.links) l;

insert into public.band_roles (profile_id, instrument_id, slots, sort_order)
select p.id, r.key, r.value::int, row_number() over (partition by p.id order by r.key)
from tw_people p, jsonb_each_text(p.needs) r
where p.needs is not null
on conflict do nothing;

-- ------------------------------------------------------ matches and chats

create temporary table tw_matches (a int, b int, lines text[]) on commit drop;
insert into tw_matches values
  (1, 3, '{"Your riff on SoundCloud is great","Thanks! Want to jam Thursday?","Yes, at the Vera room"}'),
  (1, 5, '{"Need a bassist for post-punk stuff?","Always"}'),
  (3, 5, '{}'),
  (6, 10, '{"Strings duo?","Only if we play Suliko"}'),
  (4, 2, '{"Love your voice","Love your Rhodes sound"}'),
  (6, 2, '{}'),
  (6, 4, '{}'),
  (10, 4, '{}'),
  (7, 8, '{"Rooftop gig in June, I''m in","Bring the sax"}'),
  (11, 12, '{"School band?","Yes! I have a kit at home"}'),
  (9, 1, '{"Drums for a track I''m producing?"}'),
  (9, 2, '{}');

-- Mutual Jams behind each match, so they're out of each other's feed.
insert into public.swipes (swiper_id, target_id, decision)
select x.id, y.id, 'jam'::public.swipe_decision from tw_matches m
join tw_people x on x.n = m.a join tw_people y on y.n = m.b
union all
select y.id, x.id, 'jam'::public.swipe_decision from tw_matches m
join tw_people x on x.n = m.a join tw_people y on y.n = m.b
on conflict do nothing;

insert into public.matches (user_a, user_b, created_by)
select least(x.id, y.id), greatest(x.id, y.id), y.id from tw_matches m
join tw_people x on x.n = m.a join tw_people y on y.n = m.b
on conflict do nothing;

-- Messages alternate between the two, a few minutes apart.
insert into public.messages (match_id, sender_id, body, created_at)
select mt.id, case when l.ordinality % 2 = 1 then x.id else y.id end, l.value,
       now() - interval '2 days' + l.ordinality * interval '7 minutes'
from tw_matches m
join tw_people x on x.n = m.a join tw_people y on y.n = m.b
join public.matches mt on mt.user_a = least(x.id, y.id) and mt.user_b = greatest(x.id, y.id),
     unnest(m.lines) with ordinality l (value, ordinality);

-- Some test musicians already like every real adult profile.
insert into public.swipes (swiper_id, target_id, decision)
select t.id, p.id, 'jam'::public.swipe_decision
from tw_people t, public.profiles p join auth.users u on u.id = p.id
where t.n in (2, 3, 4, 7, 9)
  and u.email not like '%@test.octava.invalid'
  and private.age_of(p.id) >= 18
on conflict do nothing;

-- ------------------------------------------------------------------ bands

insert into public.bands (id, name, created_by, description, genres, open_roles, is_public) values
  ('00000000-0000-4000-8000-000000000c01', 'Rustaveli Riot', '00000000-0000-4000-8000-000000000b01',
   'Loud, fast post-punk from Tbilisi. We rehearse twice a week in Vera and play wherever there''s a plug.',
   '{post-punk,punk,math-rock}', '{vocals,keys}', true),
  ('00000000-0000-4000-8000-000000000c02', 'Mtatsminda Strings', '00000000-0000-4000-8000-000000000b06',
   'Chamber pop with violin, cello and keys: old Georgian songs arranged new, and our own.',
   '{indie-folk,georgian-folk,classical}', '{guitar}', false),
  ('00000000-0000-4000-8000-000000000c03', 'Sunday Session Crew', '00000000-0000-4000-8000-000000000b07',
   'Dato''s Sunday jam for young players and the adults who show them the ropes. Funk, rock, anything with a groove.',
   '{funk,rock,soul}', '{bass,keys}', false)
on conflict (id) do nothing;

insert into public.band_members (band_id, profile_id, instrument_id, joined_at)
select b.band::uuid, p.id, (select pi.instrument_id from public.profile_instruments pi
                           where pi.profile_id = p.id and pi.is_primary), now() - b.days * interval '1 day'
from (values
  ('00000000-0000-4000-8000-000000000c01', 1, 30), ('00000000-0000-4000-8000-000000000c01', 3, 28),
  ('00000000-0000-4000-8000-000000000c01', 5, 20),
  ('00000000-0000-4000-8000-000000000c02', 6, 40), ('00000000-0000-4000-8000-000000000c02', 10, 38),
  ('00000000-0000-4000-8000-000000000c02', 4, 30), ('00000000-0000-4000-8000-000000000c02', 2, 12),
  -- Adults first: a teen joins a band with adults only once it has 2+.
  ('00000000-0000-4000-8000-000000000c03', 7, 25), ('00000000-0000-4000-8000-000000000c03', 8, 24),
  ('00000000-0000-4000-8000-000000000c03', 11, 15), ('00000000-0000-4000-8000-000000000c03', 12, 10)
) b (band, n, days)
join tw_people p on p.n = b.n
on conflict do nothing;

-- Rustaveli Riot: Nika proposed Levan (they matched; Nika's yes counts),
-- and Salome asked to join from the feed.
insert into public.band_proposals (id, band_id, candidate_id, proposed_by, status, requested) values
  ('00000000-0000-4000-8000-000000000d01', '00000000-0000-4000-8000-000000000c01',
   '00000000-0000-4000-8000-000000000b09', '00000000-0000-4000-8000-000000000b01', 'voting', false),
  ('00000000-0000-4000-8000-000000000d02', '00000000-0000-4000-8000-000000000c01',
   '00000000-0000-4000-8000-000000000b08', null, 'voting', true)
on conflict (id) do nothing;
insert into public.band_votes (proposal_id, voter_id, approve) values
  ('00000000-0000-4000-8000-000000000d01', '00000000-0000-4000-8000-000000000b01', true),
  ('00000000-0000-4000-8000-000000000d02', '00000000-0000-4000-8000-000000000b03', true)
on conflict do nothing;

-- Band chats.
insert into public.band_messages (band_id, sender_id, body, created_at)
select b.band::uuid, p.id, b.body, now() - interval '1 day' + b.k * interval '9 minutes'
from (values
  ('00000000-0000-4000-8000-000000000c01', 1, 1, 'Room is booked for Thursday 19:00'),
  ('00000000-0000-4000-8000-000000000c01', 3, 2, 'I''ll bring the new riff for Static Hearts'),
  ('00000000-0000-4000-8000-000000000c01', 5, 3, 'Can we run the Fabrika set twice?'),
  ('00000000-0000-4000-8000-000000000c01', 1, 4, 'Yes. And let''s vote on Levan and Salome'),
  ('00000000-0000-4000-8000-000000000c02', 6, 1, 'New arrangement of Suliko is in the songs'),
  ('00000000-0000-4000-8000-000000000c02', 10, 2, 'Beautiful. The cello line in bar 12 is lovely'),
  ('00000000-0000-4000-8000-000000000c02', 2, 3, 'I can sing the second verse in Georgian'),
  ('00000000-0000-4000-8000-000000000c03', 7, 1, 'Sunday at 12, same place. Bring water'),
  ('00000000-0000-4000-8000-000000000c03', 11, 2, 'Can we try First Gig Song?'),
  ('00000000-0000-4000-8000-000000000c03', 12, 3, 'I practised the fill all week!'),
  ('00000000-0000-4000-8000-000000000c03', 8, 4, 'Great, I''ll learn the lyrics')
) b (band, n, k, body)
join tw_people p on p.n = b.n;

insert into public.band_reads (band_id, user_id, last_read_at)
select m.band_id, m.profile_id, now() - interval '20 hours'
from public.band_members m
where m.band_id in ('00000000-0000-4000-8000-000000000c01', '00000000-0000-4000-8000-000000000c02',
                    '00000000-0000-4000-8000-000000000c03')
on conflict do nothing;

-- ------------------------------------------------------------------ songs

insert into public.songs (band_id, title, song_key, tempo, notes, status, links, created_by)
select b.band::uuid, b.title, b.k, b.t, b.notes, b.status::public.song_status, b.links,
       (select m.profile_id from public.band_members m where m.band_id = b.band::uuid order by m.joined_at limit 1)
from (values
  ('00000000-0000-4000-8000-000000000c01', 'Concrete Summer', 'E minor', 142, 'Intro x2, verse, chorus, verse, double chorus. Nika counts in.', 'ready', '{https://youtube.com/watch?v=concrete-summer}'::text[]),
  ('00000000-0000-4000-8000-000000000c01', 'Rustaveli at 3am', 'A minor', 128, 'Slow build, everyone in at the second chorus.', 'ready', '{}'::text[]),
  ('00000000-0000-4000-8000-000000000c01', 'Static Hearts', 'D', 150, '7/8 in the bridge. Still working on the ending.', 'learning', '{https://www.songsterr.com/static-hearts}'::text[]),
  ('00000000-0000-4000-8000-000000000c01', 'Untitled jam #4', null, null, 'From the voice memo on Tuesday.', 'idea', '{}'::text[]),
  ('00000000-0000-4000-8000-000000000c02', 'Mtatsminda Lullaby', 'G major', 72, 'Violin melody, cello drone, keys come in at verse 2.', 'ready', '{}'::text[]),
  ('00000000-0000-4000-8000-000000000c02', 'Suliko (arrangement)', 'F minor', 60, 'Mariam sings verse 2 in Georgian.', 'ready', '{https://youtube.com/watch?v=suliko}'::text[]),
  ('00000000-0000-4000-8000-000000000c02', 'Autumn on Leselidze', 'C minor', 96, 'Needs a guitar part.', 'learning', '{}'::text[]),
  ('00000000-0000-4000-8000-000000000c03', 'First Gig Song', 'E', 120, 'Simple groove, everyone gets a solo.', 'learning', '{}'::text[]),
  ('00000000-0000-4000-8000-000000000c03', 'Sunday Funk', 'G', 104, 'Dato''s riff, Saba on rhythm.', 'ready', '{}'::text[]),
  ('00000000-0000-4000-8000-000000000c03', 'Rooftop', null, null, 'Salome''s idea for June.', 'idea', '{}'::text[])
) b (band, title, k, t, notes, status, links);

-- --------------------------------------------------------------- setlists

insert into public.setlists (id, band_id, name, created_by) values
  ('00000000-0000-4000-8000-000000000e01', '00000000-0000-4000-8000-000000000c01', 'Friday at Fabrika', '00000000-0000-4000-8000-000000000b01'),
  ('00000000-0000-4000-8000-000000000e02', '00000000-0000-4000-8000-000000000c02', 'Sunday matinee', '00000000-0000-4000-8000-000000000b06'),
  ('00000000-0000-4000-8000-000000000e03', '00000000-0000-4000-8000-000000000c03', 'School party', '00000000-0000-4000-8000-000000000b07')
on conflict (id) do nothing;

insert into public.setlist_songs (setlist_id, band_id, song_id, position)
select s.list::uuid, so.band_id, so.id, s.pos
from (values
  ('00000000-0000-4000-8000-000000000e01', 'Concrete Summer', 1),
  ('00000000-0000-4000-8000-000000000e01', 'Static Hearts', 2),
  ('00000000-0000-4000-8000-000000000e01', 'Rustaveli at 3am', 3),
  ('00000000-0000-4000-8000-000000000e02', 'Mtatsminda Lullaby', 1),
  ('00000000-0000-4000-8000-000000000e02', 'Suliko (arrangement)', 2),
  ('00000000-0000-4000-8000-000000000e03', 'Sunday Funk', 1),
  ('00000000-0000-4000-8000-000000000e03', 'First Gig Song', 2)
) s (list, title, pos)
join public.setlists sl on sl.id = s.list::uuid
join public.songs so on so.band_id = sl.band_id and so.title = s.title
on conflict do nothing;

-- ------------------------------------------------------------- rehearsals

-- Times are Tbilisi time; the first date is the next such weekday.
insert into public.rehearsals (band_id, starts_at, duration_minutes, place, notes, weekly, created_by, setlist_id)
select r.band::uuid,
       ((current_date + ((r.dow - extract(isodow from current_date)::int + 7) % 7 + 1)) + r.at)
         at time zone 'Asia/Tbilisi',
       r.minutes, r.place, r.notes, r.weekly, r.by::uuid, r.list::uuid
from (values
  ('00000000-0000-4000-8000-000000000c01', 4, time '19:00', 120, 'Vera rehearsal room, 2nd floor', 'Run the Fabrika set twice.', true, '00000000-0000-4000-8000-000000000b01', '00000000-0000-4000-8000-000000000e01'),
  ('00000000-0000-4000-8000-000000000c02', 6, time '15:00', 90, 'Tamar''s studio, Vake', 'Record a rough take of Suliko.', false, '00000000-0000-4000-8000-000000000b06', '00000000-0000-4000-8000-000000000e02'),
  ('00000000-0000-4000-8000-000000000c03', 7, time '12:00', 120, 'Nadzaladevi youth centre', 'Bring water. Parents welcome.', true, '00000000-0000-4000-8000-000000000b07', '00000000-0000-4000-8000-000000000e03')
) r (band, dow, at, minutes, place, notes, weekly, by, list);

-- Answers for each first date: most are going, one can't.
insert into public.rehearsal_answers (rehearsal_id, occurs_on, member_id, going)
select r.id, (r.starts_at at time zone 'Asia/Tbilisi')::date, m.profile_id,
       not (row_number() over (partition by r.id order by m.joined_at) = 3)
from public.rehearsals r
join public.band_members m on m.band_id = r.band_id
where r.band_id in ('00000000-0000-4000-8000-000000000c01', '00000000-0000-4000-8000-000000000c02',
                    '00000000-0000-4000-8000-000000000c03')
on conflict do nothing;

select (select count(*) from public.profiles p join tw_people t on t.id = p.id) as people,
       (select count(*) from public.bands where id::text like '00000000-0000-4000-8000-000000000c0%') as bands;

commit;
