-- TEMPORARY, for testers: clears your own Pass and Jam choices so everyone
-- shows up in your deck again. Swipes that made a match stay (the match
-- and its chat are untouched). Remove before the store launch.
create function public.reset_my_swipes()
returns int language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  removed int;
begin
  if me is null then
    raise exception 'Sign in first' using errcode = 'insufficient_privilege';
  end if;
  delete from public.swipes s
  where s.swiper_id = me
    and not exists (
      select 1 from public.matches m
      where m.user_a = least(me, s.target_id) and m.user_b = greatest(me, s.target_id)
    );
  get diagnostics removed = row_count;
  return removed;
end;
$$;

revoke execute on function public.reset_my_swipes() from public, anon;
grant execute on function public.reset_my_swipes() to authenticated;
