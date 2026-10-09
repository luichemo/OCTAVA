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

Flutter is installed at `C:\src\flutter` (stable channel) and is on the user PATH. A shell started before PATH was updated needs the full path, `/c/src/flutter/bin/flutter`.

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

The Flutter project was just created. Supabase is not wired in yet, and there is no data model.
- `lib/main.dart`: `OctavaApp` (MaterialApp with light and dark themes) and a placeholder `HomeScreen` showing the "Your band" lineup.
- `lib/theme.dart`: `OctavaColors` (the design palette), `octavaTheme(brightness)`, and `displayStyle()` for Big Shoulders headings. Take colours from the theme's `ColorScheme`, not hardcoded hex values.
- `assets/fonts/`: static TTFs for Instrument Sans (400/600/700) and Big Shoulders Display (900), bundled through `pubspec.yaml`. Don't use the `google_fonts` package: its current release depends on `package:material_ui`, which clashes with this Flutter SDK's `TextTheme`. Neither font has Georgian glyphs, so Georgian text falls back to the system font.
- `prototype/index.html`: the clickable HTML prototype of the swipe screen (open it in a browser). It's the design reference for the Flutter UI: riso-print look, swipe actions named "Pass" and "Jam", band-lineup slots, and halftone portrait tones in pink, yellow and aqua.

App IDs: the store-facing ID is `com.octava.app` (Android `applicationId`, iOS `PRODUCT_BUNDLE_IDENTIFIER`). The Android Kotlin `namespace` stays `com.octava.octava`; it's internal only.

## Keeping this file current

When Supabase and real features land, document the architecture here: how auth, profiles, swipes and matches, chat and audio storage fit together, plus where the age and teen-chat rules are enforced (database policies, not only the app). Update "Product" and "Release plan" when the owner changes a decision.

## Environment

Development happens on Windows. Both PowerShell and Git Bash are available.
