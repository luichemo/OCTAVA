-- Reports can point at a band message: which one, and a copy of its text
-- (kept even if the band or message is deleted later). Reporters can only
-- point at a message the reported person really sent, in a band they're in,
-- with its exact text.
alter table public.reports
  add column band_message_id uuid references public.band_messages (id) on delete set null,
  add column reported_text text check (char_length(reported_text) <= 2000);
create index reports_band_message_idx on public.reports (band_message_id);

alter policy "File a report" on public.reports
  with check (
    reporter_id = (select auth.uid())
    and (
      (band_message_id is null and reported_text is null)
      or exists (
        select 1 from public.band_messages bm
        where bm.id = band_message_id
          and bm.sender_id = reported_id
          and bm.body = reported_text
          and private.is_band_member(bm.band_id, (select auth.uid()))
      )
    )
  );
