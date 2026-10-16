import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/deck.dart';
import 'package:octava/data/sample_musicians.dart';
import 'package:octava/l10n/l10n.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band_card.dart';
import 'package:octava/screens/swipe_screen.dart';
import 'package:octava/widgets/band_card.dart';

import 'profile_edit_test.dart' show FakeClipPlayer;
import 'swipe_helpers.dart';

const riot = BandCardData(
  id: 'riot',
  name: 'Riot',
  description: 'Loud songs, Friday rehearsals.',
  genres: ['post-punk', 'shoegaze'],
  openRoles: ['drums', 'keys'],
  memberInstruments: ['guitar', 'bass'],
  memberCount: 2,
  clipPath: 'riot/song.m4a',
  clipSeconds: 42,
  fitsYou: true,
);

const quiet = BandCardData(id: 'quiet', name: 'Quiet', memberCount: 1);

/// The sample people plus band cards; records band swipes.
class BandDeck extends SampleDeck {
  BandDeck(this.bands);

  final List<BandCardData> bands;
  final bandSwipes = <String>[];

  @override
  Future<List<BandCardData>> loadBandCards() async => bands;

  @override
  Future<bool> swipeBand(BandCardData band, Decision decision) async {
    bandSwipes.add('${band.id}:${decision.name}');
    return decision == Decision.jam;
  }
}

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  test('a band comes after every 3 people, ones needing you first', () {
    final deck = mixDeck(sampleMusicians.take(7).toList(), [quiet, riot]);
    expect(
      [
        for (final d in deck)
          switch (d) {
            PersonItem() => 'P',
            BandItem(:final band) => band.id,
          },
      ],
      ['P', 'P', 'P', 'riot', 'P', 'P', 'P', 'quiet', 'P'],
    );
  });

  test('bands left over go after the people', () {
    final deck = mixDeck(sampleMusicians.take(2).toList(), [riot]);
    expect(deck.last, isA<BandItem>());
  });

  testWidgets('a band card shows its profile, members as instruments only', (
    tester,
  ) async {
    final player = FakeClipPlayer();
    await pump(
      tester,
      Scaffold(
        body: SizedBox(
          height: 640,
          child: BandCard(band: riot, player: player),
        ),
      ),
    );
    expect(find.text('RIOT'), findsOneWidget);
    expect(find.text('Needs your instrument'), findsOneWidget);
    expect(find.text('Looking for: Drums and Keys'), findsNothing);
    // The lineup: two members, then the two open roles.
    expect(find.text('Guitar'), findsOneWidget);
    expect(find.text('In the band'), findsNWidgets(2));
    expect(find.text('Open'), findsNWidgets(2));
    expect(find.text('Post-punk'), findsOneWidget);
    expect(find.text('Loud songs, Friday rehearsals.'), findsOneWidget);
    expect(find.text('Band clip · 0:42'), findsOneWidget);

    await tester.tap(find.byTooltip('Play the band clip'));
    await tester.pump();
    expect(player.toggled, ['band:riot/song.m4a']);
  });

  testWidgets('in the feed, a band card comes after 3 people and Jam asks to '
      'join', (tester) async {
    final deck = BandDeck([riot]);
    await pump(tester, SwipeScreen(source: deck));
    for (var i = 0; i < 3; i++) {
      await swipePass(tester);
      await tester.pumpAndSettle();
    }
    expect(find.byType(BandCard), findsOneWidget);

    await tester.drag(find.byType(BandCard), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(deck.bandSwipes, ['riot:jam']);
    expect(
      find.text('Asked to join Riot. Its members will vote.'),
      findsOneWidget,
    );
  });

  testWidgets('passing on a band hides it', (tester) async {
    final deck = BandDeck([riot]);
    await pump(tester, SwipeScreen(source: deck));
    for (var i = 0; i < 3; i++) {
      await swipePass(tester);
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(BandCard), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(deck.bandSwipes, ['riot:pass']);
    expect(find.text('Passed on Riot.'), findsOneWidget);
    expect(find.byType(BandCard), findsNothing);
  });

  testWidgets('the band card fits in Georgian', (tester) async {
    appLanguage.value = const Locale('ka');
    addTearDown(() => appLanguage.value = null);
    await pump(
      tester,
      const Scaffold(
        body: SizedBox(height: 640, child: BandCard(band: riot)),
      ),
    );
    expect(find.text('შენი ინსტრუმენტი სჭირდებათ'), findsOneWidget);
  });
}
