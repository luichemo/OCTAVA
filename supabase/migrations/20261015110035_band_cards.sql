-- OCTAVA v2, step 5a: band profiles, band clips, band cards in the deck,
-- and join requests.
--
-- A band's card shows its name, description, genres, open roles, its
-- members' instruments (never names: teens see adult bands here) and the
-- band's own clip. Anyone can swipe on a band (record_band_swipe). A Jam
-- is a join request: a proposal with requested = true and no proposer.
-- Every member must approve, and then the person joins straight away
-- (they asked). The age rule, blocks and limits are checked again then.

-- ---------------------------------------------------------------- band profile

alter table public.bands
  add column description text check (char_length(description) <= 500),
  add column genres text[] not null default '{}',
  add column open_roles text[] not null default '{}',
  add column clip_path text,
  add column clip_seconds int check (clip_seconds between 1 and 120);

-- Genres from the list (lower-cased, no repeats, at most 10); open roles are
-- instrument ids (no repeats, at most 8); the clip must be in the band's
-- own folder of the band-clips bucket.
create function private.check_band_profile() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.genres := coalesce((select array_agg(distinct lower(g)) from unnest(new.genres) g), '{}');
  -- No repeats, keeping the order members chose.
  new.open_roles := coalesce((
    select array_agg(r order by i)
    from (select r, min(i) as i from unnest(new.open_roles) with ordinality as t (r, i) group by r) x
  ), '{}');
  if cardinality(new.genres) > 10 then
    raise exception 'A band can have at most 10 genres' using errcode = 'check_violation';
  end if;
  if exists (select 1 from unnest(new.genres) g where g not in (select id from public.genres)) then
    raise exception 'Pick genres from the list' using errcode = 'check_violation';
  end if;
  if cardinality(new.open_roles) > 8 then
    raise exception 'A band can look for at most 8 roles' using errcode = 'check_violation';
  end if;
  if exists (select 1 from unnest(new.open_roles) r where r not in (select id from public.instruments)) then
    raise exception 'Pick instruments from the list' using errcode = 'check_violation';
  end if;
  if new.clip_path is not null and new.clip_path not like new.id::text || '/%' then
    raise exception 'The clip must be the band''s own' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;
revoke all on function private.check_band_profile() from public, anon, authenticated;

create trigger bands_check_profile
  before insert or update on public.bands
  for each row execute function private.check_band_profile();

-- Any member edits the profile. Pass null for things that stay the same.
create function public.update_band(
  band uuid,
  name text default null,
  description text default null,
  genres text[] default null,
  open_roles text[] default null
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_band_member(band, auth.uid()) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  update public.bands b set
    name = coalesce(btrim(update_band.name), b.name),
    description = case when update_band.description is null then b.description
                       else nullif(btrim(update_band.description), '') end,
    genres = coalesce(update_band.genres, b.genres),
    open_roles = coalesce(update_band.open_roles, b.open_roles)
  where b.id = band;
end;
$$;

-- Sets (or with null, clears) the band's clip, after uploading it to
-- band-clips/<band id>/... Deleting the old file is up to the app.
create function public.set_band_clip(band uuid, path text, seconds int)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_band_member(band, auth.uid()) then
    raise exception 'You''re not in this band' using errcode = 'insufficient_privilege';
  end if;
  update public.bands b
  set clip_path = path, clip_seconds = case when path is null then null else seconds end
  where b.id = band;
end;
$$;

-- ---------------------------------------------------------------- band clip files

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'band-clips', 'band-clips', false, 10485760,
  array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/x-m4a', 'audio/wav', 'audio/x-wav',
        'audio/ogg', 'audio/webm', 'audio/flac']
);

-- Band cards are shown to everyone, so anyone signed in can listen.
create policy "Listen to band clips"
  on storage.objects for select to authenticated
  using (bucket_id = 'band-clips');
create policy "Members upload band clips"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'band-clips'
              and private.is_band_member(private.clip_owner(name), (select auth.uid())));
create policy "Members delete band clips"
  on storage.objects for delete to authenticated
  using (bucket_id = 'band-clips'
         and private.is_band_member(private.clip_owner(name), (select auth.uid())));

-- ---------------------------------------------------------------- swipes on bands

create table public.band_swipes (
  swiper_id uuid not null references public.profiles (id) on delete cascade,
  band_id uuid not null references public.bands (id) on delete cascade,
  decision public.swipe_decision not null,
  created_at timestamptz not null default now(),
  primary key (swiper_id, band_id)
);
create index band_swipes_band_idx on public.band_swipes (band_id);

alter table public.band_swipes enable row level security;
create policy "Read own band swipes" on public.band_swipes
  for select to authenticated using (swiper_id = (select auth.uid()));
revoke all on public.band_swipes from anon;
revoke insert, update, delete on public.band_swipes from authenticated;
grant select on public.band_swipes to authenticated;

-- A join request: the person asked, so nobody proposed them.
alter table public.band_proposals add column requested boolean not null default false;

