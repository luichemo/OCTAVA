-- Checks the database rules by acting as fake users. Everything runs in one
-- block that always ends with an exception, so all test data is rolled back.
-- Read the exception message for the PASS/FAIL list.
-- Run in the Supabase SQL editor (or via the MCP execute_sql tool).
-- Deck checks only count the fake users (B, C, ...), so real or test-musician
-- profiles already in the database don't change the results.

do $$
declare
  a uuid := gen_random_uuid();   -- adult, Tbilisi, no clip
  b uuid := gen_random_uuid();   -- adult, Tbilisi ~3 km away, drums, has a clip
  c uuid := gen_random_uuid();   -- adult, Batumi ~270 km away, bass, has a clip
  t1 uuid := gen_random_uuid();  -- 17, Tbilisi, no clip
  t2 uuid := gen_random_uuid();  -- 16, Tbilisi, has a clip
  u15 uuid := gen_random_uuid(); -- 15, can't join
  r text[] := '{}';
  n int;
  m uuid;
  ok boolean;
begin
  -- ---------------------------------------------------------- setup (as admin)
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, created_at, updated_at)
  select '00000000-0000-0000-0000-000000000000', u, 'authenticated', 'authenticated',
         u::text || '@test.octava.invalid', '', now(), now()
  from unnest(array[a, b, c, t1, t2, u15]) u;

  insert into public.profile_private (id, birth_date) values
    (a, '1995-05-01'), (b, '1998-03-02'), (c, '1990-01-01'),
    (t1, (current_date - interval '17 years')::date),
    (t2, (current_date - interval '16 years 6 months')::date);

  insert into public.profiles (id, display_name, lat, lng, genres) values
    (a, 'A', 41.7151, 44.8271, '{rock}'),
    (b, 'B', 41.7200, 44.7900, '{Post-Punk}'),
    (c, 'C', 41.6500, 41.6400, '{jazz}'),
    (t1, 'T1', 41.716, 44.828, '{}'),
    (t2, 'T2', 41.717, 44.829, '{}');

  insert into public.profile_instruments (profile_id, instrument_id, skill, is_primary) values
    (b, 'drums', 'intermediate', true), (c, 'bass', 'pro', true);

  -- Decks only show people with a clip: B, C and T2 have one, A and T1 don't.
  insert into public.audio_clips (profile_id, storage_path, title, duration_seconds) values
    (b, b || '/x.wav', 'b', 5), (c, c || '/x.wav', 'c', 5), (t2, t2 || '/x.wav', 't2', 5);

  begin
    update public.profiles set genres = '{not-a-genre}' where id = a;
    r := r || 'FAIL unknown genre accepted'::text;
  exception when others then
    r := r || 'PASS only genres from the list are accepted'::text;
  end;

  select (lat = 41.72 and lng = 44.79) into ok from public.profiles where id = b;
  r := r || case when ok then 'PASS locations are rounded to 2 decimals' else 'FAIL location not rounded' end;
  select genres = '{post-punk}' into ok from public.profiles where id = b;
  r := r || case when ok then 'PASS genres are lower-cased' else 'FAIL genres not normalised' end;

  -- ---------------------------------------------------------- 15-year-old
  perform set_config('request.jwt.claims', json_build_object('sub', u15, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    insert into public.profile_private (id, birth_date) values (u15, (current_date - interval '15 years')::date);
    r := r || 'FAIL under-16 birth date accepted'::text;
  exception when others then
    r := r || ('PASS under-16 rejected: ' || sqlerrm);
  end;

  -- ---------------------------------------------------------- adult A
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);

  select count(*) into n from public.profile_private;
  r := r || case when n = 1 then 'PASS A sees only their own birth date' else 'FAIL A sees ' || n || ' birth dates' end;

  begin
    perform lat from public.profiles limit 1;
    r := r || 'FAIL A can read locations'::text;
  exception when insufficient_privilege then
    r := r || 'PASS locations are not readable'::text;
  end;

  select count(*) into n from public.profiles where id in (t1, t2);
  r := r || case when n = 0 then 'PASS A sees no teen profiles' else 'FAIL A sees teens' end;

  begin
    perform private.age_of(b);
    r := r || 'FAIL internal helper age_of is callable'::text;
  exception when insufficient_privilege then
    r := r || 'PASS internal helpers can''t be called directly'::text;
  end;

  select count(*) into n from public.get_deck(25) d where d.id in (b, c);
  r := r || case when n = 1 then 'PASS deck within 25 km has B, not far-away C' else 'FAIL deck(25 km) has ' || n end;

  select count(*) into n from public.get_deck(null) d where d.id in (b, c);
  r := r || case when n = 2 then 'PASS deck with no distance limit has B and C' else 'FAIL deck(any) has ' || n end;

  select count(*) into n from public.get_deck(null, array['drums']) d where d.id in (b, c);
  r := r || case when n = 1 then 'PASS drums filter finds only B' else 'FAIL drums filter found ' || n end;

  select count(*) into n from public.get_deck(null, array['bass'], 'advanced') d where d.id in (b, c);
  r := r || case when n = 1 then 'PASS skill filter (bass, advanced+) finds C' else 'FAIL skill filter found ' || n end;

  select count(*) into n from public.get_deck(null, null, null, array['POST-PUNK']) d where d.id in (b, c);
  r := r || case when n = 1 then 'PASS genre filter ignores case' else 'FAIL genre filter found ' || n end;

  select distance_km into n from public.get_deck(25) d where d.id = b;
  r := r || case when n = 3 then 'PASS distance shown as whole km (3)' else 'FAIL distance is ' || coalesce(n::text, 'null') end;

  -- A's band needs a bassist: far-away bassist C now comes before nearby drummer B.
  insert into public.band_roles (profile_id, instrument_id, slots) values (a, 'bass', 1);
  select d.id into m from public.get_deck(null) with ordinality d
  where d.id in (b, c) order by d.ordinality limit 1;
  r := r || case when m = c then 'PASS open band roles come first in the deck' else 'FAIL deck order ignores band roles' end;
  m := null;
  begin
    insert into public.band_roles (profile_id, instrument_id, slots) values (a, 'drums', 4), (a, 'keys', 4);
    r := r || 'FAIL more than 8 band slots accepted'::text;
  exception when others then
    r := r || 'PASS a lineup has at most 8 slots'::text;
  end;
  begin
    insert into public.band_roles (profile_id, instrument_id, slots) values (b, 'bass', 1);
    r := r || 'FAIL A could set B''s band roles'::text;
  exception when others then
    r := r || 'PASS band roles can only be set for yourself'::text;
  end;

  begin
    perform public.record_swipe(t1, 'jam');
    r := r || 'FAIL adult could swipe on a teen'::text;
  exception when others then
    r := r || 'PASS adult can''t swipe on a teen'::text;
  end;

  begin
    insert into public.swipes (swiper_id, target_id, decision) values (a, b, 'jam');
    r := r || 'FAIL swipes writable directly'::text;
  exception when insufficient_privilege then
    r := r || 'PASS swipes only go through record_swipe'::text;
  end;

  m := public.record_swipe(b, 'jam');
  r := r || case when m is null then 'PASS one-sided Jam is not a match' else 'FAIL one-sided Jam matched' end;

  select count(*) into n from public.get_deck(null) d where d.id = b;
  r := r || case when n = 0 then 'PASS swiped people leave the deck' else 'FAIL B still in deck' end;

  -- ---------------------------------------------------------- adult B
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  m := public.record_swipe(a, 'jam');
  r := r || case when m is not null then 'PASS mutual Jam creates a match' else 'FAIL mutual Jam did not match' end;

  select count(*) into n from public.band_roles where profile_id = a;
  r := r || case when n = 0 then 'PASS B can''t see A''s band roles' else 'FAIL B sees A''s band roles' end;

  select count(*) into n from public.swipes;
  r := r || case when n = 1 then 'PASS B sees only their own swipes' else 'FAIL B sees ' || n || ' swipes' end;

  insert into public.messages (match_id, body) values (m, 'Hi A, want to jam?');
  r := r || 'PASS B can message A in their match'::text;

  -- ---------------------------------------------------------- adult C
  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_deck(null) d where d.id = a;
  r := r || case when n = 0 then 'PASS people without a clip are not in decks' else 'FAIL clip-less A is in C''s deck' end;
  select count(*) into n from public.get_deck(null) d where d.id = b;
  r := r || case when n = 1 then 'PASS people with a clip are in decks' else 'FAIL B missing from C''s deck' end;
  select count(*) into n from public.messages where match_id = m;
  r := r || case when n = 0 then 'PASS C can''t read A and B''s messages' else 'FAIL C reads ' || n || ' messages' end;
  select count(*) into n from public.matches where id = m;
  r := r || case when n = 0 then 'PASS C can''t see A and B''s match' else 'FAIL C sees their match' end;
  begin
    insert into public.messages (match_id, body) values (m, 'sneaky');
    r := r || 'FAIL C could post in someone else''s match'::text;
  exception when others then
    r := r || 'PASS C can''t post in someone else''s match'::text;
  end;

  -- ---------------------------------------------------------- A blocks B
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  select count(*) into n from public.messages where match_id = m;
  r := r || case when n = 1 then 'PASS A reads B''s message' else 'FAIL A reads ' || n || ' messages' end;

  insert into public.blocks (blocked_id) values (b);
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  begin
    insert into public.messages (match_id, body) values (m, 'still there?');
    r := r || 'FAIL blocked person can still message'::text;
  exception when others then
    r := r || 'PASS blocked person can''t message'::text;
  end;

  -- ---------------------------------------------------------- reports
  insert into public.reports (reported_id, reason, details) values (a, 'spam', 'test');
  begin
    perform 1 from public.reports;
    r := r || 'FAIL reports are readable'::text;
  exception when insufficient_privilege then
    r := r || 'PASS reports can be filed but not read'::text;
  end;

  -- ---------------------------------------------------------- teens
  perform set_config('request.jwt.claims', json_build_object('sub', t1, 'role', 'authenticated')::text, true);
  select count(*) into n from public.profiles where id in (a, b, c);
  r := r || case when n = 0 then 'PASS teen sees no adult profiles' else 'FAIL teen sees ' || n || ' adults' end;
  select count(*) into n from public.get_deck(null) d where d.id = t2;
  r := r || case when n = 1 then 'PASS teen''s deck has the other teen (who has a clip)' else 'FAIL teen deck missing T2' end;

  -- ---------------------------------------------------------- location setter
  perform public.set_my_location(41.71234, 44.83456);
  perform set_config('role', 'postgres', true);
  select (lat = 41.71 and lng = 44.83) into ok from public.profiles where id = t1;
  r := r || case when ok then 'PASS set_my_location rounds to ~1 km' else 'FAIL set_my_location not rounded' end;

  raise exception E'RULES CHECK (rolled back)\n%', array_to_string(r, E'\n');
end;
$$;
