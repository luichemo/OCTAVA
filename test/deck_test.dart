import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/deck.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/screens/swipe_screen.dart';

/// A deck whose swipes fail, like a lost connection.
class OfflineDeck extends SampleDeck {
  const OfflineDeck();

  @override
  Future<bool> swipe(Musician musician, Decision decision) async =>
      throw const UserFacingException(
        "Couldn't save that. Check your connection and try again.",
      );
}

/// A deck that can't load at all.
class BrokenDeck extends SampleDeck {
  const BrokenDeck();

  @override
  Future<List<Musician>> loadDeck() async => throw const UserFacingException(
    "Couldn't load musicians. Check your connection and try again.",
  );
}

void main() {
  Future<void> pump(WidgetTester tester, DeckSource source) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: SwipeScreen(source: source)));
    await tester.pumpAndSettle();
  }

  testWidgets('a swipe that fails to save puts the card back', (tester) async {
    await pump(tester, const OfflineDeck());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Pass'));
    await tester.pumpAndSettle();

    expect(find.text('Nika, 24'), findsOneWidget);
    expect(find.textContaining("Couldn't save that"), findsOneWidget);
  });

  testWidgets('a deck that fails to load offers to try again', (tester) async {
    await pump(tester, const BrokenDeck());

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Jam'))
          .onPressed,
      isNull,
    );
  });

  test('a get_deck row becomes a card', () {
    final m = Musician.fromDeckRow({
      'id': '6f1c0d1e-0000-4000-8000-000000000001',
      'display_name': 'Ana',
      'age': 25,
      'area': 'Mtatsminda',
      'distance_km': 3,
      'genres': ['indie folk'],
      'looking_for': null,
      'instruments': [
        {'instrument': 'keys', 'skill': 'advanced', 'is_primary': false},
        {'instrument': 'vocals', 'skill': 'pro', 'is_primary': true},
      ],
      'links': [],
      'clips': [],
    });

    expect(m.instrument, 'Vocals');
    expect(m.whereText, 'Mtatsminda, 3 km away');
    expect(m.clipSeconds, isNull);
    expect(m.lookingFor, isNull);
  });

  test('location text copes with missing parts', () {
    const nowhere = Musician(name: 'X', age: 30, instrument: 'Bass');
    const onlyArea = Musician(
      name: 'Y',
      age: 30,
      instrument: 'Bass',
      area: 'Vake',
    );
    expect(nowhere.whereText, '');
    expect(onlyArea.whereText, 'Vake');
  });
}
