-- Which of your bands' chats are open (2+ members, 3+ when teens and adults
-- mix), so the app can say why a chat is closed before anyone types.
-- Posting is still checked by the band_messages policy.
create function public.my_band_chats()
returns table (band_id uuid, chat_open boolean)
language sql stable security definer set search_path = '' as $$
  select m.band_id, private.band_chat_open(m.band_id)
  from public.band_members m
  where m.profile_id = auth.uid();
$$;

revoke execute on function public.my_band_chats() from public, anon;
grant execute on function public.my_band_chats() to authenticated;