-- Whether [who] may join [band] now: not full, not in too many bands, no
-- blocks, and the age rule.
create function private.can_join_band(band uuid, who uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select (select count(*) from public.band_members m where m.band_id = band) between 1 and 11
     and (select count(*) from public.band_members m where m.profile_id = who) < 10
     and not private.blocked_in_band(band, who)
     and private.band_age_ok(band, who);
$$;

-- Once every member has approved: an invite goes out, or for a request,
-- the person joins straight away (if the rules still allow it).
create or replace function private.settle_proposal(proposal uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  p public.band_proposals;
begin
  select * into p from public.band_proposals where id = proposal;
  if p.status <> 'voting' or exists (
    select 1 from public.band_members m
    where m.band_id = p.band_id
      and not exists (select 1 from public.band_votes v
                      where v.proposal_id = p.id and v.voter_id = m.profile_id and v.approve)
  ) then
    return;
  end if;
  if not p.requested then
    update public.band_proposals set status = 'invited', decided_at = now() where id = proposal;
  elsif private.can_join_band(p.band_id, p.candidate_id)
        and not private.is_band_member(p.band_id, p.candidate_id) then
    insert into public.band_members (band_id, profile_id, instrument_id)
    values (p.band_id, p.candidate_id, private.main_instrument(p.candidate_id));
    update public.band_proposals set status = 'joined', decided_at = now() where id = proposal;
  else
    update public.band_proposals set status = 'refused', decided_at = now() where id = proposal;
  end if;
end;
$$;

-- Pass or Jam on a band. A Jam sends a join request (once). Returns true
-- when it made a request.
create function public.record_band_swipe(band uuid, decision public.swipe_decision)
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  if me is null or not exists (select 1 from public.profiles where id = me) then
    raise exception 'Set up your profile first' using errcode = 'insufficient_privilege';
  end if;
  if not exists (select 1 from public.bands where id = band) then
    raise exception 'This band isn''t available' using errcode = 'check_violation';
  end if;
  if private.is_band_member(band, me) then
    raise exception 'They''re already in the band' using errcode = 'check_violation';
  end if;
  if not private.can_join_band(band, me) then
    raise exception 'This band isn''t available' using errcode = 'check_violation';
  end if;

  insert into public.band_swipes (swiper_id, band_id, decision)
  values (me, band, record_band_swipe.decision)
  on conflict (swiper_id, band_id) do update set decision = excluded.decision, created_at = now();

  if record_band_swipe.decision = 'jam' and not exists (
    select 1 from public.band_proposals p
    where p.band_id = band and p.candidate_id = me and p.status in ('voting', 'invited')
  ) then
    insert into public.band_proposals (band_id, candidate_id, proposed_by, requested)
    values (band, me, null, true);
    return true;
  end if;
  return false;
end;
$$;

-- Band cards for your deck: bands you're not in, haven't swiped on and
-- haven't asked to join, that you could join now. Members show as
-- instruments only (no names, no ids). Bands needing your main instrument
-- come first.
create function public.get_band_deck(max_results int default 10)
returns table (
  id uuid,
  name text,
  description text,
  genres text[],
  open_roles text[],
  member_instruments text[],
  member_count int,
  clip_path text,
  clip_seconds int,
  fits_you boolean
)
language sql stable security definer set search_path = '' as $$
  with me as (select auth.uid() as id, private.main_instrument(auth.uid()) as role)
  select b.id, b.name, b.description, b.genres, b.open_roles,
    (select coalesce(array_agg(m.instrument_id order by m.joined_at), '{}')
       from public.band_members m where m.band_id = b.id),
    (select count(*)::int from public.band_members m where m.band_id = b.id),
    b.clip_path, b.clip_seconds,
    coalesce(me.role = any (b.open_roles), false)
  from public.bands b, me
  where not private.is_band_member(b.id, me.id)
    and not exists (select 1 from public.band_swipes s where s.swiper_id = me.id and s.band_id = b.id)
    and not exists (select 1 from public.band_proposals p
                    where p.band_id = b.id and p.candidate_id = me.id and p.status in ('voting', 'invited'))
    and private.can_join_band(b.id, me.id)
  order by coalesce(me.role = any (b.open_roles), false) desc, b.created_at desc
  limit least(greatest(max_results, 1), 50);
$$;

-- The temporary tester reset also clears swipes on bands.
create or replace function public.reset_my_swipes()
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
  delete from public.band_swipes where swiper_id = me;
  return removed;
end;
$$;

-- ---------------------------------------------------------------- grants

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid)
  to authenticated;

revoke execute on function public.update_band(uuid, text, text, text[], text[]),
  public.set_band_clip(uuid, text, int),
  public.record_band_swipe(uuid, public.swipe_decision),
  public.get_band_deck(int)
  from public, anon;
grant execute on function public.update_band(uuid, text, text, text[], text[]),
  public.set_band_clip(uuid, text, int),
  public.record_band_swipe(uuid, public.swipe_decision),
  public.get_band_deck(int)
  to authenticated;
