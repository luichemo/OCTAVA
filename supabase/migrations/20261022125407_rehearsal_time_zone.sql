-- The time zone the rehearsal was set in (the creating or editing device's,
-- e.g. 'Europe/Berlin'), so push reminders work out its local day, weekly
-- repeats across daylight saving, and clock time. Null on older rows: the
-- push function falls back to Asia/Tbilisi, where they were all made.
alter table public.rehearsals
  add column time_zone text
  check (
    time_zone is null
    or (length(time_zone) <= 64 and time_zone ~ '^[A-Za-z][A-Za-z0-9_+/-]*$')
  );

comment on column public.rehearsals.time_zone is
  'IANA time zone of the band (from the device that saved it); null = Asia/Tbilisi.';
