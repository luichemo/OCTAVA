-- Checks the moderation rules (migration 20261019075400_moderation) by acting
-- as fake users. Like rules_check.sql it always ends with an exception, so
-- all test data is rolled back. Read the exception message for PASS/FAIL.

do $$
declare
  m uuid := gen_random_uuid(); x uuid := gen_random_uuid(); y uuid := gen_random_uuid(); z uuid := gen_random_uuid(); bad uuid := gen_random_uuid(); v uuid := gen_random_uuid();
  rep uuid; r text[] := '{}'; n int; ok boolean; st text;
begin
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, created_at, updated_at)
  select '00000000-0000-0000-0000-000000000000', u, 'authenticated', 'authenticated', u::text || '@test.octava.invalid', '', now(), now()
  from unnest(array[m, x, y, z, bad, v]) u;
  insert into public.profile_private (id, birth_date) select u, '1990-01-01' from unnest(array[m, x, y, z, bad, v]) u;
  insert into public.profiles (id, display_name) select u, 'P' || left(u::text, 4) from unnest(array[m, x, y, z, bad, v]) u;
  insert into public.audio_clips (profile_id, storage_path, title, duration_seconds) values (bad, bad || '/x.wav', 'b', 5);
  insert into public.moderators (profile_id) values (m);

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', v, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_deck(null, null, null, null, null, null, 50) d where d.id = bad;
  r := r || case when n = 1 then 'PASS visible before reports' else 'FAIL not visible before' end;

  perform set_config('request.jwt.claims', json_build_object('sub', x, 'role', 'authenticated')::text, true);
  insert into public.reports (reporter_id, reported_id, reason) values (x, bad, 'harassment');
  begin
    insert into public.reports (reporter_id, reported_id, reason, status) values (x, bad, 'spam', 'dismissed');
  exception when others then null; end;
  perform set_config('request.jwt.claims', json_build_object('sub', y, 'role', 'authenticated')::text, true);
  insert into public.reports (reporter_id, reported_id, reason) values (y, bad, 'harassment');

  perform set_config('request.jwt.claims', json_build_object('sub', v, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_deck(null, null, null, null, null, null, 50) d where d.id = bad;
  r := r || case when n = 1 then 'PASS still visible with 2 reporters' else 'FAIL hidden too early' end;

  perform set_config('request.jwt.claims', json_build_object('sub', z, 'role', 'authenticated')::text, true);
  insert into public.reports (reporter_id, reported_id, reason) values (z, bad, 'fake_profile');
  perform set_config('request.jwt.claims', json_build_object('sub', v, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_deck(null, null, null, null, null, null, 50) d where d.id = bad;
  r := r || case when n = 0 then 'PASS hidden after 3 different reporters' else 'FAIL still visible after 3' end;

  begin
    perform * from public.mod_reports();
    r := r || 'FAIL non-moderator saw reports'::text;
  exception when insufficient_privilege then r := r || 'PASS non-moderators can''t see reports'::text; end;
  begin
    perform public.mod_resolve_report(gen_random_uuid(), 'dismiss');
    r := r || 'FAIL non-moderator resolved'::text;
  exception when insufficient_privilege then r := r || 'PASS non-moderators can''t resolve'::text; end;

  perform set_config('role', 'postgres', true);
  select string_agg(distinct status::text, ',') into st from public.reports where reported_id = bad;
  r := r || case when st = 'open' then 'PASS reporters can''t pre-resolve' else 'FAIL statuses: ' || st end;
  perform set_config('role', 'authenticated', true);

  perform set_config('request.jwt.claims', json_build_object('sub', m, 'role', 'authenticated')::text, true);
  select count(*) into n from public.mod_reports() mr where mr.reported_id = bad;
  r := r || case when n >= 3 then 'PASS moderator sees the open reports (' || n || ')' else 'FAIL moderator sees ' || n end;

  select mr.id into rep from public.mod_reports() mr where mr.reported_id = bad and mr.reason = 'fake_profile';
  perform public.mod_resolve_report(rep, 'dismiss', 'not fake');
  perform set_config('request.jwt.claims', json_build_object('sub', v, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_deck(null, null, null, null, null, null, 50) d where d.id = bad;
  r := r || case when n = 1 then 'PASS dismissing brings them back' else 'FAIL still hidden after dismiss' end;

  perform set_config('request.jwt.claims', json_build_object('sub', m, 'role', 'authenticated')::text, true);
  select mr.id into rep from public.mod_reports() mr where mr.reported_id = bad limit 1;
  perform public.mod_resolve_report(rep, 'suspend', 'harassment confirmed');
  select count(*) into n from public.mod_reports() mr where mr.reported_id = bad;
  r := r || case when n = 0 then 'PASS suspending closes their reports' else 'FAIL reports left open' end;
  perform set_config('request.jwt.claims', json_build_object('sub', v, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_deck(null, null, null, null, null, null, 50) d where d.id = bad;
  r := r || case when n = 0 then 'PASS suspended are hidden' else 'FAIL suspended visible' end;
  perform set_config('role', 'postgres', true);
  select banned_until > now() into ok from auth.users where id = bad;
  r := r || case when ok then 'PASS login banned' else 'FAIL not banned' end;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', m, 'role', 'authenticated')::text, true);
  perform public.mod_unsuspend(bad);
  perform set_config('role', 'postgres', true);
  select banned_until is null and (select suspended_at is null from public.profiles where id = bad) into ok from auth.users where id = bad;
  r := r || case when ok then 'PASS unsuspend lifts it' else 'FAIL still suspended' end;

  raise exception E'MODERATION CHECK (rolled back)\n%', array_to_string(r, E'\n');
end $$;
