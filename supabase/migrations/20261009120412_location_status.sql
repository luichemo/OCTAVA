-- OCTAVA: let the app know whether you've shared a location, without
-- exposing the (rounded) coordinates themselves, which clients can't read.
create function public.has_my_location()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select p.lat is not null and p.lng is not null from public.profiles p where p.id = auth.uid()), false);
$$;

revoke execute on function public.has_my_location() from public, anon;
grant execute on function public.has_my_location() to authenticated;
