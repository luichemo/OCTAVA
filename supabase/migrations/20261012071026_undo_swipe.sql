-- Takes back your swipe on someone, so they return to your deck. Not allowed
-- once the swipe made a match (unmatch instead). Returns whether a swipe
-- was removed.
create function public.undo_swipe(target uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  removed int;
begin
  if me is null then
    raise exception 'Sign in first' using errcode = 'insufficient_privilege';
  end if;
  if exists (select 1 from public.matches m
             where m.user_a = least(me, target) and m.user_b = greatest(me, target)) then
    raise exception 'You already matched; unmatch instead' using errcode = 'check_violation';
  end if;
  delete from public.swipes s where s.swiper_id = me and s.target_id = target;
  get diagnostics removed = row_count;
  return removed > 0;
end;
$$;

revoke all on function public.undo_swipe(uuid) from public, anon;
grant execute on function public.undo_swipe(uuid) to authenticated;
