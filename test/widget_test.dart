import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'swipe_helpers.dart';

import 'package:octava/data/sample_musicians.dart';
import 'package:octava/main.dart';
import 'package:octava/screens/swipe_screen.dart';
import 'package:octava/widgets/invite.dart';

/// The feed's open band slots (their pills show the role; screen readers
/// hear "Drums: Open").
final openSlots = find.bySemanticsLabel(RegExp(r': Open$'));

void main() {
  // A phone-sized screen, so the full card layout is used.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const OctavaApp(home: SwipeScreen()));
    await tester.pumpAndSettle(); // the deck loads asynchronously
  }

  testWidgets('shows the band lineup and the first musician', (tester) async {
    await pumpApp(tester);

    expect(find.bySemanticsLabel('OCTAVA'), findsOneWidget); // the logo
    expect(find.text('YOUR BAND'), findsNothing); // no band label
    expect(openSlots, findsNWidgets(4));
    expect(find.text('Nika, 24'), findsOneWidget);
    expect(find.text('Fits your open drums slot'), findsOneWidget);
  });

  testWidgets('Pass moves on to the next musician', (tester) async {
    await pumpApp(tester);

    await swipePass(tester);
    await tester.pumpAndSettle();

    expect(find.text('Nika, 24'), findsNothing);
    expect(find.text('Mariam, 27'), findsOneWidget);
    expect(openSlots, findsNWidgets(4));
  });

  testWidgets('Jam on someone who likes you is a match and fills the slot', (
    tester,
  ) async {
    await pumpApp(tester);

    await swipeJam(tester);
    await tester.pumpAndSettle();

    expect(find.text('Nika wants to jam too'), findsOneWidget);
    expect(find.textContaining('Drums is now filled'), findsOneWidget);

    await tester.tap(find.text('Say hi'));
    await tester.pumpAndSettle();

    expect(find.text('You said hi to Nika'), findsOneWidget);
    // The Drums segment is now taken (screen readers hear who).
    expect(find.bySemanticsLabel('Drums: Nika'), findsOneWidget);
    expect(openSlots, findsNWidgets(3));
  });

  testWidgets('dragging a card right counts as Jam', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.text('Nika, 24'), const Offset(250, 0));
    await tester.pumpAndSettle();

    expect(find.text('Nika wants to jam too'), findsOneWidget);
  });

  testWidgets('a short drag snaps back without deciding', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.text('Nika, 24'), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(find.text('Nika, 24'), findsOneWidget);
    expect(find.text('Nika wants to jam too'), findsNothing);
  });

  testWidgets('after everyone, shows the empty state and can check again', (
    tester,
  ) async {
    await pumpApp(tester);

    for (var i = 0; i < sampleMusicians.length; i++) {
      await swipePass(tester);
      await tester.pumpAndSettle();
    }

    expect(find.text("You've heard everyone"), findsOneWidget);
    expect(
      find.text(
        "That's everyone for now. Invite musicians you know, or widen your filters.",
      ),
      findsOneWidget,
    );

    // Invite musicians opens the share sheet with the landing-page link.
    String? shared;
    debugShareOverride = (text) async => shared = text;
    addTearDown(() => debugShareOverride = null);
    await tester.tap(find.text('Invite musicians'));
    await tester.pumpAndSettle();
    expect(shared, contains('https://luichemo.github.io/OCTAVA/get/'));

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text('Nika, 24'), findsOneWidget);
  });
}
