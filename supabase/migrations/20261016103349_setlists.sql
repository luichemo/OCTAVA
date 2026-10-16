-- OCTAVA v3, step 3c: setlists. A setlist is a named, ordered list of the
-- band's own songs. Any member adds, renames, reorders and deletes them.
-- A rehearsal can link one setlist to practise.
--
-- Members write `setlists` directly; the songs in one are only replaced as
-- a whole through set_setlist_songs(), so the order is always consistent
-- and every song belongs to the same band.

create table public.setlists (
  id uuid primary key default gen_random_uuid(),
  band_id uuid not null references public.bands (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 60),
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index setlists_band_idx on public.setlists (band_id, name);
create index setlists_created_by_idx on public.setlists (created_by);

-- band_id is copied from the setlist so policies don't need a helper.
create table public.setlist_songs (
  setlist_id uuid not null references public.setlists (id) on delete cascade,
  band_id uuid not null references public.bands (id) on delete cascade,
  song_id uuid not null references public.songs (id) on delete cascade,
  position int not null check (position between 1 and 60),
  primary key (setlist_id, song_id),
  unique (setlist_id, position)
);
create index setlist_songs_song_idx on public.setlist_songs (song_id);
create index setlist_songs_band_idx on public.setlist_songs (band_id);

-- The band and creator can't change; updated_at follows edits.
create function private.setlists_before_update() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.band_id := old.band_id;
  new.created_by := old.created_by;
  new.updated_at := now();
  return new;
end;
$$;
create trigger setlists_before_update before update on public.setlists
  for each row execute function private.setlists_before_update();

alter table public.setlists enable row level security;
alter table public.setlist_songs enable row level security;

create policy "See your bands' setlists" on public.setlists
  for select to authenticated using (private.is_band_member(band_id, (select auth.uid())));
create policy "Add setlists to your bands" on public.setlists
  for insert to authenticated
  with check (private.is_band_member(band_id, (select auth.uid())) and created_by = (select auth.uid()));
create policy "Edit your bands' setlists" on public.setlists
  for update to authenticated
  using (private.is_band_member(band_id, (select auth.uid())))
  with check (private.is_band_member(band_id, (select auth.uid())));
create policy "Delete your bands' setlists" on public.setlists
  for delete to authenticated using (private.is_band_member(band_id, (select auth.uid())));

create policy "See songs in your bands' setlists" on public.setlist_songs
  for select to authenticated using (private.is_band_member(band_id, (select auth.uid())));

revoke all on public.setlists, public.setlist_songs from anon;
grant select, insert, update, delete on public.setlists to authenticated;
revoke all on public.setlist_songs from authenticated;
grant select on public.setlist_songs to authenticated;

-- Replaces a setlist's songs with `song_ids`, in that order. Repeats are
-- dropped (the first one stays); every song must be the band's own.
create function public.set_setlist_songs(setlist uuid, song_ids uuid[])
returns void language plpgsql security definer set search_path = '' as $$
declare
  band uuid;
  ids uuid[];
begin
  select s.band_id into band from public.setlists s where s.id = setlist;
  if band is null or not private.is_band_member(band, auth.uid()) then
    raise exception 'You are not in this band' using errcode = '42501';
  end if;
  select coalesce(array_agg(id order by first_at), '{}') into ids
  from (select id, min(ord) as first_at
        from unnest(coalesce(song_ids, '{}')) with ordinality as u(id, ord)
        group by id) d;
  if cardinality(ids) > 60 then
    raise exception 'A setlist can have up to 60 songs' using errcode = 'P0001';
  end if;
  if exists (select 1 from unnest(ids) as u(id)
             where not exists (select 1 from public.songs so
                               where so.id = u.id and so.band_id = band)) then
    raise exception 'That song is not in this band' using errcode = 'P0001';
  end if;
  delete from public.setlist_songs where setlist_id = setlist;
  insert into public.setlist_songs (setlist_id, band_id, song_id, position)
  select setlist, band, u.id, u.ord::int from unnest(ids) with ordinality as u(id, ord);
  update public.setlists set updated_at = now() where id = setlist;
end;
$$;
revoke execute on function public.set_setlist_songs(uuid, uuid[]) from public, anon;
grant execute on function public.set_setlist_songs(uuid, uuid[]) to authenticated;

-- ------------------------------------------------- a rehearsal's setlist

alter table public.rehearsals
  add column setlist_id uuid references public.setlists (id) on delete set null;
create index rehearsals_setlist_idx on public.rehearsals (setlist_id);

-- The linked setlist must be the same band's. On update the band is the
-- stored one (rehearsals_keep_band resets any change to it).
create function private.rehearsals_check_setlist() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  band uuid := case when tg_op = 'UPDATE' then old.band_id else new.band_id end;
begin
  if new.setlist_id is not null and not exists (
    select 1 from public.setlists s where s.id = new.setlist_id and s.band_id = band
  ) then
    raise exception 'That setlist is not in this band' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
create trigger rehearsals_check_setlist before insert or update of setlist_id on public.rehearsals
  for each row execute function private.rehearsals_check_setlist();

alter publication supabase_realtime add table public.setlists, public.setlist_songs;

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid)
  to authenticated;
