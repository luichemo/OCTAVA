-- OCTAVA v3, step 3b: the band's songs. Any member adds, edits and
-- deletes them. A song has a title, key, tempo, notes, a status (idea →
-- learning → ready), up to 5 links and a recording. Recordings are private
-- to the band (unlike the band clip on its card): the `band-songs` bucket
-- at <band id>/<file>, readable and writable only by members.

create type public.song_status as enum ('idea', 'learning', 'ready');

create table public.songs (
  id uuid primary key default gen_random_uuid(),
  band_id uuid not null references public.bands (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 100),
  song_key text check (char_length(song_key) <= 20),
  tempo int check (tempo between 20 and 320),
  notes text check (char_length(notes) <= 1000),
  status public.song_status not null default 'idea',
  links text[] not null default '{}' check (cardinality(links) <= 5),
  recording_path text,
  recording_seconds int check (recording_seconds between 1 and 600),
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (recording_path is null or recording_path like band_id::text || '/%')
);
create index songs_band_idx on public.songs (band_id, title);
create index songs_created_by_idx on public.songs (created_by);

-- The band and creator can't change; updated_at follows edits.
create function private.songs_before_update() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.band_id := old.band_id;
  new.created_by := old.created_by;
  new.updated_at := now();
  return new;
end;
$$;
create trigger songs_before_update before update on public.songs
  for each row execute function private.songs_before_update();

alter table public.songs enable row level security;
create policy "See your bands' songs" on public.songs
  for select to authenticated using (private.is_band_member(band_id, (select auth.uid())));
create policy "Add songs to your bands" on public.songs
  for insert to authenticated
  with check (private.is_band_member(band_id, (select auth.uid())) and created_by = (select auth.uid()));
create policy "Edit your bands' songs" on public.songs
  for update to authenticated
  using (private.is_band_member(band_id, (select auth.uid())))
  with check (private.is_band_member(band_id, (select auth.uid())));
create policy "Delete your bands' songs" on public.songs
  for delete to authenticated using (private.is_band_member(band_id, (select auth.uid())));

revoke all on public.songs from anon;
grant select, insert, update, delete on public.songs to authenticated;

-- ---------------------------------------------------------------- recordings

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'band-songs', 'band-songs', false, 10485760,
  array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/x-m4a', 'audio/wav', 'audio/x-wav',
        'audio/ogg', 'audio/webm', 'audio/flac']
);

create policy "Members hear their songs"
  on storage.objects for select to authenticated
  using (bucket_id = 'band-songs'
         and private.is_band_member(private.clip_owner(name), (select auth.uid())));
create policy "Members upload song recordings"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'band-songs'
              and private.is_band_member(private.clip_owner(name), (select auth.uid())));
create policy "Members delete song recordings"
  on storage.objects for delete to authenticated
  using (bucket_id = 'band-songs'
         and private.is_band_member(private.clip_owner(name), (select auth.uid())));

alter publication supabase_realtime add table public.songs;

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid)
  to authenticated;
