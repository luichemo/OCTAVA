-- OCTAVA: audio clips back to at most 2:00 (reverts clip_length_150s).
alter table public.audio_clips drop constraint audio_clips_duration_seconds_check;
alter table public.audio_clips add constraint audio_clips_duration_seconds_check
  check (duration_seconds between 1 and 120);
