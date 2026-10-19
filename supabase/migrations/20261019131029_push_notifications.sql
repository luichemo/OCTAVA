-- Push notifications (owner, 2026-10-19): new messages (one-on-one and band),
-- new matches, band activity (votes, invites, join requests, someone joined)
-- and rehearsal reminders an hour before. Lock-screen text shows the sender
-- and the message.
--
-- Phones register their Firebase Cloud Messaging token with
-- register_push_token(). Database triggers call the `push` Edge Function
-- (through pg_net) with the event; it works out who to tell and sends via
-- FCM. A pg_cron job asks it every 5 minutes for rehearsal reminders. The
-- call carries a shared secret from the Vault (`push_hook_secret`); without
-- it nothing is sent. The function also does nothing until the Firebase
-- service account is set (Edge Function secret FIREBASE_SERVICE_ACCOUNT).

create extension if not exists pg_cron;

-- ------------------------------------------------------------ device tokens

create table public.push_tokens (
  token text primary key check (char_length(token) between 10 and 4096),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  language text not null default 'en' check (language in ('en', 'ka')),
  updated_at timestamptz not null default now()
);
create index push_tokens_profile_idx on public.push_tokens (profile_id);
-- Only the functions below and the service role touch it.
alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;

-- Registers this device for the signed-in person (a token moves to whoever
-- signed in on that device last), with the app language for the texts.
create function public.register_push_token(token text, platform text, language text default 'en')
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in first' using errcode = 'insufficient_privilege';
  end if;
  insert into public.push_tokens (token, profile_id, platform, language, updated_at)
  values (token, auth.uid(), platform, case when language = 'ka' then 'ka' else 'en' end, now())
  on conflict on constraint push_tokens_pkey do update
    set profile_id = excluded.profile_id, platform = excluded.platform,
        language = excluded.language, updated_at = now();
end;
$$;

-- Stops notifications to this device (on sign-out).
create function public.unregister_push_token(token text)
returns void language sql security definer set search_path = '' as $$
  delete from public.push_tokens t where t.token = unregister_push_token.token and t.profile_id = auth.uid();
$$;

revoke execute on function public.register_push_token(text, text, text), public.unregister_push_token(text) from public, anon;
grant execute on function public.register_push_token(text, text, text), public.unregister_push_token(text) to authenticated;

-- Reminders already sent, so each date is announced once.
create table public.push_reminders_sent (
  rehearsal_id uuid not null references public.rehearsals (id) on delete cascade,
  occurs_on date not null,
  sent_at timestamptz not null default now(),
  primary key (rehearsal_id, occurs_on)
);
alter table public.push_reminders_sent enable row level security;
revoke all on public.push_reminders_sent from anon, authenticated;

-- ------------------------------------------------------------ the hook

-- Lets the Edge Function check the shared secret (service role only).
create function public.push_hook_secret_ok(secret text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from vault.decrypted_secrets s
                 where s.name = 'push_hook_secret' and s.decrypted_secret = secret);
$$;
revoke execute on function public.push_hook_secret_ok(text) from public, anon, authenticated;
grant execute on function public.push_hook_secret_ok(text) to service_role;

-- Tells the push function about an event. Never fails the write that
-- caused it.
create function private.push_hook(event text, payload jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  secret text;
begin
  select decrypted_secret into secret from vault.decrypted_secrets where name = 'push_hook_secret';
  if secret is null then
    return;
  end if;
  perform net.http_post(
    url := 'https://nbvcbhnaevkrnpbjhbbj.supabase.co/functions/v1/push',
    body := jsonb_build_object('event', event) || payload,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', secret)
  );
exception when others then
  null;
end;
$$;

create function private.push_on_message() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform private.push_hook(tg_argv[0], jsonb_build_object('id', new.id));
  return new;
end;
$$;
create trigger messages_push after insert on public.messages
  for each row execute function private.push_on_message('message');
create trigger band_messages_push after insert on public.band_messages
  for each row execute function private.push_on_message('band_message');
create trigger matches_push after insert on public.matches
  for each row execute function private.push_on_message('match');
create trigger band_removals_push after insert on public.band_removals
  for each row execute function private.push_on_message('band_removal');

-- A proposal or join request being voted on, or an invite going out.
create function private.push_on_proposal() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if (tg_op = 'INSERT' and new.status in ('voting', 'invited'))
     or (tg_op = 'UPDATE' and new.status = 'invited' and old.status is distinct from 'invited') then
    perform private.push_hook('band_proposal', jsonb_build_object('id', new.id, 'status', new.status));
  end if;
  return new;
end;
$$;
create trigger band_proposals_push after insert or update of status on public.band_proposals
  for each row execute function private.push_on_proposal();

create function private.push_on_join() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform private.push_hook('band_join', jsonb_build_object('band_id', new.band_id, 'profile_id', new.profile_id));
  return new;
end;
$$;
create trigger band_members_push after insert on public.band_members
  for each row execute function private.push_on_join();

-- Rehearsal reminders: every 5 minutes.
select cron.schedule('octava-push-reminders', '*/5 * * * *',
  $$select private.push_hook('reminders', '{}'::jsonb)$$);

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid)
  to authenticated;
