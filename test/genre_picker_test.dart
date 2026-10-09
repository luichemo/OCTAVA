import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/profile_options.dart';
import 'package:octava/main.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/widgets/genre_picker.dart';

import 'profile_edit_test.dart' show FakeClipRepository, FakeClipPlayer;
import 'signup_flow_test.dart' show FakeProfileRepository;

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  /// A picker on its own page; `picked` always holds the latest selection.
  Widget picker(List<String> picked, {int? max}) => Scaffold(
    body: StatefulBuilder(
      builder: (context, setState) => GenrePicker(
        selected: picked,
        max: max,
        onChanged: (next) => setState(() {
          picked
            ..clear()
            ..addAll(next);
        }),
      ),
    ),
  );

  group('genre list', () {
    test('every genre has a label', () {
      expect(genreLabels.length, 42);
      expect(genreLabel('post-punk'), 'Post-punk');
    });

    testWidgets('search, tick and confirm', (tester) async {
      final picked = <String>[];
      await pump(tester, picker(picked));

      await tester.tap(find.text('Choose genres'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'punk');
      await tester.pump();
      expect(find.widgetWithText(CheckboxListTile, 'Jazz'), findsNothing);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Post-punk'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(picked, ['post-punk']);
      expect(find.widgetWithText(InputChip, 'Post-punk'), findsOneWidget);
      expect(find.text('Change genres'), findsOneWidget);
    });

    testWidgets('nothing matching the search says so', (tester) async {
      await pump(tester, picker([]));
      await tester.tap(find.text('Choose genres'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('at the limit, other genres are greyed out', (tester) async {
      final picked = ['jazz', 'funk'];
      await pump(tester, picker(picked, max: 2));

      await tester.tap(find.text('Change genres'));
      await tester.pumpAndSettle();
      expect(find.text('You can pick up to 10 genres.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'post');
      await tester.pump();
      final tile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Post-punk'),
      );
      expect(tile.enabled, isFalse);
    });

    testWidgets('deleting a chip removes the genre', (tester) async {
      final picked = ['jazz', 'funk'];
      await pump(tester, picker(picked));
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(InputChip, 'Jazz'),
          matching: find.byTooltip('Delete'),
        ),
      );
      await tester.pump();
      expect(picked, ['funk']);
    });
  });

  group('no-clips warning', () {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );

    testWidgets('shown while you have no clips', (tester) async {
      await pump(
        tester,
        EditProfileScreen(
          repository: repo,
          clips: FakeClipRepository(),
          player: FakeClipPlayer(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("You're hidden from the feed"), findsOneWidget);
    });

    testWidgets('gone once you have a clip', (tester) async {
      final clips = FakeClipRepository();
      await clips.upload(bytes: Uint8List(1), fileName: 'Song.mp3');
      await pump(
        tester,
        EditProfileScreen(
          repository: repo,
          clips: clips,
          player: FakeClipPlayer(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("You're hidden from the feed"), findsNothing);
    });
  });
}
