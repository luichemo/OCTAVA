import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/location_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/deck_filters.dart';
import 'package:octava/screens/swipe_screen.dart';

class FakeLocation implements LocationRepository {
  FakeLocation({this.sharing = false, this.error});

  bool sharing;
  final String? error;

  @override
  Future<bool> hasLocation() async => sharing;

  @override
  Future<void> shareCurrentLocation() async {
    if (error != null) throw UserFacingException(error!);
    sharing = true;
  }

  @override
  Future<void> stopSharing() async => sharing = false;
}

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  group('filters', () {
    test('only real filters count, and skill needs instruments', () {
      expect(const DeckFilters(minSkill: 'pro').activeCount, 0);
      expect(
        const DeckFilters(instruments: {'drums'}, minSkill: 'pro').activeCount,
        2,
      );
      expect(const DeckFilters().describe(hasLocation: false), 'Everywhere');
      expect(
        const DeckFilters(goals: {'fun'}).describe(hasLocation: true),
        'Within 25 km, 1 filter',
      );
    });

    test('database parameters leave unused filters as "any"', () {
      final params = const DeckFilters(
        maxKm: 10,
        minSkill: 'pro',
      ).toRpcParams(hasLocation: false);
      expect(params['max_km'], isNull); // no location yet
      expect(params['min_skill'], isNull); // no instruments picked
      expect(params['instrument_ids'], isNull);
    });

    test('filters survive a round trip through storage', () {
      const f = DeckFilters(
        maxKm: null,
        instruments: {'bass'},
        genres: ['funk'],
        frequencies: {'weekly'},
      );
      final back = DeckFilters.fromJson(f.toJson());
      expect(back.maxKm, isNull);
      expect(back.instruments, {'bass'});
      expect(back.genres, ['funk']);
      expect(back.frequencies, {'weekly'});
    });

    testWidgets('choosing drums shows only drummers and is remembered', (
      tester,
    ) async {
      final store = MemoryFilterStore();
      await pump(tester, SwipeScreen(filterStore: store));
      expect(find.text('Everywhere'), findsOneWidget);

      await tester.tap(find.text('Everywhere'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Drums'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Show musicians'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Show musicians'));
      await tester.pumpAndSettle();

      expect(find.text('Everywhere, 1 filter'), findsOneWidget);
      expect(find.text('Nika, 24'), findsOneWidget); // a drummer
      expect(find.text('Mariam, 27'), findsNothing); // bass
      expect((await store.load()).instruments, {'drums'});
    });

    testWidgets('no matches suggests changing filters', (tester) async {
      final store = MemoryFilterStore();
      await store.save(const DeckFilters(instruments: {'cello'}));
      await pump(tester, SwipeScreen(filterStore: store));

      expect(find.text('Nobody matches'), findsOneWidget);
      expect(find.text('Change filters'), findsOneWidget);
    });
  });

  group('location', () {
    testWidgets('sharing a location hides the prompt and enables distance', (
      tester,
    ) async {
      final location = FakeLocation();
      await pump(tester, SwipeScreen(location: location));
      expect(find.text('See how far away people are.'), findsOneWidget);

      await tester.tap(find.text('Share location'));
      await tester.pumpAndSettle();

      expect(location.sharing, isTrue);
      expect(find.text('See how far away people are.'), findsNothing);
      expect(find.text('Within 25 km'), findsOneWidget);
    });

    testWidgets('a refused permission is explained', (tester) async {
      await pump(
        tester,
        SwipeScreen(
          location: FakeLocation(
            error: "OCTAVA isn't allowed to use your location.",
          ),
        ),
      );
      await tester.tap(find.text('Share location'));
      await tester.pumpAndSettle();
      expect(
        find.text("OCTAVA isn't allowed to use your location."),
        findsOneWidget,
      );
    });
  });

  testWidgets('the bottom bar holds profile, record and matches', (
    tester,
  ) async {
    var opened = <String>[];
    await pump(
      tester,
      SwipeScreen(
        onOpenProfile: () async => opened.add('profile'),
        onOpenMatches: () => opened.add('matches'),
        onRecord: () => opened.add('record'),
      ),
    );
    // Choosing is by swiping: no Pass or Jam buttons, and no hint text.
    expect(find.widgetWithText(FilledButton, 'Jam'), findsNothing);
    expect(find.textContaining('Swipe right'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Record a clip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matches'));
    expect(opened, ['profile', 'record', 'matches']);
    opened = [];
  });
}
