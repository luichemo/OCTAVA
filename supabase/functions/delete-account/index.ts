// Deletes the signed-in person's account for good (deployed with JWT
// verification; the caller can only delete themselves).
//
// 1. Leaves each of their bands with leave_band (as them), so open votes are
//    re-settled and a band they were alone in is deleted; that band's files
//    (band clip, song recordings, chat voice messages) are removed too.
// 2. Removes their files: clips and avatar, and the voice messages in their
//    one-on-one chats (those chats go with the account).
// 3. Deletes the auth user. Every table cascades from it (profile, details,
//    swipes, matches, messages, blocks, reports, band rows, read marks).
//
// Answers { deleted: true }, 401 without a valid session, 500 on failure.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

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

/** Removes every file directly inside `folder` of `bucket`. */
async function removeFolder(admin: SupabaseClient, bucket: string, folder: string) {
  const { data } = await admin.storage.from(bucket).list(folder, { limit: 1000 });
  const names = (data ?? []).filter((f) => f.id).map((f) => `${folder}/${f.name}`);
  if (names.length) await admin.storage.from(bucket).remove(names);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Use POST." }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: { user } } = await admin.auth.getUser(token);
  if (!user) return json({ error: "Sign in first." }, 401);
  const uid = user.id;

  try {
    // 1. Leave every band as the person, so the band rules run.
    const asUser = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: memberships } = await admin
      .from("band_members")
      .select("band_id")
      .eq("profile_id", uid);
    for (const { band_id: band } of memberships ?? []) {
      await asUser.rpc("leave_band", { band });
      const { data: still } = await admin.from("bands").select("id").eq("id", band).maybeSingle();
      if (!still) {
        await removeFolder(admin, "band-clips", band);
        await removeFolder(admin, "band-songs", band);
        await removeFolder(admin, "voice", `b/${band}`);
      }
    }

    // 2. Their files, and the voice messages in their one-on-one chats.
    const { data: matches } = await admin
      .from("matches")
      .select("id")
      .or(`user_a.eq.${uid},user_b.eq.${uid}`);
    for (const { id } of matches ?? []) await removeFolder(admin, "voice", `m/${id}`);
    await removeFolder(admin, "clips", uid);
    await removeFolder(admin, "avatars", uid);

    // 3. The account itself; everything else cascades.
    const { error } = await admin.auth.admin.deleteUser(uid);
    if (error) throw error;
    return json({ deleted: true });
  } catch (e) {
    console.error("delete-account failed", uid, e);
    return json({ error: "Couldn't delete the account." }, 500);
  }
});
