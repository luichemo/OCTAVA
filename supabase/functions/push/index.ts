// Sends push notifications through Firebase Cloud Messaging (HTTP v1).
// Called by database triggers and a 5-minute cron job (migration
// 20261019131029_push_notifications) with a shared secret header; deployed
// without JWT verification, since the caller is the database.
//
// Events: message, band_message, match, band_proposal (voting → the other
// members; invited → the candidate), band_join, band_removal, reminders
// (rehearsals starting in about an hour, for members who haven't said
// Can't). Texts follow each device's language (en / ka). Tokens Firebase
// rejects as gone are deleted.
//
// Needs the Edge Function secret FIREBASE_SERVICE_ACCOUNT (the service
// account JSON from Firebase → Project settings → Service accounts).
// Without it, it answers { skipped } and sends nothing.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

type Lang = "en" | "ka";
type Text = { title: string; body: string };
type Note = { to: string[]; text: (lang: Lang) => Text; data: Record<string, string> };

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const clip = (s: string, n = 140) => (s.length > n ? s.slice(0, n - 1) + "…" : s);
const voice = { en: "🎤 Voice message", ka: "🎤 ხმოვანი შეტყობინება" };

// ------------------------------------------------------------ Firebase auth

let cachedToken: { value: string; expires: number } | null = null;

