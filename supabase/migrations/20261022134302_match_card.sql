-- A match's swipe card, so people can look at who they matched with
-- (owner, 2026-10-22). Same shape as one get_deck row. Only for someone you
-- share a match with, neither of you has blocked the other, in your own age
-- group (matches always are; checked again in case one turned 18), and not
-- suspended. Returns null otherwise, so the app shows "not available".
create or replace function public.match_card(person uuid)
returns jsonb
language sql
stable
security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'id', p.id, 'display_name', p.display_name, 'age', private.age_of(p.id),
    'area', p.area, 'looking_for', p.looking_for, 'genres', p.genres,
    'influences', p.influences, 'avatar_path', p.avatar_path,
    'distance_km', case when me.lat is not null and p.lat is not null
      then greatest(1, round(private.distance_km(me.lat, me.lng, p.lat, p.lng)))::int end,
    'instruments', coalesce((select jsonb_agg(jsonb_build_object('instrument', pi.instrument_id,
                      'skill', pi.skill, 'is_primary', pi.is_primary) order by pi.is_primary desc, pi.instrument_id)
                    from public.profile_instruments pi where pi.profile_id = p.id), '[]'::jsonb),
    'links', coalesce((select jsonb_agg(jsonb_build_object('kind', l.kind, 'url', l.url))
              from public.profile_links l where l.profile_id = p.id), '[]'::jsonb),
    'clips', coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'path', a.storage_path,
                  'title', a.title, 'seconds', a.duration_seconds)
                  order by (a.id = p.featured_clip_id) desc, a.created_at)
              from public.audio_clips a where a.profile_id = p.id), '[]'::jsonb))
  from public.profiles p
  cross join (select lat, lng from public.profiles where id = auth.uid()) me
  where p.id = person
    and p.id <> auth.uid()
    and exists (
      select 1 from public.matches m
      where (m.user_a = auth.uid() and m.user_b = p.id)
         or (m.user_b = auth.uid() and m.user_a = p.id)
    )
    and not private.is_blocked_between(auth.uid(), p.id)
    and private.same_age_group(p.id)
    and p.suspended_at is null;
$$;

revoke all on function public.match_card(uuid) from public, anon;
grant execute on function public.match_card(uuid) to authenticated, service_role;
