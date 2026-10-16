-- OCTAVA v3, step 3a: the band's rehearsal calendar. Any member adds,
-- edits and deletes rehearsals. One can repeat weekly (until a date, or
-- open-ended); each date is an "occurrence" identified by its day
-- (occurs_on, in the band's local calendar as the app sends it). Members
-- answer Going / Can't per occurrence, and a single occurrence of a
-- weekly rehearsal can be cancelled without deleting the series.

create table public.rehearsals (
  id uuid primary key default gen_random_uuid(),
  band_id uuid not null references public.bands (id) on delete cascade,
  starts_at timestamptz not null,
  duration_minutes int not null default 120 check (duration_minutes between 15 and 720),
  place text check (char_length(place) <= 120),
  notes text check (char_length(notes) <= 500),
  weekly boolean not null default false,
  repeat_until date,
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  check (repeat_until is null or weekly)
);
create index rehearsals_band_idx on public.rehearsals (band_id, starts_at);
create index rehearsals_created_by_idx on public.rehearsals (created_by);

-- Going / Can't, per member and date.
create table public.rehearsal_answers (
  rehearsal_id uuid not null references public.rehearsals (id) on delete cascade,
  occurs_on date not null,
  member_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  going boolean not null,
  answered_at timestamptz not null default now(),
  primary key (rehearsal_id, occurs_on, member_id)
);
create index rehearsal_answers_member_idx on public.rehearsal_answers (member_id);

-- Single dates of a weekly rehearsal that are called off.
create table public.rehearsal_cancellations (
  rehearsal_id uuid not null references public.rehearsals (id) on delete cascade,
  occurs_on date not null,
  cancelled_by uuid default auth.uid() references public.profiles (id) on delete set null,
  cancelled_at timestamptz not null default now(),
  primary key (rehearsal_id, occurs_on)
);
create index rehearsal_cancellations_by_idx on public.rehearsal_cancellations (cancelled_by);

-- The band a rehearsal belongs to (security definer, so policies on the
-- answer tables don't depend on reading rehearsals through RLS).
create function private.rehearsal_band(rehearsal uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select band_id from public.rehearsals where id = rehearsal;
$$;

alter table public.rehearsals enable row level security;
alter table public.rehearsal_answers enable row level security;
alter table public.rehearsal_cancellations enable row level security;

-- Members do everything in their band's calendar.
create policy "See your bands' rehearsals" on public.rehearsals
  for select to authenticated using (private.is_band_member(band_id, (select auth.uid())));
create policy "Add rehearsals to your bands" on public.rehearsals
  for insert to authenticated
  with check (private.is_band_member(band_id, (select auth.uid())) and created_by = (select auth.uid()));
create policy "Edit your bands' rehearsals" on public.rehearsals
  for update to authenticated
  using (private.is_band_member(band_id, (select auth.uid())))
  with check (private.is_band_member(band_id, (select auth.uid())));
create policy "Delete your bands' rehearsals" on public.rehearsals
  for delete to authenticated using (private.is_band_member(band_id, (select auth.uid())));

create policy "See answers in your bands" on public.rehearsal_answers
  for select to authenticated
  using (private.is_band_member(private.rehearsal_band(rehearsal_id), (select auth.uid())));
create policy "Answer for yourself" on public.rehearsal_answers
  for insert to authenticated
  with check (member_id = (select auth.uid())
              and private.is_band_member(private.rehearsal_band(rehearsal_id), (select auth.uid())));
create policy "Change your answer" on public.rehearsal_answers
  for update to authenticated
  using (member_id = (select auth.uid()))
  with check (member_id = (select auth.uid())
              and private.is_band_member(private.rehearsal_band(rehearsal_id), (select auth.uid())));
create policy "Take back your answer" on public.rehearsal_answers
  for delete to authenticated using (member_id = (select auth.uid()));

create policy "See cancelled dates in your bands" on public.rehearsal_cancellations
  for select to authenticated
  using (private.is_band_member(private.rehearsal_band(rehearsal_id), (select auth.uid())));
create policy "Cancel a date in your bands" on public.rehearsal_cancellations
  for insert to authenticated
  with check (cancelled_by = (select auth.uid())
              and private.is_band_member(private.rehearsal_band(rehearsal_id), (select auth.uid())));
create policy "Restore a date in your bands" on public.rehearsal_cancellations
  for delete to authenticated
  using (private.is_band_member(private.rehearsal_band(rehearsal_id), (select auth.uid())));

-- The band can't be moved to another band, and the creator stays.
create function private.rehearsals_keep_band() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.band_id := old.band_id;
  new.created_by := old.created_by;
  return new;
end;
$$;
create trigger rehearsals_keep_band before update on public.rehearsals
  for each row execute function private.rehearsals_keep_band();

revoke all on public.rehearsals, public.rehearsal_answers, public.rehearsal_cancellations from anon;
grant select, insert, update, delete on public.rehearsals, public.rehearsal_answers,
  public.rehearsal_cancellations to authenticated;

revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.same_age_group(uuid), private.can_message(uuid),
  private.clip_owner(text), private.is_band_member(uuid, uuid), private.can_see_band(uuid),
  private.knows_via_band(uuid), private.can_band_message(uuid),
  private.can_hear_voice(text), private.can_send_voice(text), private.rehearsal_band(uuid)
  to authenticated;

alter publication supabase_realtime add table public.rehearsals, public.rehearsal_answers,
  public.rehearsal_cancellations;