function base64url(bytes: Uint8Array | string): string {
  const b = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let s = "";
  for (const c of b) s += String.fromCharCode(c);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: { client_email: string; private_key: string; token_uri?: string }) {
  if (cachedToken && cachedToken.expires > Date.now() + 60_000) return cachedToken.value;
  const now = Math.floor(Date.now() / 1000);
  const tokenUri = sa.token_uri ?? "https://oauth2.googleapis.com/token";
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${base64url(signature)}`,
    }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`Google token: ${res.status} ${JSON.stringify(body)}`);
  cachedToken = { value: body.access_token, expires: Date.now() + body.expires_in * 1000 };
  return cachedToken.value;
}

// ------------------------------------------------------------ helpers

async function name(admin: SupabaseClient, id: string | null): Promise<string> {
  if (!id) return "?";
  const { data } = await admin.from("profiles").select("display_name").eq("id", id).maybeSingle();
  return data?.display_name ?? "?";
}

async function bandName(admin: SupabaseClient, id: string): Promise<string> {
  const { data } = await admin.from("bands").select("name").eq("id", id).maybeSingle();
  return data?.name ?? "OCTAVA";
}

async function members(admin: SupabaseClient, band: string): Promise<string[]> {
  const { data } = await admin.from("band_members").select("profile_id").eq("band_id", band);
  return (data ?? []).map((m) => m.profile_id as string);
}

/** Who to tell, and what, for one event. */
async function plan(admin: SupabaseClient, e: Record<string, string>): Promise<Note[]> {
  switch (e.event) {
    case "message": {
      const { data: m } = await admin.from("messages")
        .select("match_id, sender_id, body, audio_path").eq("id", e.id).maybeSingle();
      if (!m) return [];
      const { data: match } = await admin.from("matches").select("user_a, user_b").eq("id", m.match_id).maybeSingle();
      if (!match) return [];
      const to = match.user_a === m.sender_id ? match.user_b : match.user_a;
      const from = await name(admin, m.sender_id);
      return [{
        to: [to],
        text: (l) => ({ title: from, body: m.audio_path ? voice[l] : clip(m.body ?? "") }),
        data: { type: "chat", match_id: m.match_id },
      }];
    }
    case "band_message": {
      const { data: m } = await admin.from("band_messages")
        .select("band_id, sender_id, body, audio_path").eq("id", e.id).maybeSingle();
      if (!m) return [];
      const [band, from, all] = await Promise.all([
        bandName(admin, m.band_id), name(admin, m.sender_id), members(admin, m.band_id),
      ]);
      return [{
        to: all.filter((p) => p !== m.sender_id),
        text: (l) => ({ title: band, body: `${from}: ${m.audio_path ? voice[l] : clip(m.body ?? "")}` }),
        data: { type: "band", band_id: m.band_id },
      }];
    }
    case "match": {
      const { data: match } = await admin.from("matches")
        .select("id, user_a, user_b, created_by").eq("id", e.id).maybeSingle();
      if (!match) return [];
      // Whoever completed the match already saw it; tell the other one.
      const to = match.created_by === match.user_a ? match.user_b : match.user_a;
      const other = await name(admin, to === match.user_a ? match.user_b : match.user_a);
      return [{
        to: [to],
        text: (l) => l === "ka"
          ? { title: "ახალი მეჩი! 🎶", body: `${other}-საც სურს ჯემი` }
          : { title: "New match! 🎶", body: `${other} wants to jam too` },
        data: { type: "chat", match_id: match.id },
      }];
    }
    case "band_proposal": {
      const { data: p } = await admin.from("band_proposals")
        .select("band_id, candidate_id, proposed_by, status, requested").eq("id", e.id).maybeSingle();
      if (!p) return [];
      const [band, candidate] = await Promise.all([bandName(admin, p.band_id), name(admin, p.candidate_id)]);
      if (p.status === "invited") {
        return [{
          to: [p.candidate_id],
          text: (l) => l === "ka"
            ? { title: band, body: `${band} გეპატიჟება ბენდში` }
            : { title: band, body: `${band} invited you to join` },
          data: { type: "bands" },
        }];
      }
      if (p.status !== "voting") return [];
      const proposer = await name(admin, p.proposed_by);
      const to = (await members(admin, p.band_id)).filter((m) => m !== p.proposed_by);
      return [{
        to,
        text: (l) => l === "ka"
          ? { title: band, body: p.requested
              ? `${candidate} ითხოვს ბენდში გაწევრიანებას. მისცი ხმა.`
              : `${proposer} გთავაზობს ${candidate}-ს. მისცი ხმა.` }
          : { title: band, body: p.requested
              ? `${candidate} asked to join. Your vote is needed.`
              : `${proposer} proposed ${candidate}. Your vote is needed.` },
        data: { type: "band", band_id: p.band_id },
      }];
    }
    case "band_join": {
      const [band, who, all] = await Promise.all([
        bandName(admin, e.band_id), name(admin, e.profile_id), members(admin, e.band_id),
      ]);
      const to = all.filter((m) => m !== e.profile_id);
      // A band's first member (its creator) has nobody to tell.
      return to.length === 0 ? [] : [{
        to,
        text: (l) => l === "ka"
          ? { title: band, body: `${who} შემოუერთდა ბენდს! 🎉` }
          : { title: band, body: `${who} joined the band! 🎉` },
        data: { type: "band", band_id: e.band_id },
      }];
    }
    case "band_removal": {
      const { data: r } = await admin.from("band_removals")
        .select("band_id, target_id, proposed_by, status").eq("id", e.id).maybeSingle();
      if (!r || r.status !== "voting") return [];
      const [band, target] = await Promise.all([bandName(admin, r.band_id), name(admin, r.target_id)]);
      const to = (await members(admin, r.band_id)).filter((m) => m !== r.proposed_by && m !== r.target_id);
      return [{
        to,
        text: (l) => l === "ka"
          ? { title: band, body: `ხმის მიცემა: ამოვიღოთ ${target} ბენდიდან?` }
          : { title: band, body: `Vote: remove ${target} from the band?` },
        data: { type: "band", band_id: r.band_id },
      }];
    }
    case "reminders":
      return await reminders(admin);
  }
  return [];
}

// ------------------------------------------------------------ time zones
// Each rehearsal keeps the time zone it was set in (rehearsals.time_zone,
// from the device; migration 20261022125407). Older rows have none: they
// were all made in Georgia.

const FALLBACK_ZONE = "Asia/Tbilisi";
const WEEK = 7 * 86_400_000;
const pad = (n: number) => String(n).padStart(2, "0");

/** A usable IANA zone name, or the fallback. */
function zoneOf(name: string | null): string {
  if (!name) return FALLBACK_ZONE;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: name });
    return name;
  } catch {
    return FALLBACK_ZONE;
  }
}

/** What a clock in [zone] shows at instant [t]. */
function wallClock(t: number, zone: string) {
  const f = new Intl.DateTimeFormat("en-US", {
    timeZone: zone, hourCycle: "h23",
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", second: "2-digit",
  });
  const o: Record<string, string> = {};
  for (const p of f.formatToParts(new Date(t))) o[p.type] = p.value;
  return { y: +o.year, m: +o.month, d: +o.day, h: +o.hour % 24, mi: +o.minute, s: +o.second };
}

/** The instant when a clock in [zone] shows that date and time (day may
 *  run past the month's end; Date.UTC rolls it over). */
function atWallClock(y: number, m: number, d: number, h: number, mi: number, zone: string): number {
  const wanted = Date.UTC(y, m - 1, d, h, mi);
  const offsetAt = (t: number) => {
    const w = wallClock(t, zone);
    return Date.UTC(w.y, w.m - 1, w.d, w.h, w.mi, w.s) - Math.floor(t / 1000) * 1000;
  };
  // Twice, so a guess on the other side of a clock change settles.
  const first = wanted - offsetAt(wanted);
  return wanted - offsetAt(first);
}

const dayIn = (t: number, zone: string) => {
  const w = wallClock(t, zone);
  return `${w.y}-${pad(w.m)}-${pad(w.d)}`;
};
const timeIn = (t: number, zone: string) => {
  const w = wallClock(t, zone);
  return `${pad(w.h)}:${pad(w.mi)}`;
};

/** Rehearsals starting in 50–60 minutes, once per date. Weekly ones repeat
 *  at the same local time in the band's zone, so they stay on time across
 *  daylight-saving changes (as the app shows them). */
async function reminders(admin: SupabaseClient): Promise<Note[]> {
  const now = Date.now();
  const from = now + 50 * 60_000;
  const until = now + 60 * 60_000;
  const { data: rows } = await admin.from("rehearsals")
    .select("id, band_id, starts_at, place, weekly, repeat_until, time_zone");
  const notes: Note[] = [];
  for (const r of rows ?? []) {
    const zone = zoneOf(r.time_zone);
    const first = Date.parse(r.starts_at);
    let start = first;
    if (r.weekly && first < from) {
      // The same weekday and local time, k weeks on; a clock change can
      // move it an hour either way, so try the neighbouring weeks too.
      const w = wallClock(first, zone);
      const k = Math.ceil((from - first) / WEEK);
      start = NaN;
      for (const weeks of [k - 1, k, k + 1]) {
        if (weeks < 0) continue;
        const t = atWallClock(w.y, w.m, w.d + 7 * weeks, w.h, w.mi, zone);
        if (t >= from && t < until) start = t;
      }
    }
    if (!(start >= from && start < until)) continue;
    const day = dayIn(start, zone); // the day the app saved answers under
    if (r.weekly && r.repeat_until && day > r.repeat_until) continue;
    const { data: cancelled } = await admin.from("rehearsal_cancellations")
      .select("rehearsal_id").eq("rehearsal_id", r.id).eq("occurs_on", day).maybeSingle();
    if (cancelled) continue;
    // Claim the date first, so two runs never both announce it.
    const { error: claimed } = await admin.from("push_reminders_sent")
      .insert({ rehearsal_id: r.id, occurs_on: day });
    if (claimed) continue;
    const { data: cant } = await admin.from("rehearsal_answers")
      .select("member_id").eq("rehearsal_id", r.id).eq("occurs_on", day).eq("going", false);
    const out = new Set((cant ?? []).map((a) => a.member_id as string));
    const to = (await members(admin, r.band_id)).filter((m) => !out.has(m));
    const band = await bandName(admin, r.band_id);
    const time = timeIn(start, zone);
    const where = r.place ? ` · ${r.place}` : "";
    notes.push({
      to,
      text: (l) => l === "ka"
        ? { title: `${band}: რეპეტიცია 1 საათში`, body: `${time}${where}` }
        : { title: `${band}: rehearsal in 1 hour`, body: `${time}${where}` },
      data: { type: "band", band_id: r.band_id },
    });
  }
  return notes;
}

// ------------------------------------------------------------ sending

async function send(admin: SupabaseClient, sa: any, notes: Note[]) {
  let sent = 0, gone = 0;
  const auth = await accessToken(sa);
  for (const n of notes) {
    if (n.to.length === 0) continue;
    const { data: tokens } = await admin.from("push_tokens")
      .select("token, platform, language").in("profile_id", n.to);
    for (const t of tokens ?? []) {
      const text = n.text(t.language === "ka" ? "ka" : "en");
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${auth}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: text,
            data: n.data,
            android: { priority: "high", notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
          },
        }),
      });
      if (res.ok) {
        sent++;
      } else {
        const body = await res.text();
        // The app was removed or the token expired: forget it.
        if (res.status === 404 || body.includes("UNREGISTERED") || body.includes("registration-token-not-registered")) {
          await admin.from("push_tokens").delete().eq("token", t.token);
          gone++;
        } else {
          console.error("FCM send failed", res.status, body);
        }
      }
    }
  }
  return { sent, gone };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST." }, 405);
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const secret = req.headers.get("x-push-secret") ?? "";
  const { data: ok } = await admin.rpc("push_hook_secret_ok", { secret });
  if (ok !== true) return json({ error: "Forbidden." }, 403);

  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) return json({ skipped: "FIREBASE_SERVICE_ACCOUNT isn't set" });

  try {
    const event = await req.json();
    const notes = await plan(admin, event);
    const result = await send(admin, JSON.parse(raw), notes);
    return json({ event: event.event, ...result });
  } catch (e) {
    console.error("push failed", e);
    return json({ error: "Couldn't send." }, 500);
  }
});
