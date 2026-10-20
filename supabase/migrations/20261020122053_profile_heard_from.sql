-- Where a musician heard about OCTAVA, asked once at the end of sign-up
-- (optional). Only for counting which channels work: clients can set it
-- when creating their profile, but nobody can read it from the app; the
-- owner counts it in the dashboard.
alter table public.profiles
  add column heard_from text
  check (heard_from in ('tiktok', 'instagram', 'friend', 'poster', 'jam_night', 'search', 'other'));

grant insert (heard_from) on public.profiles to authenticated;

comment on column public.profiles.heard_from is
  'Where they heard about OCTAVA (sign-up, optional). Not readable by clients.';
