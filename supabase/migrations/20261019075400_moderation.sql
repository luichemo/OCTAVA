-- Handling reports (owner, 2026-10-19).
--  * Moderators (the owner's accounts) review reports in the app: a list of
--    open reports and Dismiss / Remove message / Suspend account.
--  * Someone reported by 3 different people, or suspended, is hidden from
--    the feed until reviewed (chats and bands stay).
--  * Each new report sends a Telegram message, when the Vault secrets
--    `telegram_bot_token` and `telegram_chat_id` exist (Dashboard → Project
--    Settings → Vault). Without them nothing is sent; reports still save.

create extension if not exists pg_net with schema extensions;

-- ------------------------------------------------------------- moderators

create table public.moderators (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  added_at timestamptz not null default now()
);
alter table public.moderators enable row level security;
-- You can only see whether you yourself are one (the app shows the screen).
create policy "See whether you're a moderator" on public.moderators
  for select to authenticated using (profile_id = (select auth.uid()));
revoke all on public.moderators from anon, authenticated;
grant select on public.moderators to authenticated;

create function private.is_moderator(person uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.moderators m where m.profile_id = person);
$$;

-- ---------------------------------------------------------------- reports

create type public.report_status as enum ('open', 'dismissed', 'actioned');
alter table public.reports
  add column status public.report_status not null default 'open',
  add column resolved_by uuid references public.profiles (id) on delete set null,
  add column resolved_at timestamptz,
  add column resolution_note text check (char_length(resolution_note) <= 500);
create index reports_open_idx on public.reports (reported_id) where status = 'open';
create index reports_resolved_by_idx on public.reports (resolved_by);

-- A reporter can't file a report that's already resolved.
create function private.reports_before_insert() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.status := 'open';
  new.resolved_by := null;
  new.resolved_at := null;
  new.resolution_note := null;
  return new;
end;
$$;
create trigger reports_before_insert before insert on public.reports
  for each row execute function private.reports_before_insert();

-- Suspended by a moderator (clients can't read or write it: no column grant).
alter table public.profiles add column suspended_at timestamptz;

-- Hidden from the feed: suspended, or reported by 3+ different people with
-- the reports still open.
create function private.under_review(person uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p where p.id = person and p.suspended_at is not null)
      or (select count(distinct r.reporter_id) from public.reports r
          where r.reported_id = person and r.status = 'open') >= 3;
$$;

-- ------------------------------------------------- moderator functions

-- Open reports, newest first, with names and how many open reports the
-- reported person has.
create function public.mod_reports()
returns table (
  id uuid, created_at timestamptz, reason text, details text,
  reported_text text, band_message_id uuid, message_still_there boolean,
  reporter_id uuid, reporter_name text,
  reported_id uuid, reported_name text, reported_suspended boolean,
  open_against int
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.is_moderator(auth.uid()) then
    raise exception 'Only moderators can see reports' using errcode = 'insufficient_privilege';
  end if;
  return query
  select r.id, r.created_at, r.reason::text, r.details, r.reported_text, r.band_message_id,
         r.band_message_id is not null
           and exists (select 1 from public.band_messages m where m.id = r.band_message_id),
         r.reporter_id, rp.display_name,
         r.reported_id, dp.display_name, dp.suspended_at is not null,
         (select count(*)::int from public.reports o
          where o.reported_id = r.reported_id and o.status = 'open')
  from public.reports r
  left join public.profiles rp on rp.id = r.reporter_id
  left join public.profiles dp on dp.id = r.reported_id
  where r.status = 'open'
  order by r.created_at desc;
end;
$$;

-- Resolves a report: 'dismiss', 'remove_message' (deletes the reported band
-- message) or 'suspend' (hides them, bans the login, ends their sessions,
-- and closes all their open reports).
create function public.mod_resolve_report(report uuid, action text, note text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare
  r public.reports;
begin
  if not private.is_moderator(auth.uid()) then
    raise exception 'Only moderators can resolve reports' using errcode = 'insufficient_privilege';
  end if;
  select * into r from public.reports where id = report;
  if r.id is null then
    raise exception 'No such report' using errcode = 'P0001';
  end if;
  if action = 'dismiss' then
    update public.reports set status = 'dismissed', resolved_by = auth.uid(),
      resolved_at = now(), resolution_note = note where id = report;
  elsif action = 'remove_message' then
    if r.band_message_id is not null then
      delete from public.band_messages where id = r.band_message_id;
    end if;
    update public.reports set status = 'actioned', resolved_by = auth.uid(),
      resolved_at = now(), resolution_note = note where id = report;
  elsif action = 'suspend' then
    if private.is_moderator(r.reported_id) then
      raise exception 'Moderators can''t be suspended here' using errcode = 'P0001';
    end if;
    update public.profiles set suspended_at = now() where id = r.reported_id;
    update auth.users set banned_until = now() + interval '100 years' where id = r.reported_id;
    delete from auth.sessions where user_id = r.reported_id;
    update public.reports set status = 'actioned', resolved_by = auth.uid(),
      resolved_at = now(), resolution_note = coalesce(note, resolution_note)
      where reported_id = r.reported_id and status = 'open';
  else
    raise exception 'Unknown action' using errcode = 'P0001';
  end if;
end;
$$;

-- Lifts a suspension.
create function public.mod_unsuspend(person uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_moderator(auth.uid()) then
    raise exception 'Only moderators can do this' using errcode = 'insufficient_privilege';
  end if;
  update public.profiles set suspended_at = null where id = person;
  update auth.users set banned_until = null where id = person;
end;
$$;

revoke execute on function public.mod_reports(), public.mod_resolve_report(uuid, text, text),
  public.mod_unsuspend(uuid) from public, anon;
grant execute on function public.mod_reports(), public.mod_resolve_report(uuid, text, text),
  public.mod_unsuspend(uuid) to authenticated;

-- -------------------------------------------------------- Telegram alert

create function private.notify_report() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  token text;
  chat text;
  reporter text;
  reported text;
  open_count int;
  msg text;
begin
  select decrypted_secret into token from vault.decrypted_secrets where name = 'telegram_bot_token';
  select decrypted_secret into chat from vault.decrypted_secrets where name = 'telegram_chat_id';
  if token is null or chat is null then
    return new;
  end if;
  select display_name into reporter from public.profiles where id = new.reporter_id;
  select display_name into reported from public.profiles where id = new.reported_id;
  select count(distinct reporter_id) into open_count from public.reports
    where reported_id = new.reported_id and status = 'open';
  msg := concat_ws(E'\n',
    '🚩 OCTAVA: new report (' || new.reason::text || ')',
    'Reported: ' || coalesce(reported, '?'),
    'By: ' || coalesce(reporter, '?'),
    case when coalesce(new.details, '') <> '' then 'Details: ' || left(new.details, 500) end,
    case when new.reported_text is not null then 'Message: "' || left(new.reported_text, 500) || '"' end,
    'Open reports against them: ' || open_count
      || case when open_count >= 3 then ' (hidden from the feed until reviewed)' else '' end,
    'Review them in the app: Profile → Reports.');
  perform net.http_post(
    url := 'https://api.telegram.org/bot' || token || '/sendMessage',
    body := jsonb_build_object('chat_id', chat, 'text', msg),
    headers := '{"Content-Type": "application/json"}'::jsonb
  );
  return new;
exception when others then
  -- An alert problem must never stop a report from saving.
  return new;
end;
$$;
create trigger reports_notify after insert on public.reports
  for each row execute function private.notify_report();

-- ------------------------------------------- the feed skips under review

CREATE OR REPLACE FUNCTION public.get_deck(max_km double precision DEFAULT 25, instrument_ids text[] DEFAULT NULL::text[], min_skill skill_level DEFAULT NULL::skill_level, genre_filter text[] DEFAULT NULL::text[], goal_filter goal[] DEFAULT NULL::goal[], frequency_filter rehearsal_frequency[] DEFAULT NULL::rehearsal_frequency[], max_results integer DEFAULT 20)
 RETURNS TABLE(id uuid, display_name text, age integer, area text, distance_km integer, looking_for text, genres text[], influences text[], goals goal[], rehearsal_frequency rehearsal_frequency, availability_note text, has_own_gear boolean, has_car boolean, has_rehearsal_space boolean, has_home_studio boolean, avatar_path text, instruments jsonb, links jsonb, clips jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
      -- Suspended, or reported by 3+ people and not yet reviewed.
      and not private.under_review(p.id)
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
$function$;

-- Moderators are added with SQL in the dashboard (not here, so no account
-- details end up in the repo): insert into public.moderators (profile_id) …

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid)
  to authenticated;
