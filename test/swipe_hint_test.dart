import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'swipe_helpers.dart';

import 'package:octava/data/swipe_hint.dart';
import 'package:octava/main.dart';
import 'package:octava/screens/swipe_screen.dart';

const _caption = 'Swipe right to Jam, left to Pass';

void main() {
  // Off for every other test (flutter_test_config.dart).
  setUp(() => swipeHintEnabled = true);
  tearDown(() => swipeHintEnabled = false);

  Future<void> pumpFeed(WidgetTester tester, HintStore hints) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: SwipeScreen(hints: hints)));
    await tester.pump(); // the deck loads
    await tester.pump();
  }

  /// How far the top card is from its resting place.
  double cardOffset(WidgetTester tester) {
    final moves = tester.widgetList<Transform>(
      find.ancestor(
        of: find.text('Nika, 24'),
        matching: find.byType(Transform),
      ),
    );
    return moves
        .map((t) => t.transform.getTranslation().x.abs())
        .fold(0.0, (a, b) => a > b ? a : b);
  }

  testWidgets('the first time, the card nudges both ways with a caption', (
    tester,
  ) async {
    final hints = MemoryHintStore();
    await pumpFeed(tester, hints);
    expect(find.text(_caption), findsNothing);

    await tester.pump(const Duration(milliseconds: 700)); // the card lands
    await tester.pump();
    expect(find.text(_caption), findsOneWidget);
    expect(hints.wasSeen, isTrue); // remembered right away

    await tester.pump(const Duration(milliseconds: 300));
    expect(cardOffset(tester), greaterThan(20)); // moving: a nudge to Jam

    // Two rounds of right-and-left, with a pause between: about 4 s.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(_caption), findsNothing); // played through, then gone
    expect(cardOffset(tester), 0);
    expect(find.text('Nika, 24'), findsOneWidget); // nothing was decided
  });

  testWidgets('a touch stops it, and swiping works as usual', (tester) async {
    await pumpFeed(tester, MemoryHintStore());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(_caption), findsOneWidget);

    await swipePass(tester);
    expect(find.text(_caption), findsNothing);
    expect(find.text('Nika, 24'), findsNothing);
    expect(find.text('Mariam, 27'), findsOneWidget);
  });

  test('every new account on a phone gets it once', () async {
    // One phone's saved settings, shared by every account signed in on it.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    final first = PrefsHintStore('account-1');
    expect(await first.seen(), isFalse);
    await first.markSeen();
    expect(await PrefsHintStore('account-1').seen(), isTrue);

    // Someone else signs up on the same phone, or the person deletes their
    // account and creates it again (a new account id): it plays again.
    expect(await PrefsHintStore('account-2').seen(), isFalse);
  });

  testWidgets('it plays only once', (tester) async {
    await pumpFeed(tester, MemoryHintStore(wasSeen: true));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(_caption), findsNothing);
    expect(cardOffset(tester), 0);
  });
}
