-- Checks the setlist rules (migration 20261016103349_setlists) by acting as
-- fake users. Like rules_check.sql it always ends with an exception, so all
-- test data is rolled back. Read the exception message for PASS/FAIL.

do $$
declare
  a uuid := gen_random_uuid(); b uuid := gen_random_uuid(); x uuid := gen_random_uuid();
  band uuid; other uuid; s1 uuid; s2 uuid; s3 uuid; so uuid; sl uuid; slo uuid; reh uuid;
  r text[] := '{}'; n int; ok boolean;
begin
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, created_at, updated_at)
  select '00000000-0000-0000-0000-000000000000', u, 'authenticated', 'authenticated',
         u::text || '@test.octava.invalid', '', now(), now() from unnest(array[a, b, x]) u;
  insert into public.profile_private (id, birth_date) values (a, '1995-05-01'), (b, '1996-05-01'), (x, '1990-01-01');
  insert into public.profiles (id, display_name) values (a, 'A'), (b, 'B'), (x, 'X');

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  band := public.create_band('Setlist band');
  perform set_config('request.jwt.claims', json_build_object('sub', x, 'role', 'authenticated')::text, true);
  other := public.create_band('Other band');
  insert into public.songs (band_id, title, created_by) values (other, 'Other song', x) returning id into so;
  insert into public.setlists (band_id, name, created_by) values (other, 'Other set', x) returning id into slo;

  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  insert into public.songs (band_id, title, created_by) values (band, 'One', a) returning id into s1;
  insert into public.songs (band_id, title, created_by) values (band, 'Two', a) returning id into s2;
  insert into public.songs (band_id, title, created_by) values (band, 'Three', a) returning id into s3;
  insert into public.setlists (band_id, name, created_by) values (band, 'Friday gig', a) returning id into sl;

  perform public.set_setlist_songs(sl, array[s3, s1, s3, s2]);
  select array_agg(song_id order by position) = array[s3, s1, s2] into ok from public.setlist_songs where setlist_id = sl;
  r := r || case when ok then 'PASS songs keep their order, repeats dropped' else 'FAIL order' end;

  begin
    perform public.set_setlist_songs(sl, array[s1, so]);
    r := r || 'FAIL another band''s song accepted'::text;
  exception when others then r := r || 'PASS only the band''s own songs'::text; end;

  begin
    insert into public.setlist_songs (setlist_id, band_id, song_id, position) values (sl, band, s1, 9);
    r := r || 'FAIL direct write to setlist_songs'::text;
  exception when others then r := r || 'PASS setlist_songs only through the function'::text; end;

  begin
    perform public.set_setlist_songs(slo, array[]::uuid[]);
    r := r || 'FAIL edited another band''s setlist'::text;
  exception when others then r := r || 'PASS can''t edit another band''s setlist'::text; end;

  select count(*) into n from public.setlists where id = slo;
  r := r || case when n = 0 then 'PASS other bands'' setlists are hidden' else 'FAIL setlist visible' end;

  insert into public.rehearsals (band_id, starts_at, created_by, setlist_id) values (band, now() + interval '1 day', a, sl) returning id into reh;
  r := r || 'PASS a rehearsal links its band''s setlist'::text;
  begin
    update public.rehearsals set setlist_id = slo where id = reh;
    r := r || 'FAIL linked another band''s setlist'::text;
  exception when others then r := r || 'PASS can''t link another band''s setlist'::text; end;

  delete from public.songs where id = s1;
  select count(*) into n from public.setlist_songs where setlist_id = sl;
  r := r || case when n = 2 then 'PASS deleting a song takes it out of setlists' else 'FAIL song delete' end;

  delete from public.setlists where id = sl;
  select setlist_id is null into ok from public.rehearsals where id = reh;
  r := r || case when ok then 'PASS deleting a setlist unlinks rehearsals' else 'FAIL unlink' end;

  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  select count(*) into n from public.songs where band_id = band;
  r := r || case when n = 0 then 'PASS outsiders see nothing' else 'FAIL outsider' end;

  raise exception E'SETLISTS CHECK (rolled back)\n%', array_to_string(r, E'\n');
end $$;
