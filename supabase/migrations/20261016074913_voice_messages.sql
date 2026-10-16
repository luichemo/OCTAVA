-- Voice messages in one-on-one and band chats. A message has text, or a
-- voice clip (audio_path + audio_seconds, up to 2 minutes), not both.
-- Clips live in the private `voice` bucket:
--   m/<match id>/<file>   one-on-one chats: only the two people hear it
--   b/<band id>/<file>    band chats: only members hear it
-- Sending a clip follows the same rules as sending text (can_message /
-- can_band_message: blocks, the age rules, locked band chats).

alter table public.messages
  alter column body drop not null,
  drop constraint messages_body_check,
  add column audio_path text,
  add column audio_seconds int check (audio_seconds between 1 and 120),
  add constraint messages_text_or_voice check (
    (audio_path is null and body is not null and char_length(btrim(body)) between 1 and 2000)
    or (audio_path is not null and body is null and audio_seconds is not null)
  );

alter table public.band_messages
  alter column body drop not null,
  drop constraint band_messages_body_check,
  add column audio_path text,
  add column audio_seconds int check (audio_seconds between 1 and 120),
  add constraint band_messages_text_or_voice check (
    (audio_path is null and body is not null and char_length(btrim(body)) between 1 and 2000)
    or (audio_path is not null and body is null and audio_seconds is not null)
  );

-- A voice clip must be in its own chat's folder.
alter policy "Send messages in own matches" on public.messages
  with check (
    sender_id = (select auth.uid())
    and private.can_message(match_id)
    and (audio_path is null or audio_path like 'm/' || match_id::text || '/%')
  );
alter policy "Post in your bands" on public.band_messages
  with check (
    sender_id = (select auth.uid())
    and private.can_band_message(band_id)
    and (audio_path is null or audio_path like 'b/' || band_id::text || '/%')
  );

-- ---------------------------------------------------------------- files

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'voice', 'voice', false, 5242880,
  array['audio/mp4', 'audio/aac', 'audio/x-m4a', 'audio/webm', 'audio/ogg', 'audio/wav', 'audio/x-wav', 'audio/mpeg']
);

-- The chat a voice file belongs to, from its path: ('m' | 'b', id).
create function private.voice_chat(object_name text)
returns table (kind text, chat uuid)
language sql immutable set search_path = '' as $$
  select (storage.foldername(object_name))[1],
         case when (storage.foldername(object_name))[2]
                   ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then (storage.foldername(object_name))[2]::uuid end;
$$;

-- Whether you're in the chat (to listen).
create function private.can_hear_voice(object_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((
    select case v.kind
      when 'm' then exists (select 1 from public.matches m
                            where m.id = v.chat and auth.uid() in (m.user_a, m.user_b))
      when 'b' then private.is_band_member(v.chat, auth.uid())
      else false end
    from private.voice_chat(object_name) v
  ), false);
$$;

-- Whether you may post in the chat (to upload).
create function private.can_send_voice(object_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((
    select case v.kind
      when 'm' then private.can_message(v.chat)
      when 'b' then private.can_band_message(v.chat)
      else false end
    from private.voice_chat(object_name) v
  ), false);
$$;

create policy "Hear voice messages in your chats"
  on storage.objects for select to authenticated
  using (bucket_id = 'voice' and private.can_hear_voice(name));
create policy "Upload voice messages to your chats"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'voice' and private.can_send_voice(name));

-- ---------------------------------------------------------------- grants

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text)
  to authenticated;
