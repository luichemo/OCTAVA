-- Removing (kicking) a band member: any member proposes it, and it
-- happens once a majority of the other members (everyone but the person
-- being removed) say yes: 2 of 2 in a band of 3, 3 of 4 in a band of 5,
-- 1 of 1 in a band of 2. The proposer's yes counts. The person being
-- removed doesn't vote and never sees the vote.

create type public.band_removal_status as enum ('voting', 'removed', 'refused', 'cancelled');

create table public.band_removals (
  id uuid primary key default gen_random_uuid(),
  band_id uuid not null references public.bands (id) on delete cascade,
  target_id uuid not null references public.profiles (id) on delete cascade,
  proposed_by uuid references public.profiles (id) on delete set null,
  status public.band_removal_status not null default 'voting',
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
create unique index band_removals_open_idx on public.band_removals (band_id, target_id)
  where status = 'voting';
create index band_removals_target_idx on public.band_removals (target_id);
create index band_removals_proposed_by_idx on public.band_removals (proposed_by);

create table public.band_removal_votes (
  removal_id uuid not null references public.band_removals (id) on delete cascade,
  voter_id uuid not null references public.profiles (id) on delete cascade,
  approve boolean not null,
  created_at timestamptz not null default now(),
  primary key (removal_id, voter_id)
);
create index band_removal_votes_voter_idx on public.band_removal_votes (voter_id);

-- Counts the votes of current members (other than the target): removes
-- them on a majority, refuses once a majority can't be reached any more,
-- and cancels if they've already left.
create function private.settle_removal(removal uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  r public.band_removals;
  others int;
  needed int;
  yes int;
  no int;
  open_proposal uuid;
begin
  select * into r from public.band_removals where id = removal;
  if r.status <> 'voting' then return; end if;
  if not private.is_band_member(r.band_id, r.target_id) then
    update public.band_removals set status = 'cancelled', decided_at = now() where id = removal;
    return;
  end if;
  select count(*) into others from public.band_members m
  where m.band_id = r.band_id and m.profile_id <> r.target_id;
  needed := others / 2 + 1;
  select count(*) filter (where v.approve), count(*) filter (where not v.approve)
    into yes, no
  from public.band_removal_votes v
  join public.band_members m on m.band_id = r.band_id and m.profile_id = v.voter_id
  where v.removal_id = removal and v.voter_id <> r.target_id;

  if yes >= needed then
    delete from public.band_members where band_id = r.band_id and profile_id = r.target_id;
    update public.band_removals set status = 'removed', decided_at = now() where id = removal;
    -- One fewer member: open join votes may now be complete.
    for open_proposal in
      select id from public.band_proposals where band_id = r.band_id and status = 'voting'
    loop
      perform private.settle_proposal(open_proposal);
    end loop;
  elsif others - no < needed then
    update public.band_removals set status = 'refused', decided_at = now() where id = removal;
  end if;
end;
$$;

create function public.propose_band_removal(band uuid, target uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  removal uuid;
begin
  if not private.is_band_member(band, me) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  if target = me then
    raise exception 'Use Leave band to leave' using errcode = 'check_violation';
  end if;
  if not private.is_band_member(band, target) then
    raise exception 'They''re not in the band' using errcode = 'check_violation';
  end if;
  if exists (select 1 from public.band_removals r
             where r.band_id = band and r.target_id = target and r.status = 'voting') then
    raise exception 'There''s already a vote on removing them' using errcode = 'check_violation';
  end if;
  insert into public.band_removals (band_id, target_id, proposed_by)
  values (band, target, me) returning id into removal;
  insert into public.band_removal_votes (removal_id, voter_id, approve) values (removal, me, true);
  perform private.settle_removal(removal);
  return removal;
end;
$$;

create function public.vote_band_removal(removal uuid, approve boolean)
returns public.band_removal_status language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  r public.band_removals;
begin
  select * into r from public.band_removals where id = removal for update;
  if r.id is null or not private.is_band_member(r.band_id, me) or r.target_id = me then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  if r.status <> 'voting' then
    raise exception 'The vote on this person is over' using errcode = 'check_violation';
  end if;
  insert into public.band_removal_votes (removal_id, voter_id, approve)
  values (removal, me, vote_band_removal.approve)
  on conflict (removal_id, voter_id) do update set approve = excluded.approve, created_at = now();
  perform private.settle_removal(removal);
  return (select status from public.band_removals where id = removal);
end;
$$;

-- The proposer withdraws it (or any member, if the proposer has left).
create function public.cancel_band_removal(removal uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  r public.band_removals;
begin
  select * into r from public.band_removals where id = removal for update;
  if r.id is null or not private.is_band_member(r.band_id, me) or r.target_id = me then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  if r.status <> 'voting' then
    raise exception 'The vote on this person is over' using errcode = 'check_violation';
  end if;
  if r.proposed_by is distinct from me and private.is_band_member(r.band_id, r.proposed_by) then
    raise exception 'Only the person who proposed them can cancel' using errcode = 'insufficient_privilege';
  end if;
  update public.band_removals set status = 'cancelled', decided_at = now() where id = removal;
end;
$$;

-- Leaving also re-counts removal votes (and cancels any against you).
create or replace function public.leave_band(band uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  open_id uuid;
begin
  delete from public.band_members where band_id = band and profile_id = me;
  if not found then
    raise exception 'You''re not in this band' using errcode = 'check_violation';
  end if;
  if not exists (select 1 from public.band_members where band_id = band) then
    delete from public.bands where id = band;
    return;
  end if;
  for open_id in
    select id from public.band_proposals where band_id = band and status = 'voting'
  loop
    perform private.settle_proposal(open_id);
  end loop;
  for open_id in
    select id from public.band_removals where band_id = band and status = 'voting'
  loop
    perform private.settle_removal(open_id);
  end loop;
end;
$$;

-- ---------------------------------------------------------------- policies

alter table public.band_removals enable row level security;
alter table public.band_removal_votes enable row level security;

-- Members see removal votes, except the person they're about.
create policy "See removal votes in your bands" on public.band_removals
  for select to authenticated using (
    private.is_band_member(band_id, (select auth.uid())) and target_id <> (select auth.uid())
  );
create policy "See removal ballots in your bands" on public.band_removal_votes
  for select to authenticated using (
    exists (select 1 from public.band_removals r
            where r.id = removal_id
              and private.is_band_member(r.band_id, (select auth.uid()))
              and r.target_id <> (select auth.uid()))
  );

revoke all on public.band_removals, public.band_removal_votes from anon;
revoke insert, update, delete on public.band_removals, public.band_removal_votes from authenticated;
grant select on public.band_removals, public.band_removal_votes to authenticated;

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid)
  to authenticated;

revoke execute on function public.propose_band_removal(uuid, uuid),
  public.vote_band_removal(uuid, boolean), public.cancel_band_removal(uuid)
  from public, anon;
grant execute on function public.propose_band_removal(uuid, uuid),
  public.vote_band_removal(uuid, boolean), public.cancel_band_removal(uuid)
  to authenticated;

alter publication supabase_realtime add table public.band_removals, public.band_removal_votes;
