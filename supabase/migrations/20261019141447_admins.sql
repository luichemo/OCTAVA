-- Admins (owner, 2026-10-19): admins add and remove moderators in the app.
-- Rows are added with SQL in the dashboard, never in a migration, so account
-- details stay out of the repo. An admin is always also a moderator and
-- can't be removed from the app.

create table public.admins (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  added_at timestamptz not null default now()
);
alter table public.admins enable row level security;
create policy "See whether you're an admin" on public.admins
  for select to authenticated using (profile_id = (select auth.uid()));
revoke all on public.admins from anon, authenticated;
grant select on public.admins to authenticated;

alter table public.moderators add column added_by uuid references public.profiles(id) on delete set null;

create function private.is_admin(person uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins a where a.profile_id = person);
$$;

-- Current moderators, admins first, then by when they were added.
create function public.admin_moderators()
returns table (id uuid, display_name text, avatar_path text, instrument_id text,
               is_admin boolean, added_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.is_admin(auth.uid()) then
    raise exception 'Only admins can manage moderators' using errcode = 'insufficient_privilege';
  end if;
  return query
  select p.id, p.display_name, p.avatar_path, private.main_instrument(p.id),
         private.is_admin(p.id), m.added_at
  from public.moderators m join public.profiles p on p.id = m.profile_id
  order by private.is_admin(p.id) desc, m.added_at;
end;
$$;

-- People whose name contains the text (any age group), up to 20.
create function public.admin_find_people(query text)
returns table (id uuid, display_name text, avatar_path text, instrument_id text,
               age int, is_moderator boolean, suspended boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
  q text := btrim(coalesce(query, ''));
begin
  if not private.is_admin(auth.uid()) then
    raise exception 'Only admins can manage moderators' using errcode = 'insufficient_privilege';
  end if;
  if length(q) < 2 then
    return;
  end if;
  q := replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_');
  return query
  select p.id, p.display_name, p.avatar_path, private.main_instrument(p.id),
         private.age_of(p.id), private.is_moderator(p.id), p.suspended_at is not null
  from public.profiles p
  where p.display_name ilike '%' || q || '%'
  order by (p.display_name ilike q) desc, (p.display_name ilike q || '%') desc, p.display_name
  limit 20;
end;
$$;

create function public.admin_set_moderator(person uuid, make boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_admin(auth.uid()) then
    raise exception 'Only admins can manage moderators' using errcode = 'insufficient_privilege';
  end if;
  if make then
    if not exists (select 1 from public.profiles p where p.id = person) then
      raise exception 'No such person' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.profiles p where p.id = person and p.suspended_at is not null) then
      raise exception 'A suspended account can''t be a moderator' using errcode = 'P0001';
    end if;
    insert into public.moderators (profile_id, added_by) values (person, auth.uid())
      on conflict (profile_id) do nothing;
  else
    if private.is_admin(person) then
      raise exception 'An admin stays a moderator' using errcode = 'P0001';
    end if;
    delete from public.moderators where profile_id = person;
  end if;
end;
$$;

revoke execute on function public.admin_moderators(), public.admin_find_people(text),
  public.admin_set_moderator(uuid, boolean) from public, anon;
grant execute on function public.admin_moderators(), public.admin_find_people(text),
  public.admin_set_moderator(uuid, boolean) to authenticated;

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid),
  private.is_moderator(uuid)
  to authenticated;
