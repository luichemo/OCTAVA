-- OCTAVA v3, step 3d: the public band page. A band's page can be opened by
-- anyone with its link (no account needed), but only once a member has
-- switched it on. The page itself is served by the `band-page` Edge
-- Function with the service role, so nothing here is readable by `anon`:
-- the function checks is_public and leaves out what must stay private
-- (16–17 year olds' names and pictures, recordings, notes, links).

alter table public.bands add column is_public boolean not null default false;

-- Any member switches the band's public page on or off.
create function public.set_band_public(band uuid, visible boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_band_member(band, auth.uid()) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  update public.bands b set is_public = coalesce(visible, false) where b.id = band;
end;
$$;
revoke execute on function public.set_band_public(uuid, boolean) from public, anon;
grant execute on function public.set_band_public(uuid, boolean) to authenticated;

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid)
  to authenticated;
