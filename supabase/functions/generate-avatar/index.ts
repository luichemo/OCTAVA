// Generates a riso-poster avatar for the signed-in musician with Cloudflare
// Workers AI (FLUX.1 schnell), saves it to the private "avatars" bucket and
// sets profiles.avatar_path. Limited to DAILY_LIMIT per person per 24 hours.
//
// Secrets (Supabase dashboard -> Edge Functions -> Secrets):
//   CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN (token with Workers AI access)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

const DAILY_LIMIT = 5;
const MODEL = "@cf/black-forest-labs/flux-1-schnell";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

// What the figure plays, for the prompt. Keys are instrument ids.
const SUBJECTS: Record<string, string> = {
  vocals: "a singer holding a vintage microphone",
  guitar: "a guitarist playing an electric guitar",
  bass: "a bass player playing a bass guitar",
  drums: "a drummer playing a drum kit",
  keys: "a keyboard player at a synthesizer",
  percussion: "a percussionist playing congas",
  violin: "a violinist playing a violin",
  cello: "a cellist playing a cello",
  saxophone: "a saxophonist playing a saxophone",
  trumpet: "a trumpet player",
  trombone: "a trombone player",
  flute: "a flute player",
  clarinet: "a clarinet player",
  dj: "a DJ at turntables",
  production: "a music producer at a mixing desk",
  other: "a musician with an instrument",
};

function buildPrompt(instrumentId: string | undefined, genres: string[]): string {
  const subject = SUBJECTS[instrumentId ?? "other"] ?? SUBJECTS.other;
  // Genres are typed by people: keep only plain words, so they can't steer the prompt.
  const mood = genres
    .map((g) => g.toLowerCase().replace(/[^a-z0-9 &-]/g, "").trim().slice(0, 24))
    .filter((g) => g.length > 0)
    .slice(0, 3);
  return [
    "Risograph print poster illustration, two-colour riso print in deep cobalt blue and fluorescent pink",
    "on off-white paper, halftone dot shading, slight print misregistration, grainy paper texture, bold graphic shapes.",
    `Subject: a faceless stylised silhouette of ${subject}, dynamic pose, simple abstract background.`,
    mood.length ? `Mood inspired by ${mood.join(", ")} music.` : "",
    "Clearly an illustration, not a photo. No face details, no text, no letters, no logos.",
  ].join(" ");
}

function base64ToBytes(b64: string): Uint8Array {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Use POST." }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Who is asking.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: { user } } = await admin.auth.getUser(token);
  if (!user) return json({ error: "Sign in first." }, 401);

  const accountId = Deno.env.get("CLOUDFLARE_ACCOUNT_ID")?.trim();
  const cfToken = Deno.env.get("CLOUDFLARE_API_TOKEN")?.trim();
  if (!accountId || !cfToken) {
    return json({ error: "Avatar generation isn't set up yet. Try again later." }, 503);
  }
  // Catch secrets pasted wrongly (e.g. a whole curl command) before using them.
  if (!/^[0-9a-f]{32}$/i.test(accountId) || !/^[A-Za-z0-9_-]{20,}$/.test(cfToken)) {
    console.error("CLOUDFLARE_ACCOUNT_ID or CLOUDFLARE_API_TOKEN doesn't look right");
    return json({ error: "Avatar generation isn't set up correctly yet. Try again later." }, 503);
  }

  const { data: profile } = await admin
    .from("profiles")
    .select("id, genres, avatar_path, profile_instruments(instrument_id, is_primary)")
    .eq("id", user.id)
    .maybeSingle();
  if (!profile) return json({ error: "Create your profile first." }, 404);

  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count } = await admin
    .from("avatar_generations")
    .select("id", { count: "exact", head: true })
    .eq("profile_id", user.id)
    .gte("created_at", since);
  const used = count ?? 0;
  if (used >= DAILY_LIMIT) {
    return json({ error: `You've made ${DAILY_LIMIT} avatars today. Try again tomorrow.`, remaining: 0 }, 429);
  }

  const instruments = (profile.profile_instruments ?? []) as { instrument_id: string; is_primary: boolean }[];
  const main = instruments.find((i) => i.is_primary) ?? instruments[0];
  const prompt = buildPrompt(main?.instrument_id, (profile.genres ?? []) as string[]);

  const cf = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/${MODEL}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${cfToken}`, "Content-Type": "application/json" },
    // Only prompt and steps: this model rejects other fields (even seed).
    body: JSON.stringify({ prompt, steps: 4 }),
  });
  if (!cf.ok) {
    console.error("Cloudflare error", cf.status, await cf.text());
    const status = cf.status === 429 ? 429 : 502;
    return json(
      { error: status === 429 ? "Too many avatars are being made right now. Try again later." : "Couldn't make an avatar right now. Try again." },
      status,
    );
  }
  const image = (await cf.json())?.result?.image as string | undefined;
  if (!image) {
    console.error("Cloudflare returned no image");
    return json({ error: "Couldn't make an avatar right now. Try again." }, 502);
  }

  const path = `${user.id}/${Date.now()}.jpg`;
  const { error: uploadError } = await admin.storage
    .from("avatars")
    .upload(path, base64ToBytes(image), { contentType: "image/jpeg" });
  if (uploadError) {
    console.error("Upload failed", uploadError);
    return json({ error: "Couldn't save your avatar. Try again." }, 500);
  }

  await admin.from("profiles").update({ avatar_path: path }).eq("id", user.id);
  await admin.from("avatar_generations").insert({ profile_id: user.id });
  if (profile.avatar_path) await admin.storage.from("avatars").remove([profile.avatar_path]);

  return json({ path, remaining: DAILY_LIMIT - used - 1 });
});
