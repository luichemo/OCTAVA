-- The person who asked to join (a Jam on a band card) sees their pending
-- requests: just the band's name and when they asked, never the votes.
-- They can withdraw a request while it's being voted on.
create function public.my_band_requests()
returns table (proposal_id uuid, band_id uuid, band_name text, asked_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select p.id, b.id, b.name, p.created_at
  from public.band_proposals p
  join public.bands b on b.id = p.band_id
  where p.candidate_id = auth.uid() and p.requested and p.status = 'voting'
  order by p.created_at desc;
$$;

create function public.withdraw_band_request(proposal uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.band_proposals
  set status = 'cancelled', decided_at = now()
  where id = proposal and candidate_id = auth.uid() and requested and status = 'voting';
  if not found then
    raise exception 'This request isn''t open' using errcode = 'check_violation';
  end if;
end;
$$;

revoke execute on function public.my_band_requests(), public.withdraw_band_request(uuid) from public, anon;
grant execute on function public.my_band_requests(), public.withdraw_band_request(uuid) to authenticated;
