// Serves a band's public page to anyone with its link, no account needed
// (deployed without JWT verification). Answers only when a member has
// switched the page on (bands.is_public). Reads with the service role and
// returns just what's meant to be public:
//   name, description, genres, open roles, the band clip (a 1-hour link),
//   members (adults: name, avatar link and instrument; 16–17 year olds:
//   their instrument only) and the titles of songs marked Ready.
// Recordings, notes, links, chats and the calendar are never included.
//
// Request: POST { "band": "<uuid>" }. 404 when there's no such public band.

import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const LINK_SECONDS = 60 * 60;

/** Whole years between a "YYYY-MM-DD" birth date and today (UTC). */
function age(birthDate: string): number {
  const [y, m, d] = birthDate.split("-").map(Number);
  const now = new Date();
  let years = now.getUTCFullYear() - y;
  const month = now.getUTCMonth() + 1;
  if (month < m || (month === m && now.getUTCDate() < d)) years--;
  return years;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Use POST." }, 405);

  let bandId: unknown;
  try {
    bandId = (await req.json())?.band;
  } catch {
    return json({ error: "Send { band }." }, 400);
  }
  if (typeof bandId !== "string" || !UUID.test(bandId)) {
    return json({ error: "Not found." }, 404);
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: band } = await admin
    .from("bands")
    .select("id, name, description, genres, open_roles, clip_path, clip_seconds, is_public")
    .eq("id", bandId)
    .maybeSingle();
  if (!band || !band.is_public) return json({ error: "Not found." }, 404);

  const { data: memberRows } = await admin
    .from("band_members")
    .select("profile_id, instrument_id, joined_at")
    .eq("band_id", bandId)
    .order("joined_at");
  const ids = (memberRows ?? []).map((m) => m.profile_id as string);

  const [{ data: profiles }, { data: births }, { data: songs }] = await Promise.all([
    admin.from("profiles").select("id, display_name, avatar_path").in("id", ids),
    admin.from("profile_private").select("id, birth_date").in("id", ids),
    admin
      .from("songs")
      .select("title")
      .eq("band_id", bandId)
      .eq("status", "ready")
      .order("title")
      .limit(50),
  ]);
  const profileOf = new Map((profiles ?? []).map((p) => [p.id as string, p]));
  const adult = new Map(
    (births ?? []).map((b) => [b.id as string, age(b.birth_date as string) >= 18]),
  );

  // Adults' avatars as temporary links, in one request.
  const avatarPaths = ids
    .filter((id) => adult.get(id) && profileOf.get(id)?.avatar_path)
    .map((id) => profileOf.get(id)!.avatar_path as string);
  const avatarUrls = new Map<string, string>();
  if (avatarPaths.length) {
    const { data } = await admin.storage.from("avatars").createSignedUrls(avatarPaths, LINK_SECONDS);
    for (const s of data ?? []) {
      if (s.path && s.signedUrl) avatarUrls.set(s.path, s.signedUrl);
    }
  }

  let clipUrl: string | null = null;
  if (band.clip_path) {
    const { data } = await admin.storage.from("band-clips").createSignedUrl(band.clip_path, LINK_SECONDS);
    clipUrl = data?.signedUrl ?? null;
  }

  return json({
    id: band.id,
    name: band.name,
    description: band.description,
    genres: band.genres ?? [],
    openRoles: band.open_roles ?? [],
    clipUrl,
    clipSeconds: clipUrl ? band.clip_seconds : null,
    // Teens (or anyone whose age is unknown) show as their instrument only.
    members: (memberRows ?? []).map((m) => {
      const id = m.profile_id as string;
      const p = profileOf.get(id);
      const shown = adult.get(id) === true;
      return {
        instrument: m.instrument_id,
        name: shown ? (p?.display_name ?? null) : null,
        avatarUrl: shown && p?.avatar_path ? (avatarUrls.get(p.avatar_path) ?? null) : null,
      };
    }),
    songs: (songs ?? []).map((s) => s.title),
  });
});
