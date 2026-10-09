# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product

OCTAVA is a Tinder-style app for forming bands. Musicians swipe on each other, and bands post open roles that musicians swipe on. The owner is building it alone.

Decisions the owner has made (build to these; don't ask about them again):
- **Audience:** all kinds of musicians: beginners and hobbyists, working musicians, existing bands looking for members, and session or one-off players.
- **Platforms:** iOS and Android, mobile first. No public web app is planned. The `web/` platform exists only as a development preview (see Commands).
- **Reach:** worldwide from launch. The UI is in English and Georgian.
- **Ages:** 16+. People aged 16–17 can join bands with adults but cannot have one-on-one private chats with adults. Enforce this on the server, not only in the UI.
- **Matching:** a match happens when two people both swipe right. A new member joins a band when a majority of its current members vote yes.
- **Profiles:** instruments (several, each with a skill level), genres and influences, gear and logistics (own kit, car, rehearsal space, home studio), availability and goals (fun, gigging, recording, paid). Samples are uploaded audio clips plus links to YouTube, TikTok and other social media. Video upload is not planned.
- **Swipe filters:** distance, instrument or role, genre and skill level, goals and availability.
- **Chat:** one-on-one text, band group chat, voice messages and audio.
- **Band tools:** public band page, rehearsal calendar, songs and setlists.
- **Money:** free for now; no payments, subscriptions or ads.

## Release plan

Keep version 1 small, because one person is building it.
1. **Version 1:** sign-up with date of birth (16+), profiles with audio clips and links, swiping with the filters above, matching on mutual likes, one-on-one chat with the teen restriction, report and block, English and Georgian.
2. **Version 2:** bands as their own profiles with open roles, majority-vote joining, band group chat, voice messages.
3. **Version 3:** public band page, rehearsal calendar, songs and setlists.

Stack (chosen by the owner): **Flutter** (Dart) for the iOS and Android app, and **Supabase** for logins, the Postgres database, audio storage and real-time chat. The owner knows JavaScript/TypeScript but is new to Dart, so briefly explain Dart-specific patterns when introducing them.

## Commands

Flutter is installed at `C:\src\flutter` (stable channel) and is on the user PATH. A shell started before PATH was updated needs the full path, `/c/src/flutter/bin/flutter`. An older Flutter (3.41, Dart 3.11) also exists at `C:\Users\lchemia\Documents\flutter` and can't build this project, which needs Dart ^3.13.5. If `flutter --version` shows 3.41, check VS Code's `dart.flutterSdkPath` setting, which should be `C:\src\flutter`; the Dart extension puts that SDK first on its terminals' PATH.

```
flutter pub get                       # install dependencies
flutter analyze                       # lint (rules in analysis_options.yaml)
flutter test                          # all tests
flutter test test/widget_test.dart    # one test file
flutter test --plain-name "home shows" # one test by name
flutter run -d chrome                 # main way to preview the app during development
flutter run                           # run on a connected Android device
flutter build apk --debug             # Android debug build
```

iOS can't be built on this Windows machine; it needs a Mac or a macOS CI runner. The Android emulator crashes on this PC (segfault at startup with the Android 37 image; the owner can't update the Intel graphics driver), so preview in Chrome and check Android with `flutter build apk --debug`. Because the app is previewed on the web but ships on mobile, choose packages that support web and mobile (for example for audio recording and playback), or isolate mobile-only code behind a check.

## Code layout

