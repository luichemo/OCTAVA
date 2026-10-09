import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'swipe_helpers.dart';

import 'package:octava/data/band_repository.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

import 'signup_flow_test.dart' show FakeProfileRepository;

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  group('lineup', () {
    test('until chosen: the usual five minus your own instrument', () {
      final band = buildLineup(myRole: 'bass', needs: null);
      expect(band.map((s) => s.role), [
        'bass',
        'vocals',
        'guitar',
        'drums',
        'keys',
      ]);
      expect(band.first.member, youMarker);
    });

    test('counts repeat a role; matches fill the first open one', () {
      final band = buildLineup(
        myRole: 'guitar',
        needs: {'guitar': 1, 'drums': 2},
        members: [
          (name: 'Nika', role: 'drums'),
          (name: 'Giorgi', role: 'drums'),
          (name: 'Dato', role: 'drums'), // no room left
          (name: 'Ana', role: 'vocals'), // not needed
        ],
      );
      expect(band, [
        (role: 'guitar', member: youMarker),
        (role: 'guitar', member: null),
        (role: 'drums', member: 'Nika'),
        (role: 'drums', member: 'Giorgi'),
      ]);
    });
  });

  group('choosing roles', () {
    testWidgets('tap the band row, set counts and save', (tester) async {
      final needs = MemoryBandNeeds();
      await pump(tester, SwipeScreen(bandNeeds: needs));
      expect(find.text('Open'), findsNWidgets(4));

      await tester.tap(find.text('Your band'));
      await tester.pumpAndSettle();
      expect(find.text('Who does your band need?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('more-drums')));
      await tester.tap(find.byKey(const ValueKey('fewer-keys')));
      await tester.pump();
      expect(find.text('4 of 8'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(needs.needs, {'vocals': 1, 'bass': 1, 'drums': 2});
      expect(find.text('Open'), findsNWidgets(4)); // vocals, bass, 2× drums
      expect(find.text('Keys'), findsNothing);
    });

    testWidgets('at least one role, and no more than 8 in total', (
      tester,
    ) async {
      await pump(tester, SwipeScreen(bandNeeds: MemoryBandNeeds({'bass': 1})));
      await tester.tap(find.text('Your band'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fewer-bass')));
      await tester.pump();
      expect(find.text('Pick at least one role.'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Save');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      for (final role in ['vocals', 'guitar']) {
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.byKey(ValueKey('more-$role')));
        }
      }
      await tester.pump();
      expect(find.text('8 of 8'), findsOneWidget);
      final more = tester.widget<IconButton>(
        find.byKey(const ValueKey('more-bass')),
      );
      expect(more.onPressed, isNull);

      // Nine slots (you + 8) scroll sideways instead of overflowing.
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a second drummer fills the second drums slot', (
      tester,
    ) async {
      await pump(
        tester,
        SwipeScreen(bandNeeds: MemoryBandNeeds({'drums': 2})),
      );
      expect(find.text('Open'), findsNWidgets(2));

      await swipeJam(tester); // Nika, a drummer who likes you
      await tester.pumpAndSettle();
      expect(find.textContaining('Drums is now filled'), findsOneWidget);
      await tester.tap(find.text('Say hi'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets("a match your band doesn't need says so", (tester) async {
      await pump(tester, SwipeScreen(bandNeeds: MemoryBandNeeds({'bass': 1})));
      await swipeJam(tester); // Nika plays drums
      await tester.pumpAndSettle();
      expect(
        find.textContaining("isn't looking for drums right now"),
        findsOneWidget,
      );
    });
  });

  testWidgets('the profile shows and changes the roles', (tester) async {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
    final needs = MemoryBandNeeds();
    await pump(tester, EditProfileScreen(repository: repo, bandNeeds: needs));

    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Change roles'),
      200,
      scrollable: scroll,
    );
    expect(
      find.text('Not chosen yet, so these are the usual roles.'),
      findsOneWidget,
    );
    // The usual roles minus Luka's vocals.
    expect(find.widgetWithText(Chip, 'Guitar'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Vocals'), findsNothing);

    await tester.tap(find.text('Change roles'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('more-guitar')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(needs.needs?['guitar'], 2);
    await tester.scrollUntilVisible(
      find.text('Change roles'),
      -200,
      scrollable: scroll,
    );
    expect(find.widgetWithText(Chip, 'Guitar ×2'), findsOneWidget);
    expect(
      find.text('Not chosen yet, so these are the usual roles.'),
      findsNothing,
    );
  });
}
