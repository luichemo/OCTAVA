-- OCTAVA v2, step 1: bands, member proposals with unanimous votes, join
-- invites, band chat and read marks.
--
-- How a member joins: a member proposes someone they matched with
-- (propose_band_member). Every other member must approve (vote_band_member);
-- one "no" refuses it. Then the person gets an invite and accepts or
-- declines (answer_band_invite). A band with one member skips the vote.
-- Clients never write bands, members, proposals or votes directly; these
-- functions check the rules. Members post messages directly (RLS).
--
-- Teens and adults: a band may mix them only when it already has 2+ members
-- before the other age group joins, so a mixed band always has 3+ people.
-- If a mixed band shrinks to 2, its chat locks (band_chat_open).

create type public.band_proposal_status as enum
  ('voting', 'invited', 'joined', 'declined', 'refused');

-- ---------------------------------------------------------------- tables

create table public.bands (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 60),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);
create index bands_created_by_idx on public.bands (created_by);

create table public.band_members (
  band_id uuid not null references public.bands (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  -- Their role in the band: their main instrument when they joined.
  instrument_id text references public.instruments (id),
  joined_at timestamptz not null default now(),
  primary key (band_id, profile_id)
);
create index band_members_profile_idx on public.band_members (profile_id);
create index band_members_instrument_idx on public.band_members (instrument_id);

create table public.band_proposals (
  id uuid primary key default gen_random_uuid(),
  band_id uuid not null references public.bands (id) on delete cascade,
  candidate_id uuid not null references public.profiles (id) on delete cascade,
  proposed_by uuid references public.profiles (id) on delete set null,
  status public.band_proposal_status not null default 'voting',
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
-- One open proposal per person per band.
create unique index band_proposals_open_idx on public.band_proposals (band_id, candidate_id)
  where status in ('voting', 'invited');
create index band_proposals_candidate_idx on public.band_proposals (candidate_id);
create index band_proposals_proposed_by_idx on public.band_proposals (proposed_by);

create table public.band_votes (
  proposal_id uuid not null references public.band_proposals (id) on delete cascade,
  voter_id uuid not null references public.profiles (id) on delete cascade,
  approve boolean not null,
  created_at timestamptz not null default now(),
  primary key (proposal_id, voter_id)
);
create index band_votes_voter_idx on public.band_votes (voter_id);

create table public.band_messages (
  id uuid primary key default gen_random_uuid(),
  band_id uuid not null references public.bands (id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index band_messages_band_idx on public.band_messages (band_id, created_at);
create index band_messages_sender_idx on public.band_messages (sender_id);

create table public.band_reads (
  band_id uuid not null references public.bands (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (band_id, user_id)
);
create index band_reads_user_idx on public.band_reads (user_id);

create trigger band_reads_stamp
  before insert or update on public.band_reads
  for each row execute function private.stamp_read();

-- ---------------------------------------------------------------- helpers
-- Security definer, so policies on band tables can ask about band_members
-- without recursing into band_members' own policy.

create function private.is_band_member(band uuid, who uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.band_members m where m.band_id = band and m.profile_id = who);
$$;

-- Whether you're in this band, or have an open invite to it.
create function private.can_see_band(band uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select private.is_band_member(band, auth.uid())
      or exists (select 1 from public.band_proposals p
                 where p.band_id = band and p.candidate_id = auth.uid() and p.status = 'invited');
$$;

-- Whether [other] is in a band with you, is in a band that invited you, or
-- is being proposed to a band you're in. Lets bandmates see each other's
-- name, instrument and avatar across age groups, only inside bands.
create function private.knows_via_band(other uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
      select 1 from public.band_members mine
      join public.band_members theirs on theirs.band_id = mine.band_id
      where mine.profile_id = auth.uid() and theirs.profile_id = other)
    or exists (
      select 1 from public.band_proposals p
      join public.band_members m on m.band_id = p.band_id
      where p.candidate_id = auth.uid() and p.status = 'invited' and m.profile_id = other)
    or exists (
      select 1 from public.band_proposals p
      join public.band_members m on m.band_id = p.band_id
      where m.profile_id = auth.uid() and p.candidate_id = other and p.status in ('voting', 'invited'));
$$;

-- The age rule for adding [candidate]: if they'd be the first of their age
-- group, the band needs 2+ members already.
create function private.band_age_ok(band uuid, candidate uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select (select count(*) from public.band_members m where m.band_id = band) >= 2
      or not exists (
        select 1 from public.band_members m
        where m.band_id = band
          and (private.age_of(m.profile_id) >= 18) <> (private.age_of(candidate) >= 18));
$$;

-- Whether the band's chat is open: 2+ members, and 3+ if it mixes teens
-- and adults.
create function private.band_chat_open(band uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  with m as (
    select private.age_of(profile_id) >= 18 as adult from public.band_members where band_id = band
  )
  select count(*) >= 3 or (count(*) = 2 and bool_and(adult) = bool_or(adult)) from m;
$$;

create function private.can_band_message(band uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select private.is_band_member(band, auth.uid()) and private.band_chat_open(band);
$$;

-- Whether [candidate] and any member have blocked each other.
create function private.blocked_in_band(band uuid, candidate uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.band_members m
    where m.band_id = band and private.is_blocked_between(m.profile_id, candidate));
$$;

-- Turns a proposal into an invite once every current member has said yes.
create function private.settle_proposal(proposal uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.band_proposals p set status = 'invited', decided_at = now()
  where p.id = proposal and p.status = 'voting'
    and not exists (
      select 1 from public.band_members m
      where m.band_id = p.band_id
        and not exists (select 1 from public.band_votes v
                        where v.proposal_id = p.id and v.voter_id = m.profile_id and v.approve));
end;
$$;

-- ---------------------------------------------------------------- the API

create function public.create_band(name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  band uuid;
begin
  if me is null or not exists (select 1 from public.profiles where id = me) then
    raise exception 'Set up your profile first' using errcode = 'insufficient_privilege';
  end if;
  if (select count(*) from public.band_members where profile_id = me) >= 10 then
    raise exception 'You can be in at most 10 bands' using errcode = 'check_violation';
  end if;
  insert into public.bands (name, created_by) values (btrim(create_band.name), me) returning id into band;
  insert into public.band_members (band_id, profile_id, instrument_id)
  values (band, me, private.main_instrument(me));
  return band;
end;
$$;

-- Proposes one of your matches. Your own vote counts as yes; in a band of
-- one, that's everyone, so the invite goes out straight away.
create function public.propose_band_member(band uuid, candidate uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  proposal uuid;
begin
  if not private.is_band_member(band, me) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  if not exists (select 1 from public.matches m
                 where m.user_a = least(me, candidate) and m.user_b = greatest(me, candidate)) then
    raise exception 'You can only propose people you''ve matched with' using errcode = 'check_violation';
  end if;
  if private.is_band_member(band, candidate) then
    raise exception 'They''re already in the band' using errcode = 'check_violation';
  end if;
  if exists (select 1 from public.band_proposals p
             where p.band_id = band and p.candidate_id = candidate and p.status in ('voting', 'invited')) then
    raise exception 'They''ve already been proposed' using errcode = 'check_violation';
  end if;
  if (select count(*) from public.band_members m where m.band_id = band) >= 12 then
    raise exception 'A band can have at most 12 members' using errcode = 'check_violation';
  end if;
  if private.blocked_in_band(band, candidate) then
    raise exception 'This person isn''t available' using errcode = 'check_violation';
  end if;
  if not private.band_age_ok(band, candidate) then
    raise exception 'A band needs at least 2 members before someone of another age group can join'
      using errcode = 'check_violation';
  end if;

  insert into public.band_proposals (band_id, candidate_id, proposed_by)
  values (band, candidate, me) returning id into proposal;
  insert into public.band_votes (proposal_id, voter_id, approve) values (proposal, me, true);
  perform private.settle_proposal(proposal);
  return proposal;
end;
$$;

-- Yes or no on a proposal in your band. One no refuses it.
create function public.vote_band_member(proposal uuid, approve boolean)
returns public.band_proposal_status language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  p public.band_proposals;
begin
  select * into p from public.band_proposals where id = proposal for update;
  if p.id is null or not private.is_band_member(p.band_id, me) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  if p.status <> 'voting' then
    raise exception 'The vote on this person is over' using errcode = 'check_violation';
  end if;

  insert into public.band_votes (proposal_id, voter_id, approve)
  values (proposal, me, vote_band_member.approve)
  on conflict (proposal_id, voter_id) do update set approve = excluded.approve, created_at = now();

  if not vote_band_member.approve then
    update public.band_proposals set status = 'refused', decided_at = now() where id = proposal;
  else
    perform private.settle_proposal(proposal);
  end if;
  return (select status from public.band_proposals where id = proposal);
end;
$$;

-- The invited person accepts or declines. The rules are checked again,
-- because the band may have changed since the vote.
create function public.answer_band_invite(proposal uuid, accept boolean)
returns public.band_proposal_status language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  p public.band_proposals;
begin
  select * into p from public.band_proposals where id = proposal for update;
  if p.id is null or p.candidate_id <> me or p.status <> 'invited' then
    raise exception 'This invite isn''t open' using errcode = 'check_violation';
  end if;

  if not accept then
    update public.band_proposals set status = 'declined', decided_at = now() where id = proposal;
    return 'declined';
  end if;

  if (select count(*) from public.band_members m where m.band_id = p.band_id) >= 12 then
    raise exception 'The band is full' using errcode = 'check_violation';
  end if;
  if (select count(*) from public.band_members where profile_id = me) >= 10 then
    raise exception 'You can be in at most 10 bands' using errcode = 'check_violation';
  end if;
  if private.blocked_in_band(p.band_id, me) then
    raise exception 'This band isn''t available' using errcode = 'check_violation';
  end if;
  if not private.band_age_ok(p.band_id, me) then
    raise exception 'A band needs at least 2 members before someone of another age group can join'
      using errcode = 'check_violation';
  end if;

  insert into public.band_members (band_id, profile_id, instrument_id)
  values (p.band_id, me, private.main_instrument(me));
  update public.band_proposals set status = 'joined', decided_at = now() where id = proposal;
  return 'joined';
end;
$$;

-- Leaves a band. The last one out deletes it. Votes still open may now be
-- complete, because one fewer person has to approve.
create function public.leave_band(band uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  open_proposal uuid;
begin
  delete from public.band_members where band_id = band and profile_id = me;
  if not found then
    raise exception 'You''re not in this band' using errcode = 'check_violation';
  end if;
  if not exists (select 1 from public.band_members where band_id = band) then
    delete from public.bands where id = band;
    return;
  end if;
  for open_proposal in
    select id from public.band_proposals where band_id = band and status = 'voting'
  loop
    perform private.settle_proposal(open_proposal);
  end loop;
end;
$$;

-- ---------------------------------------------------------------- policies

alter table public.bands enable row level security;
alter table public.band_members enable row level security;
alter table public.band_proposals enable row level security;
alter table public.band_votes enable row level security;
alter table public.band_messages enable row level security;
alter table public.band_reads enable row level security;

create policy "See your bands and invites" on public.bands
  for select to authenticated using (private.can_see_band(id));

create policy "See members of your bands and invites" on public.band_members
  for select to authenticated using (private.can_see_band(band_id));

-- Members see every proposal; the candidate sees only their own open invite
-- (never the vote, or a refusal).
create policy "See proposals in your bands and your invites" on public.band_proposals
  for select to authenticated using (
    private.is_band_member(band_id, (select auth.uid()))
    or (candidate_id = (select auth.uid()) and status = 'invited')
  );

create policy "See votes in your bands" on public.band_votes
  for select to authenticated using (
    exists (select 1 from public.band_proposals p
            where p.id = proposal_id and private.is_band_member(p.band_id, (select auth.uid())))
  );

create policy "Read your bands' messages" on public.band_messages
  for select to authenticated using (private.is_band_member(band_id, (select auth.uid())));
create policy "Post in your bands" on public.band_messages
  for insert to authenticated
  with check (sender_id = (select auth.uid()) and private.can_band_message(band_id));

create policy "See read marks in your bands" on public.band_reads
  for select to authenticated using (private.is_band_member(band_id, (select auth.uid())));
create policy "Mark your bands read" on public.band_reads
  for insert to authenticated
  with check (user_id = (select auth.uid()) and private.is_band_member(band_id, (select auth.uid())));
create policy "Move your band read mark" on public.band_reads
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Bandmates (and people in bands you're joining) see each other's profile
-- and instruments across age groups. Not their clips, links or avatar files
-- (migrations can't change storage policies), and never in the deck:
-- get_deck still uses same_age_group.
alter policy "Read profiles in your age group" on public.profiles
  using (id = (select auth.uid()) or private.same_age_group(id) or private.knows_via_band(id));
alter policy "Read profiles in your age group" on public.profiles rename to "Read profiles in your age group or bands";
alter policy "Read instruments in your age group" on public.profile_instruments
  using (profile_id = (select auth.uid()) or private.same_age_group(profile_id) or private.knows_via_band(profile_id));
alter policy "Read instruments in your age group" on public.profile_instruments rename to "Read instruments in your age group or bands";

-- ---------------------------------------------------------------- grants

revoke all on public.bands, public.band_members, public.band_proposals, public.band_votes,
  public.band_messages, public.band_reads from anon;
revoke insert, update, delete on public.bands, public.band_members, public.band_proposals,
  public.band_votes from authenticated;
grant select on public.bands, public.band_members, public.band_proposals, public.band_votes
  to authenticated;
revoke update, delete on public.band_messages from authenticated;
grant select, insert on public.band_messages to authenticated;
revoke delete on public.band_reads from authenticated;
grant select, insert, update on public.band_reads to authenticated;

revoke execute on all functions in schema private from public, anon, authenticated;
-- Policies run with the caller's rights, so these stay callable.
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid)
  to authenticated;

revoke execute on function public.create_band(text), public.propose_band_member(uuid, uuid),
  public.vote_band_member(uuid, boolean), public.answer_band_invite(uuid, boolean),
  public.leave_band(uuid)
  from public, anon;
grant execute on function public.create_band(text), public.propose_band_member(uuid, uuid),
  public.vote_band_member(uuid, boolean), public.answer_band_invite(uuid, boolean),
  public.leave_band(uuid)
  to authenticated;

-- ---------------------------------------------------------------- realtime

alter publication supabase_realtime add table public.bands, public.band_members,
  public.band_proposals, public.band_votes, public.band_messages, public.band_reads;
