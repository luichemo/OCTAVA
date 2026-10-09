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

After adding a package with platform code (file_picker, just_audio, url_launcher, ...), quit and re-run `flutter run`. Hot restart (`R`) doesn't register new plugins, and the web build then fails with `UnimplementedError: ... has not been implemented`.

iOS can't be built on this Windows machine; it needs a Mac or a macOS CI runner. The Android emulator crashes on this PC (segfault at startup with the Android 37 image; the owner can't update the Intel graphics driver), so preview in Chrome and check Android with `flutter build apk --debug`. Because the app is previewed on the web but ships on mobile, choose packages that support web and mobile (for example for audio recording and playback), or isolate mobile-only code behind a check.

## Code layout

Sign-up, profile setup and swiping use Supabase. Screen state lives in each screen (`setState`). No state-management package has been chosen yet.
- `lib/main.dart`: initialises Supabase, then runs `OctavaApp` (MaterialApp with light and dark themes). `OctavaApp(home:)` defaults to `AuthGate`; tests pass their own home so they don't need Supabase.
- `lib/config/supabase_config.dart`: project URL and publishable key. These are public by design; never add the secret/service_role key or the DB password.
- `lib/screens/auth_gate.dart`: `AuthGate` listens to Supabase auth. Signed out → `AuthScreen`; signed in → `ProfileGate`, which asks the repository for a `ProfileStatus` (needsBirthDate / needsProfile / ready) and shows `OnboardingScreen` or `SwipeScreen`.
- `lib/screens/matches_screen.dart` and `lib/screens/chat_screen.dart`: opened from the swipe screen's Matches button, or from "Say hi" after a match (`SwipeScreen.onOpenChat`; `DeckSource.swipe` returns the match id). `lib/data/chat_repository.dart` loads matches with each person's main instrument and latest message, streams a match's messages live (`.stream()` = Supabase Realtime, RLS applies), and maps RLS refusals (42501: blocked or age rule) to a message. `ProfileGate(chat:)` is optional; without it there's no Matches button.
- Block and report: `lib/widgets/safety_sheet.dart` (`showSafetyOptions`: a bottom sheet with Block, which needs a confirm, or Report, which takes a reason, optional details and "Also block", on by default) over `lib/data/safety_repository.dart` (inserts into `blocks` / `reports`; `reportReasonLabels` keys match the `report_reason` enum). Opened from the chat's ⋮ button and each top card's flag button. Blocked people are dropped from the deck (by `get_deck`), from Matches and from the band lineup (the app filters out your `blocks`). Reports are read in the Supabase dashboard.
- Profile editing: the swipe screen's person button opens `EditProfileScreen`, which loads `ProfileRepository.loadMyProfile()` into `OnboardingScreen` in edit mode (`initial:`; no birth date; adds Links and Audio clips; "Save changes" calls `updateProfile`, which updates `profiles` and replaces `profile_instruments` and `profile_links`). Links: `lib/models/profile_link.dart` (`ProfileLink.fromInput` adds https:// and detects the site). They're shown as chips on cards and opened with url_launcher.
- Audio clips: `lib/data/clip_repository.dart`. `SupabaseClipRepository.upload` checks type (`clipMimeTypes`), size (10 MB) and count (5), uploads to the `clips` bucket at `<uid>/<millis>.<ext>`, measures the length with just_audio from a signed URL (deleting the file if it's unreadable or over 120 s), then inserts `audio_clips`. `ClipPlayer` (interface; `JustAudioClipPlayer` for real) plays one clip at a time: one per signed-in session, owned by `ProfileGate` and passed to cards and `ClipsSection` (`lib/widgets/clips_section.dart`; files picked with file_picker 13's static `FilePicker.pickFile`). Cards play their first clip (`Musician.clipPath`); sample musicians have no path, so their play button is disabled.
- AI avatars: a **Generate my avatar** button in the profile's Avatar section (`lib/widgets/avatar_section.dart`) calls the `generate-avatar` Edge Function through `lib/data/avatar_repository.dart`. Cards and the card preview show the avatar (`Musician.avatarPath`, via `AvatarImage` and signed URLs) over the halftone pattern.
- Swipe screen layout: the header has the wordmark plus the filter summary, which is also the Filters button ("Within 25 km, 2 filters"). Below come the band lineup, a "Share location" prompt (until you share one), the card deck and a swipe hint. Profile, Matches and Sign out sit in a bottom bar (`_BottomBar`). Choosing is swipe-only, plus the arrow keys and screen-reader custom actions "Jam"/"Pass" on the top card.
- Filters and location: `lib/models/deck_filters.dart` (`DeckFilters` maps onto get_deck's parameters; distance applies only once you've shared a location; min skill only with instruments). `lib/screens/filters_screen.dart` pops the new filters, which are saved per account on the device by `PrefsFilterStore` (shared_preferences; `MemoryFilterStore` in tests). `lib/data/location_repository.dart` uses geolocator (low accuracy) and then `set_my_location`, with `has_my_location()` for status. The profile has a Location section (`lib/widgets/location_section.dart`) to share, update or stop sharing. Android declares ACCESS_COARSE_LOCATION; iOS has NSLocationWhenInUseUsageDescription.
- `lib/screens/auth_screen.dart` (email + password sign-up/sign-in) and `lib/screens/onboarding_screen.dart` (birth date with a "can't change it later" confirmation, then the profile form).
- `lib/data/repositories.dart`: `AuthRepository` / `ProfileRepository` interfaces with Supabase implementations. Errors become `UserFacingException` with wording for people; messages raised by our own DB rules (codes P0001/23514, not "new row…" constraint text) pass through. Screens take repositories as parameters; `test/signup_flow_test.dart` has fakes.
- `lib/data/profile_options.dart`: labels for DB enum values and instrument ids (keys must match the DB). `lib/models/profile_draft.dart` builds the `profiles` and `profile_instruments` rows.
- Dart gotcha that caused a real bug: `setState(() => _x = someFuture())` returns the Future, so `setState` throws and nothing redraws. Use a block body: `setState(() { _x = someFuture(); })`.
- `lib/screens/swipe_screen.dart`: takes a `DeckSource` (`lib/data/deck.dart`) and loads the band lineup (`Map<String, String?>` of role → member) and the card queue from it. The drag offset is animated by one `AnimationController` for fly-off and snap-back. Each swipe is saved while the card flies away; if saving fails, the card comes back with a message. It also contains the match dialog, the empty/error states, and arrow-key shortcuts.
- `lib/data/deck.dart`: `SupabaseDeck` (`get_deck` with no distance limit until location exists; `record_swipe`, where a non-null match id means a match). The lineup is the five usual roles plus your own main instrument as "You", filled from your matches' main instruments. `SampleDeck` holds the 8 sample people (their `likesYou` decides matches) and is the default in tests.
- `lib/widgets/musician_card.dart`: the card. `HalftonePainter` draws the riso portrait (dots grow away from a per-musician spotlight); the instrument name overlaps the portrait with a multiply blend in light mode. The audio clip's play button is disabled until real clips exist.
- `lib/widgets/band_lineup.dart`: the "Your band" slots, which flash pink when filled.
- `lib/models/musician.dart` and `lib/data/sample_musicians.dart`: the `Musician` model (spotlight and waveform come from a stable name-based seed) and the 8 sample people from the prototype.
- Tests: choosing is by swiping only (no Pass or Jam buttons), so tests call `swipeJam` / `swipePass` from `test/swipe_helpers.dart`, which drag the top card. The drag stamps contain the text "Pass" and "Jam" on both visible cards, so don't find those by text. Tests render text in the wide Ahem font, so rows with two texts need `Expanded` with an ellipsis or they overflow. Each feature has its own test file with fake repositories.
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
- **Avatars:** the `supabase/functions/generate-avatar` Edge Function (Deno, deployed with verify_jwt) checks the caller, allows 5 per person per rolling 24 hours (`avatar_generations`, which clients can't access), and builds a riso-poster prompt from the main instrument and sanitised genres. The prompt always asks for a faceless, stylised figure, so it's never a fake photo of a person. It calls Cloudflare Workers AI `@cf/black-forest-labs/flux-1-schnell` (body is only `prompt` and `steps` 4: the model rejects any other field, even `seed`; response `result.image` is a base64 JPEG), uploads to the private `avatars` bucket at `<uid>/<millis>.jpg` with the service role, sets `profiles.avatar_path` (clients can read but not write it) and deletes the previous file. It needs the Edge Function secrets `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN`; without them it answers 503 "isn't set up yet". Cost: about 58 neurons per 1024×1024 image, so the free 10,000 neurons/day cover about 170 avatars. Avatar files are readable by the same age group (policy like clips); `get_deck` returns `avatar_path`. Redeploy after editing the function (MCP `deploy_edge_function`).
- **Test data:** `supabase/seed/test_musicians.sql` adds the 8 sample musicians as adult profiles that can't sign in (emails `@test.octava.invalid`, fixed ids ending `a1`–`a8`). Nika, Luka, Tamar and Dato have already chosen Jam on every real adult profile that existed when the script ran. `supabase/seed/remove_test_musicians.sql` deletes them and everything linked to them. They are currently in the database.
- **Rule tests:** `supabase/tests/rules_check.sql` acts as fake users in one block and always ends with an exception, so it rolls itself back. All checks should read PASS. Re-run it after any schema or policy change, and also run the Supabase security and performance advisors.

## Keeping this file current

Keep "Backend" in step with new migrations. Update "Product" and "Release plan" when the owner changes a decision.

## Environment

Development happens on Windows. Both PowerShell and Git Bash are available.
