-- OCTAVA: audio clips can be up to 2:30 (was 2:00).
alter table public.audio_clips drop constraint audio_clips_duration_seconds_check;
alter table public.audio_clips add constraint audio_clips_duration_seconds_check
  check (duration_seconds between 1 and 150);
