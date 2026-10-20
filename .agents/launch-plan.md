# OCTAVA Launch Plan

**Version:** v1 · **Date:** 2026-10-20
**Reads with:** `.agents/product-marketing.md`

## Starting point
- **Product:** v1–v3 built: profiles with clips, swiping with filters, matches, chat with voice messages, bands with feed cards, rehearsals, songs, setlists, public band pages, report/block/moderation, English + Georgian. Web preview live; Android not yet in the store.
- **Audience:** a few musician friends; otherwise starting from zero. No OCTAVA social accounts yet.
- **Market:** worldwide from day one; first 100 users = hobbyists and beginners.
- **Channels chosen:** TikTok / Instagram Reels, and the local music scene (jam nights, music schools, rehearsal studios, gear shops).
- **Timeline:** no date. Move to the next phase when its exit check passes.
- **Budget:** none planned. Everything below is free except optional printing and the store fees already in the plan.

## Readiness gate (Simple, Lovable, Complete)
- **Simple:** yes — one job: find people to make music with. Swipe, hear, Jam.
- **Complete:** yes, more than complete. Sign-up → profile → clip → swipe → match → chat → band all work end to end.
- **Lovable:** unknown until strangers use it. That's what Phase 1 finds out.
- **The real risk is "Just One More Feature,"** not stealth. Three versions are built for a product with no users yet. **Feature freeze from now until public launch:** only fixes and things testers ask for repeatedly. Deep links, voice-message reports and similar wait.

## The biggest launch risk: an empty feed
A swipe app with no one nearby feels dead, and a worldwide launch spreads people thin. Everything in this plan pushes against that:
1. **Grow in clusters, not just numbers.** Every musician who joins should bring their bandmates and musician friends. Ask every tester: "Who are 3 musicians you'd want to see in here?"
2. **Bands bring people.** One band with 2 open roles in the feed gives everyone a reason to Jam. Recruit existing bands that need members early.
3. **Be honest when the feed is empty.** The app already shows an empty state; make sure it says to widen filters or invite a friend, not just "nothing here".
4. **Remove the 12 test musicians before strangers arrive** (`test_world_files.py --remove`). Fake profiles in a public feed would mislead people and break the trust this app depends on. Keep them for Phase 1 only, and tell friends they're test profiles.

## ORB: channels
| Type | Channel | Role |
|------|---------|------|
| Owned | The app itself + the landing page (`/get/`) | Where every channel points. The QR code goes here. |
| Owned | A Telegram channel or group for testers (free, owner already uses Telegram) | Updates, feedback, "what should we build next". The closest thing to an email list for now. |
| Rented | TikTok + Instagram (one account each, `@octava.app` or similar; same short videos on both) | Reach hobbyist musicians. Every bio links to `/get/`. |
| Rented | Google Play listing | Discovery once public (see the `aso` skill). |
| Borrowed | Jam-night hosts, music teachers, rehearsal studios, small music creators | Their audience, their trust. Free: offer them something (a feature, a shout-out, a jam night). |

Don't email existing users with marketing until there's a clear opt-in; their emails were collected for sign-in, and the privacy policy should match anything new.

## Phases

### Phase 1 — Friends test (now)
**Who:** 5–10 musician friends, mixed instruments; ideally 1–2 existing bands.
**How:** web preview link + Android APK (a signed release build). A Telegram group "OCTAVA testers".
**Ask each tester to:** sign up, add a clip, swipe 20 cards, Jam someone they know, chat, create or join a band, then send 3 answers:
1. What did you expect it to do that it didn't?
2. In one sentence, how would you describe OCTAVA to a musician friend? *(verbatim → marketing context)*
3. Who are 3 musicians you'd invite?
**Watch (from the database):** sign-ups, % who add a clip, % with a match in 7 days, bands created, who comes back after a week.
**Meanwhile:** create the TikTok and Instagram accounts; post 3–5 videos to learn the format (see Content below).
**Exit check:** at least 5 people finished a profile with a clip, at least one band formed among testers, and no bug blocks sign-up → match → chat.

