-- Bandmates see each other's avatar files across age groups (the profile
-- row is already visible through knows_via_band).
create policy "See bandmates' avatars"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and private.knows_via_band(private.clip_owner(name)));
