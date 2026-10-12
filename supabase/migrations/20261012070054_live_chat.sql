-- Who completed the match (their swipe made it mutual). record_swipe inserts
-- matches inside the caller's request, so the default is the swiper. The
-- other person gets a "new match" banner; the swiper already saw a dialog.
alter table public.matches
  add column created_by uuid default auth.uid() references auth.users (id) on delete set null;
grant select (created_by) on public.matches to authenticated;

-- When each person last read a chat: unread counts and "Seen" receipts.
create table public.match_reads (
  match_id uuid not null references public.matches (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (match_id, user_id)
);

alter table public.match_reads enable row level security;

-- Both people in a match see both read marks (for "Seen").
create policy "Read marks in own matches" on public.match_reads
  for select to authenticated using (
    exists (select 1 from public.matches m
            where m.id = match_id and (select auth.uid()) in (m.user_a, m.user_b))
  );
create policy "Mark own matches read" on public.match_reads
  for insert to authenticated with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.matches m
                where m.id = match_id and (select auth.uid()) in (m.user_a, m.user_b))
  );
create policy "Move own read mark" on public.match_reads
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.match_reads from anon;
grant select, insert, update on public.match_reads to authenticated;

-- The server's clock decides, so nobody can mark a chat read in the future.
create function private.stamp_read() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.last_read_at := now();
  return new;
end;
$$;
revoke all on function private.stamp_read() from public, anon, authenticated;

create trigger match_reads_stamp
  before insert or update on public.match_reads
  for each row execute function private.stamp_read();

-- Live "Seen" updates.
alter publication supabase_realtime add table public.match_reads;