### Phase 2 — Google Play closed test (14 days)
**Required by Google:** at least 12 testers opted in for 14 continuous days before production.
**Who:** Phase 1 testers + the people they named + 1–2 bands that need members. Aim for 20 to keep 12 active.
**Before it starts:** Play developer account ($25), signed release build, store listing (title, descriptions, screenshots, feature graphic; use `aso`), content rating and data safety forms, privacy policy link.
**Meanwhile:** post 2–3 videos a week; start the local-scene groundwork (talk to one jam-night host and one music school).
**Exit check:** 12+ testers stayed 14 days; Play approves production access; testers would be "disappointed" to lose it (ask them).

### Phase 3 — Open beta / soft launch (2–4 weeks)
**What:** Play open testing or production with no announcement; web preview stays. "Early access" framing: early members get seen first, and early bands get featured on OCTAVA's TikTok.
**Local scene push (start where the owner is, then wherever testers are):**
- A4 poster and small flyer with the QR code (`web/get/qr.png`): "Need a drummer? Swipe. Jam. Form a band." In jam-night bars, rehearsal studios, music schools, gear shops.
- Host or co-host one **OCTAVA jam night**: everyone signs up at the door, adds a clip on the spot, swipes on the people in the room. Film it for TikTok.
- Ask 2–3 music teachers to tell students about it (beginners are the primary audience).
**Remove the test musicians before this phase starts.**
**Exit check:** steady sign-ups without personal invites; most new people add a clip; matches happen between strangers.

### Phase 4 — Public launch
**When:** after Phase 3 shows strangers finding each other. Upgrade Supabase to Pro first (Free pauses inactive projects).
**Launch week:**
- [ ] Play listing final (screenshots from real bands, with permission)
- [ ] `/get/` store button switched on (`STORES.android` in `web/get/index.html`)
- [ ] Launch video series: 5 videos over the week (one per feature: hear before you swipe, mutual Jam, band cards, band tools, safety)
- [ ] Testers asked to leave an honest Play review and invite 3 friends
- [ ] Posters refreshed with "Now on Google Play"
- [ ] Tell every partner (jam-night host, teachers, studios) and ask them to share
- [ ] Watch crash reports (Crashlytics) and reports (Telegram bot) daily
**Not worth it now:** Product Hunt (tech audience, few hobbyist musicians). Revisit for the iOS launch or OCTAVA Plus.

### Phase 5 — Keep launching
Every visible improvement is a small launch: a TikTok + a Telegram post + "What's new" in the Play listing. Big ones (iOS app, OCTAVA Plus, deep links) get a full week like Phase 4.

## Content: first TikTok / Reels ideas
Short, vertical, real musicians, real sound. No stock footage, no AI people.
1. **"Hear before you swipe"** — screen recording: swipe through cards, each clip plays. Caption: "Tinder, but you hear them play first."
2. **"Our drummer quit"** — a band acts out the problem, then finds a drummer through a band card.
3. **"Match to first jam"** — follow two strangers from a match to their first rehearsal.
4. **"Rate my 30-second clip"** — musicians record their profile clip; comments vote.
5. **"Beginner-friendly"** — someone who's played guitar for 6 months finds people at their level.
6. **Jam-night recap** — 20 people, one room, everyone swiping, first band formed that night.
7. **"Band tools in 15 seconds"** — the rehearsal calendar with Going/Can't, the setlist length adding up.
8. **Duet/stitch bait** — "Need a bassist for this riff. Duet it." → link in bio.
Post the same video on TikTok and Reels. Every caption ends with one action: "Link in bio to join."

## Metrics per phase
| Metric | Why |
|--------|-----|
| Sign-ups per week | Reach |
| % of sign-ups who add a clip | Without one they're hidden; the key activation step |
| % with a match within 7 days | Does the feed have enough people? |
| Bands created / joined | The real outcome |
| Back after 7 days | Lovable? |
| Where they heard of OCTAVA (ask in the tester group, later in onboarding) | Which channel works |
These come from simple database counts; no analytics tool needed yet.

## Next steps
1. Build the signed release APK for Phase 1.
2. Write the tester invite message and the 3 feedback questions as a ready-to-send text (`copywriting`).
3. Create the TikTok and Instagram accounts (owner).
4. Check the empty-feed message in the app (invite a friend / widen filters).
5. Before Phase 3: remove the test musicians; design the poster.

## Changelog
- v1 (2026-10-20) — First plan: friends test → Play closed test → soft launch with the local scene → public launch; TikTok/Reels and local scene as the chosen channels; no date.
