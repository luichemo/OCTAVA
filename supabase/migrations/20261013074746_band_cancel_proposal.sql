-- The member who proposed someone can withdraw it, while it's being voted
-- on or after the invite went out. If they've left the band, any member
-- can, so no request gets stuck. The candidate only ever saw the invite,
-- which simply disappears.
alter type public.band_proposal_status add value 'cancelled';

create function public.cancel_band_proposal(proposal uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  p public.band_proposals;
begin
  select * into p from public.band_proposals where id = proposal for update;
  if p.id is null or not private.is_band_member(p.band_id, me) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  if p.status not in ('voting', 'invited') then
    raise exception 'The vote on this person is over' using errcode = 'check_violation';
  end if;
  if p.proposed_by is distinct from me and private.is_band_member(p.band_id, p.proposed_by) then
    raise exception 'Only the person who proposed them can cancel' using errcode = 'insufficient_privilege';
  end if;
  update public.band_proposals set status = 'cancelled', decided_at = now() where id = proposal;
end;
$$;

revoke execute on function public.cancel_band_proposal(uuid) from public, anon;
grant execute on function public.cancel_band_proposal(uuid) to authenticated;
