import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/clip_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/models/profile_link.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/screens/swipe_screen.dart';
import 'package:octava/data/deck.dart';
import 'package:octava/widgets/clips_section.dart';

import 'signup_flow_test.dart' show FakeProfileRepository;

class FakeClipRepository implements ClipRepository {
  final list = <MyClip>[];
  String? rejectWith;

  @override
  Future<List<MyClip>> myClips() async => List.of(list);

  @override
  Future<MyClip> upload({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (rejectWith != null) throw UserFacingException(rejectWith!);
    final clip = MyClip(
      id: 'c${list.length}',
      path: 'me/${list.length}.mp3',
      title: fileName,
      seconds: 42,
    );
    list.add(clip);
    return clip;
  }

  @override
  Future<void> delete(MyClip clip) async =>
      list.removeWhere((c) => c.id == clip.id);

  @override
  Future<String> playbackUrl(String path) async =>
      'https://example.invalid/$path';
}

class FakeClipPlayer implements ClipPlayer {
  final toggled = <String>[];

  @override
  final ValueNotifier<String?> playing = ValueNotifier(null);

  @override
  Stream<Duration> get position => const Stream.empty();

  @override
  Future<void> toggle(String path) async {
    toggled.add(path);
    playing.value = playing.value == path ? null : path;
  }

  @override
  Future<void> stop() async => playing.value = null;

  @override
  Future<void> dispose() async {}
}

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  group('links', () {
    test('pasted links get https and the right site', () {
      expect(
        ProfileLink.fromInput('youtu.be/abc'),
        const ProfileLink(kind: 'youtube', url: 'https://youtu.be/abc'),
      );
      expect(
        ProfileLink.fromInput('http://www.tiktok.com/@nika')?.url,
        'https://www.tiktok.com/@nika',
      );
      expect(
        ProfileLink.fromInput('https://nika.bandcamp.com')?.kind,
        'bandcamp',
      );
      expect(
        ProfileLink.fromInput('https://open.spotify.com/artist/1')?.kind,
        'spotify',
      );
      expect(ProfileLink.fromInput('mysite.ge')?.kind, 'other');
      expect(ProfileLink.fromInput('not a link'), isNull);
      expect(ProfileLink.fromInput('localhost'), isNull);
    });

    test('database rows become an editable draft, main instrument first', () {
      final draft = ProfileDraft.fromRows(
        profile: {
          'display_name': 'Luka',
          'area': null,
          'looking_for': 'A band',
          'genres': ['grunge'],
          'goals': ['gigging'],
          'rehearsal_frequency': 'weekly',
          'has_own_gear': true,
          'has_car': false,
          'has_rehearsal_space': false,
          'has_home_studio': true,
        },
        instruments: [
          {'instrument_id': 'guitar', 'skill': 'beginner', 'is_primary': false},
          {'instrument_id': 'vocals', 'skill': 'pro', 'is_primary': true},
        ],
        links: [
          {'kind': 'youtube', 'url': 'https://youtu.be/x'},
        ],
      );
      expect(draft.instruments.keys.first, 'vocals');
      expect(draft.area, '');
      expect(draft.gear, {'has_own_gear', 'has_home_studio'});
      expect(draft.toLinkRows('me'), [
        {'profile_id': 'me', 'kind': 'youtube', 'url': 'https://youtu.be/x'},
      ]);
    });
  });

