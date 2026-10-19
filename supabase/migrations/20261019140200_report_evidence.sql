-- Report review, more context (owner, 2026-10-19):
--  * When someone reports a person they have a one-on-one chat with, the
--    report keeps a copy of that person's last 20 messages to the reporter
--    (`reports.evidence`, oldest first). Only what was sent to the reporter,
--    who has already seen it; moderators see it on the report card.
--  * mod_profile(person) gives moderators the reported person's card (the
--    same shape as a get_deck row), whatever their age group.
--  * Moderators can open those people's clips and avatar files.

alter table public.reports add column evidence jsonb;

create function private.reports_capture_evidence() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  match uuid;
begin
  new.evidence := null;  -- only ever the server's copy, never the reporter's
  if new.band_message_id is not null then
    return new;  -- band-message reports quote the message itself
  end if;
  select m.id into match from public.matches m
  where m.user_a = least(new.reporter_id, new.reported_id)
    and m.user_b = greatest(new.reporter_id, new.reported_id);
  if match is null then
    return new;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
           'at', x.created_at, 'body', x.body,
           'voice', x.audio_path is not null, 'seconds', x.audio_seconds)
         order by x.created_at), '[]'::jsonb)
    into new.evidence
  from (select msg.created_at, msg.body, msg.audio_path, msg.audio_seconds
        from public.messages msg
        where msg.match_id = match and msg.sender_id = new.reported_id
        order by msg.created_at desc limit 20) x;
  return new;
end;
$$;
create trigger reports_capture_evidence before insert on public.reports
  for each row execute function private.reports_capture_evidence();

-- The review list now includes the evidence.
drop function public.mod_reports();
create function public.mod_reports()
returns table (
  id uuid, created_at timestamptz, reason text, details text,
  reported_text text, band_message_id uuid, message_still_there boolean,
  reporter_id uuid, reporter_name text,
  reported_id uuid, reported_name text, reported_suspended boolean,
  open_against int, evidence jsonb
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
          where o.reported_id = r.reported_id and o.status = 'open'),
         r.evidence
  from public.reports r
  left join public.profiles rp on rp.id = r.reporter_id
  left join public.profiles dp on dp.id = r.reported_id
  where r.status = 'open'
  order by r.created_at desc;
end;
$$;
revoke execute on function public.mod_reports() from public, anon;
grant execute on function public.mod_reports() to authenticated;

-- A person's card for moderators, like a get_deck row (no distance).
create function public.mod_profile(person uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  out jsonb;
begin
  if not private.is_moderator(auth.uid()) then
    raise exception 'Only moderators can see this' using errcode = 'insufficient_privilege';
  end if;
  select jsonb_build_object(
    'id', p.id, 'display_name', p.display_name, 'age', private.age_of(p.id),
    'area', p.area, 'looking_for', p.looking_for, 'genres', p.genres,
    'influences', p.influences, 'avatar_path', p.avatar_path,
    'suspended', p.suspended_at is not null, 'joined_at', p.created_at,
    'instruments', coalesce((select jsonb_agg(jsonb_build_object('instrument', pi.instrument_id,
                      'skill', pi.skill, 'is_primary', pi.is_primary) order by pi.is_primary desc, pi.instrument_id)
                    from public.profile_instruments pi where pi.profile_id = p.id), '[]'::jsonb),
    'links', coalesce((select jsonb_agg(jsonb_build_object('kind', l.kind, 'url', l.url))
              from public.profile_links l where l.profile_id = p.id), '[]'::jsonb),
    'clips', coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'path', a.storage_path,
                  'title', a.title, 'seconds', a.duration_seconds)
                  order by (a.id = p.featured_clip_id) desc, a.created_at)
              from public.audio_clips a where a.profile_id = p.id), '[]'::jsonb))
  into out
  from public.profiles p where p.id = person;
  return out;
end;
$$;
revoke execute on function public.mod_profile(uuid) from public, anon;
grant execute on function public.mod_profile(uuid) to authenticated;

-- Moderators can play clips and see avatars of anyone (for reviewing).
create policy "Moderators hear clips" on storage.objects for select to authenticated
  using (bucket_id = 'clips' and private.is_moderator((select auth.uid())));
create policy "Moderators see avatars" on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and private.is_moderator((select auth.uid())));

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid),
  private.is_moderator(uuid)
  to authenticated;
