-- The temporary tester button "Reset my swipes (test)" is gone from the app
-- (owner, 2026-10-20, before launch), so its function goes too.
drop function if exists public.reset_my_swipes();