  testWidgets('editing a profile saves changes and links', (tester) async {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
    await pump(tester, EditProfileScreen(repository: repo));

    expect(find.text('Your profile'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Date of birth'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Luka G',
    );
    final scroll = find.byType(Scrollable).first;
    final linkField = find.widgetWithText(
      TextField,
      'YouTube, TikTok, SoundCloud, Spotify…',
    );
    await tester.scrollUntilVisible(linkField, 200, scrollable: scroll);
    await tester.enterText(linkField, 'soundcloud.com/lukag');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('SoundCloud'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Save changes'),
      200,
      scrollable: scroll,
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repo.saved?.displayName, 'Luka G');
    expect(repo.saved?.links, [
      const ProfileLink(
        kind: 'soundcloud',
        url: 'https://soundcloud.com/lukag',
      ),
    ]);
  });

  testWidgets('a link left in the box is saved too', (tester) async {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
    await pump(tester, EditProfileScreen(repository: repo));

    final scroll = find.byType(Scrollable).first;
    final linkField = find.widgetWithText(
      TextField,
      'YouTube, TikTok, SoundCloud, Spotify…',
    );
    await tester.scrollUntilVisible(linkField, 200, scrollable: scroll);
    await tester.enterText(
      linkField,
      'youtube.com/watch?v=abc',
    ); // no Enter, no +
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repo.saved?.links, [
      const ProfileLink(
        kind: 'youtube',
        url: 'https://youtube.com/watch?v=abc',
      ),
    ]);
  });

  testWidgets('an unusable link stops the save and says why', (tester) async {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
    await pump(tester, EditProfileScreen(repository: repo));

    final scroll = find.byType(Scrollable).first;
    final linkField = find.widgetWithText(
      TextField,
      'YouTube, TikTok, SoundCloud, Spotify…',
    );
    await tester.scrollUntilVisible(linkField, 200, scrollable: scroll);
    await tester.enterText(linkField, 'my channel');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repo.saved?.links, isEmpty);
    expect(find.textContaining('Check the link'), findsOneWidget);
  });

  testWidgets('"See your card" shows your own card', (tester) async {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
        links: [ProfileLink(kind: 'youtube', url: 'https://youtu.be/x')],
      );
    await pump(tester, EditProfileScreen(repository: repo));

    await tester.tap(find.text('See your card'));
    await tester.pumpAndSettle();

    expect(find.text('Your card'), findsOneWidget);
    expect(find.text('Luka, 30'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
  });

  group('audio clips', () {
    Widget section(FakeClipRepository clips, FakeClipPlayer player) => Scaffold(
      body: ClipsSection(
        clips: clips,
        player: player,
        pickFile: () async => ('Demo song.mp3', Uint8List(10)),
      ),
    );

    testWidgets('upload, play and delete a clip', (tester) async {
      final clips = FakeClipRepository();
      final player = FakeClipPlayer();
      await pump(tester, section(clips, player));

      await tester.tap(find.text('Add a clip'));
      await tester.pumpAndSettle();
      expect(find.text('Demo song.mp3'), findsOneWidget);
      expect(find.text('0:42'), findsOneWidget);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(player.toggled, ['me/0.mp3']);
      expect(find.byTooltip('Stop'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete clip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(clips.list, isEmpty);
      expect(player.playing.value, isNull);
    });

    testWidgets('explains a rejected upload', (tester) async {
      final clips = FakeClipRepository()
        ..rejectWith = 'Clips can be up to 2 minutes. This one is 3:10.';
      await pump(tester, section(clips, FakeClipPlayer()));

      await tester.tap(find.text('Add a clip'));
      await tester.pumpAndSettle();
      expect(
        find.text('Clips can be up to 2 minutes. This one is 3:10.'),
        findsOneWidget,
      );
    });

    testWidgets('cards play a real clip', (tester) async {
      final player = FakeClipPlayer();
      await pump(
        tester,
        SwipeScreen(source: const _ClipDeck(), player: player),
      );

      await tester.tap(find.byTooltip("Play Ana's clip"));
      await tester.pump();
      expect(player.toggled, ['ana/1.mp3']);
      expect(find.byTooltip("Stop Ana's clip"), findsOneWidget);

      // Swiping stops it.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Pass'));
      await tester.pumpAndSettle();
      expect(player.playing.value, isNull);
    });
  });
}

class _ClipDeck extends SampleDeck {
  const _ClipDeck();

  @override
  Future<List<Musician>> loadDeck() async => const [
    Musician(
      id: 'ana',
      name: 'Ana',
      age: 25,
      instrument: 'Vocals',
      clipSeconds: 30,
      clipPath: 'ana/1.mp3',
    ),
  ];
}
