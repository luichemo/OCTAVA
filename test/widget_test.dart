import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'swipe_helpers.dart';

import 'package:octava/data/deck.dart';
import 'package:octava/data/sample_musicians.dart';
import 'package:octava/main.dart';
import 'package:octava/screens/swipe_screen.dart';

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

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text('Nika, 24'), findsOneWidget);
  });

  testWidgets('the temporary reset clears your swipes and refills the deck', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deck = _ResettableDeck();
    await tester.pumpWidget(OctavaApp(home: SwipeScreen(source: deck)));
    await tester.pumpAndSettle();
    for (var i = 0; i < sampleMusicians.length; i++) {
      await swipePass(tester);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Reset my swipes (test)'));
    await tester.pumpAndSettle();
    // It asks first; Cancel changes nothing.
    expect(find.text('Reset all your swipes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deck.resets, 0);

    await tester.tap(find.text('Reset my swipes (test)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset swipes'));
    await tester.pumpAndSettle();
    expect(deck.resets, 1);
    expect(
      find.text("Your swipes are cleared. Everyone's back."),
      findsOneWidget,
    );
    expect(find.text('Nika, 24'), findsOneWidget);
  });
}

class _ResettableDeck extends SampleDeck {
  _ResettableDeck();

  int resets = 0;

  @override
  Future<void> resetSwipes() async => resets++;
}
