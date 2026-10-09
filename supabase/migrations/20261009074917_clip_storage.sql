-- OCTAVA v1: storage bucket for audio clips.
-- Files live at clips/<profile_id>/<file>. Private bucket: the app plays clips
-- through signed URLs, and only people in the owner's age group can get them.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'clips', 'clips', false, 10485760,  -- 10 MB
  array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/x-m4a', 'audio/wav',
        'audio/x-wav', 'audio/ogg', 'audio/webm', 'audio/flac']
);

-- The owner of a clip file, from its folder name (null if it isn't a uuid).
create function public.clip_owner(object_name text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when (storage.foldername(object_name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then (storage.foldername(object_name))[1]::uuid
  end;
$$;

revoke execute on function public.clip_owner(text) from public, anon;
grant execute on function public.clip_owner(text) to authenticated;

create policy "Listen to clips in your age group"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'clips'
    and (public.clip_owner(name) = (select auth.uid()) or public.same_age_group(public.clip_owner(name)))
  );

create policy "Upload clips to your own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'clips' and public.clip_owner(name) = (select auth.uid()));

create policy "Replace your own clips"
  on storage.objects for update to authenticated
  using (bucket_id = 'clips' and public.clip_owner(name) = (select auth.uid()))
  with check (bucket_id = 'clips' and public.clip_owner(name) = (select auth.uid()));

create policy "Delete your own clips"
  on storage.objects for delete to authenticated
  using (bucket_id = 'clips' and public.clip_owner(name) = (select auth.uid()));
