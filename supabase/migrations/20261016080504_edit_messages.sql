-- Editing your own text messages, within 15 minutes of sending, in
-- one-on-one and band chats. Edited messages show "edited" (edited_at).
-- Earlier versions are kept in *_edits tables that clients can't read, so
-- reports can still see what was first said (read them in the dashboard).

alter table public.messages add column edited_at timestamptz;
alter table public.band_messages add column edited_at timestamptz;
grant select (edited_at) on public.messages, public.band_messages to authenticated;

create table public.message_edits (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages (id) on delete cascade,
  old_body text not null,
  edited_at timestamptz not null default now()
);
create index message_edits_message_idx on public.message_edits (message_id);

create table public.band_message_edits (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.band_messages (id) on delete cascade,
  old_body text not null,
  edited_at timestamptz not null default now()
);
create index band_message_edits_message_idx on public.band_message_edits (message_id);

-- Moderation only: no policies, so clients see nothing.
alter table public.message_edits enable row level security;
alter table public.band_message_edits enable row level security;
revoke all on public.message_edits, public.band_message_edits from anon, authenticated;

create function public.edit_message(message uuid, body text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  m public.messages;
  clean text := btrim(edit_message.body);
begin
  select * into m from public.messages where id = message for update;
  if m.id is null or m.sender_id <> me then
    raise exception 'You can only edit your own messages' using errcode = 'insufficient_privilege';
  end if;
  if m.audio_path is not null then
    raise exception 'Voice messages can''t be edited' using errcode = 'check_violation';
  end if;
  if m.created_at < now() - interval '15 minutes' then
    raise exception 'Messages can only be edited for 15 minutes' using errcode = 'check_violation';
  end if;
  -- Same rules as sending (blocks, the age rule).
  if not private.can_message(m.match_id) then
    raise exception 'You can''t send messages in this chat' using errcode = 'insufficient_privilege';
  end if;
  if char_length(clean) not between 1 and 2000 then
    raise exception 'A message needs 1 to 2000 characters' using errcode = 'check_violation';
  end if;
  if clean = m.body then return; end if;
  insert into public.message_edits (message_id, old_body) values (m.id, m.body);
  update public.messages set body = clean, edited_at = now() where id = m.id;
end;
$$;

create function public.edit_band_message(message uuid, body text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  m public.band_messages;
  clean text := btrim(edit_band_message.body);
begin
  select * into m from public.band_messages where id = message for update;
  if m.id is null or m.sender_id <> me then
    raise exception 'You can only edit your own messages' using errcode = 'insufficient_privilege';
  end if;
  if m.audio_path is not null then
    raise exception 'Voice messages can''t be edited' using errcode = 'check_violation';
  end if;
  if m.created_at < now() - interval '15 minutes' then
    raise exception 'Messages can only be edited for 15 minutes' using errcode = 'check_violation';
  end if;
  if not private.can_band_message(m.band_id) then
    raise exception 'You can''t send messages in this chat' using errcode = 'insufficient_privilege';
  end if;
  if char_length(clean) not between 1 and 2000 then
    raise exception 'A message needs 1 to 2000 characters' using errcode = 'check_violation';
  end if;
  if clean = m.body then return; end if;
  insert into public.band_message_edits (message_id, old_body) values (m.id, m.body);
  update public.band_messages set body = clean, edited_at = now() where id = m.id;
end;
$$;

revoke execute on function public.edit_message(uuid, text), public.edit_band_message(uuid, text)
  from public, anon;
grant execute on function public.edit_message(uuid, text), public.edit_band_message(uuid, text)
  to authenticated;