The Supabase database is built and tested, and the app initialises the Supabase client, but no screen uses it yet. The swipe screen still uses sample data, and all state lives in it (`setState`). No state-management package has been chosen yet.
- `lib/main.dart`: initialises Supabase, then runs `OctavaApp` (MaterialApp with light and dark themes), which opens on `SwipeScreen`.
- `lib/config/supabase_config.dart`: project URL and publishable key. These are public by design; never add the secret/service_role key or the DB password.
- `lib/screens/swipe_screen.dart`: holds the band lineup (`Map<String, String?>` of role → member), the card queue, and the drag offset, which one `AnimationController` animates for fly-off and snap-back. It also contains the match dialog, the empty state, and arrow-key shortcuts. A Jam on someone with `likesYou` is a match and fills their instrument's slot if it's open.
- `lib/widgets/musician_card.dart`: the card. `HalftonePainter` draws the riso portrait (dots grow away from a per-musician spotlight); the instrument name overlaps the portrait with a multiply blend in light mode. The audio clip's play button is disabled until real clips exist.
- `lib/widgets/band_lineup.dart`: the "Your band" slots, which flash pink when filled.
- `lib/models/musician.dart` and `lib/data/sample_musicians.dart`: the `Musician` model (spotlight and waveform come from a stable name-based seed) and the 8 sample people from the prototype.
- Tests (`test/widget_test.dart`) find the action buttons with `find.widgetWithText(OutlinedButton, 'Pass')` and `find.widgetWithText(FilledButton, 'Jam')`, because the drag stamps also contain the text "Pass" and "Jam". Tests render text in the wide Ahem font, so rows with two texts need `Expanded` with an ellipsis or they overflow.
- `lib/theme.dart`: `OctavaColors` (the design palette), `octavaTheme(brightness)`, and `displayStyle()` for Big Shoulders headings. Take colours from the theme's `ColorScheme`, not hardcoded hex values.
- `assets/fonts/`: static TTFs for Instrument Sans (400/600/700) and Big Shoulders Display (900), bundled through `pubspec.yaml`. Don't use the `google_fonts` package: its current release depends on `package:material_ui`, which clashes with this Flutter SDK's `TextTheme`. Neither font has Georgian glyphs, so Georgian text falls back to the system font.
- `prototype/index.html`: the clickable HTML prototype of the swipe screen (open it in a browser). It's the design reference for the Flutter UI: riso-print look, swipe actions named "Pass" and "Jam", band-lineup slots, and halftone portrait tones in pink, yellow and aqua.

App IDs: the store-facing ID is `com.octava.app` (Android `applicationId`, iOS `PRODUCT_BUNDLE_IDENTIFIER`). The Android Kotlin `namespace` stays `com.octava.octava`; it's internal only.

## Backend (Supabase)

Project ref `nbvcbhnaevkrnpbjhbbj` (Frankfurt). Claude Code reaches it through the Supabase MCP server in `.mcp.json`; the owner authenticates with `/mcp`. The schema lives in `supabase/migrations/`, with file names matching the versions applied remotely. Add changes as new migration files (apply with the MCP `apply_migration` tool, then save the same SQL locally under the version it gets). Don't edit applied migrations.

How v1 fits together:
- **Sign-up order:** auth user → `profile_private` (birth date; a trigger rejects anyone under 16; no update policy, so it can't be changed from the app) → `profiles` (its id references `profile_private`, so there's no profile without a birth date) → `profile_instruments`, `profile_links`, `audio_clips` (files in the private `clips` storage bucket at `<user id>/<file>`, played via signed URLs).
- **Age groups:** 16–17 year olds and adults never see each other in v1. RLS on profiles, details and clip files uses `private.same_age_group()`. `get_deck` and `record_swipe` apply it too, and `private.can_message()` re-checks it on every message, so a teen pair stops chatting if one turns 18. Bands (v2) are where teens and adults will meet.
- **Location:** `profiles.lat/lng` are rounded to 2 decimals (~1 km) by trigger and can't be read or written by clients (column grants). Set them with `set_my_location()`; distances come back from `get_deck` as whole km.
- **Public API (RPC):** only `get_deck(max_km, instrument_ids, min_skill, genre_filter, goal_filter, frequency_filter, max_results)`, `record_swipe(target, decision)` (returns the match id on a mutual Jam, else null), and `set_my_location(lat, lng)`. Helpers live in the unexposed `private` schema; signed-in users can execute only the ones RLS policies call.
- **Tables clients write directly:** profile tables (own rows), `messages` (insert in own match, if `can_message`), `blocks` (own), `reports` (insert only; read them in the dashboard). Swipes and matches are written only by `record_swipe`; either person can delete (unmatch) a match.
- **Realtime:** `matches` and `messages` are in the `supabase_realtime` publication (RLS applies).
- **Rule tests:** `supabase/tests/rules_check.sql` acts as fake users in one block and always ends with an exception, so it rolls itself back. All checks should read PASS. Re-run it after any schema or policy change, and also run the Supabase security and performance advisors.

## Keeping this file current

Keep "Backend" in step with new migrations. Update "Product" and "Release plan" when the owner changes a decision.

## Environment

Development happens on Windows. Both PowerShell and Git Bash are available.
