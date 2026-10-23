-- A bandmate's or candidate's swipe card (owner, 2026-10-23): members open
-- the card of someone proposed or asking to join before they vote, and
-- bandmates open each other's cards from the band chat. Same shape as one
-- get_deck row. Only for people you know through a band
-- (private.knows_via_band: bandmates, people voted on in your bands, and the
-- members of a band that invited you), with no block either way, not
-- suspended. Across age groups the card has no clips, links or distance,
-- as the band rules already say. Returns null otherwise.
create or replace function public.band_person_card(person uuid)
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
    'distance_km', case when same and me.lat is not null and p.lat is not null
      then greatest(1, round(private.distance_km(me.lat, me.lng, p.lat, p.lng)))::int end,
    'instruments', coalesce((select jsonb_agg(jsonb_build_object('instrument', pi.instrument_id,
                      'skill', pi.skill, 'is_primary', pi.is_primary) order by pi.is_primary desc, pi.instrument_id)
                    from public.profile_instruments pi where pi.profile_id = p.id), '[]'::jsonb),
    'links', coalesce((select jsonb_agg(jsonb_build_object('kind', l.kind, 'url', l.url))
              from public.profile_links l where l.profile_id = p.id and same), '[]'::jsonb),
    'clips', coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'path', a.storage_path,
                  'title', a.title, 'seconds', a.duration_seconds)
                  order by (a.id = p.featured_clip_id) desc, a.created_at)
              from public.audio_clips a where a.profile_id = p.id and same), '[]'::jsonb))
  from public.profiles p
  cross join (select lat, lng from public.profiles where id = auth.uid()) me
  cross join lateral (select private.same_age_group(p.id) as same) g
  where p.id = person
    and p.id <> auth.uid()
    and private.knows_via_band(p.id)
    and not private.is_blocked_between(auth.uid(), p.id)
    and p.suspended_at is null;
$$;

revoke all on function public.band_person_card(uuid) from public, anon;
grant execute on function public.band_person_card(uuid) to authenticated, service_role;
