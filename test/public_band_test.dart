import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/live_bands.dart';
import 'package:octava/data/public_band_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/l10n/l10n.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band_group.dart';
import 'package:octava/screens/band_screen.dart';
import 'package:octava/screens/public_band_screen.dart';

import 'bands_test.dart' show FakeBandsRepository, me, nika;
import 'profile_edit_test.dart' show FakeClipPlayer;

const bandId = '5d543885-d62f-4432-8925-23793d67621a';

/// Answers like the band-page function: the band, null (404) or an error.
class FakePublicBands implements PublicBandSource {
  FakePublicBands({this.band, this.fail = false});

  final PublicBand? band;
  bool fail;
  int loads = 0;

  @override
  Future<PublicBand?> load(String bandId) async {
    loads++;
    if (fail) throw UserFacingException(L10n.current.errPublicBandLoad);
    return band;
  }
}

void main() {
  final riot = PublicBand.fromJson({
    'id': bandId,
    'name': 'Riot Grrl',
    'description': 'Loud and fast.',
    'genres': ['post-punk'],
    'openRoles': ['drums'],
    'clipUrl': 'https://example.invalid/clip.m4a?token=x',
    'clipSeconds': 42,
    'members': [
      {'instrument': 'vocals', 'name': 'Luka', 'avatarUrl': null},
      // A 16–17 year old: the function leaves out name and picture.
      {'instrument': 'bass', 'name': null, 'avatarUrl': null},
    ],
    'songs': ['Night Drive', 'Tbilisi Rain'],
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  test('links carry the band id, and only real ids are read back', () {
    expect(
      publicBandLink(bandId),
      'https://luichemo.github.io/OCTAVA/?band=$bandId',
    );
    expect(bandIdFromLink(Uri.parse(publicBandLink(bandId))), bandId);
    expect(bandIdFromLink(Uri.parse('https://x.invalid/?band=nope')), isNull);
    expect(bandIdFromLink(Uri.parse('https://x.invalid/')), isNull);
  });

  testWidgets('a visitor sees the band, teens as their instrument only', (
    tester,
  ) async {
    final player = FakeClipPlayer();
    var joined = 0;
    await pump(
      tester,
      PublicBandScreen(
        source: FakePublicBands(band: riot),
        bandId: bandId,
        player: player,
        onJoin: () => joined++,
      ),
    );
    expect(find.text('Riot Grrl'), findsOneWidget);
    expect(find.text('Post-punk'), findsOneWidget);
    expect(find.text('Loud and fast.'), findsOneWidget);
    expect(find.text('Looking for: Drums'), findsOneWidget);
    // The adult: name, with the instrument under it.
    expect(find.text('Luka'), findsOneWidget);
    expect(find.text('Vocals'), findsOneWidget);
    // The teen: just "Bass".
    expect(find.text('Bass'), findsOneWidget);
    expect(find.text('1. Night Drive'), findsOneWidget);
    expect(find.text('2. Tbilisi Rain'), findsOneWidget);

    await tester.tap(find.byTooltip('Play the band clip'));
    await tester.pump();
    expect(player.toggled, [riot.clipUrl]);

    await tester.tap(find.text('Join OCTAVA'));
    expect(joined, 1);
  });

  testWidgets('a private or missing band says so, and still invites', (
    tester,
  ) async {
    await pump(
      tester,
      PublicBandScreen(
        source: FakePublicBands(),
        bandId: bandId,
        onJoin: () {},
      ),
    );
    expect(find.textContaining("isn't available"), findsOneWidget);
    expect(find.text('Join OCTAVA'), findsOneWidget);
  });

  testWidgets('a failed load can be tried again', (tester) async {
    final source = FakePublicBands(band: riot, fail: true);
    await pump(tester, PublicBandScreen(source: source, bandId: bandId));
    expect(find.textContaining("Couldn't load this band"), findsOneWidget);
    // Members previewing have no Join button.
    expect(find.text('Join OCTAVA'), findsNothing);

    source.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Riot Grrl'), findsOneWidget);
    expect(source.loads, 2);
  });

  testWidgets('a member switches the public page on, then can copy the link', (
    tester,
  ) async {
    final repo = FakeBandsRepository(
      bands: const [
        MyBand(id: 'b1', name: 'Riot', members: [me, nika]),
      ],
    );
    final live = LiveBands(repo)..start();
    addTearDown(live.dispose);
    await pump(tester, BandScreen(bands: live, bandId: 'b1'));
    expect(find.textContaining('Off: only band members'), findsOneWidget);
    expect(find.text('Copy link'), findsNothing);

    await tester.tap(find.text('Public page'));
    await tester.pumpAndSettle();
    expect(repo.bands.single.isPublic, isTrue);
    expect(find.textContaining('On: anyone with the link'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('View page'), findsOneWidget);

    await tester.tap(find.text('Public page'));
    await tester.pumpAndSettle();
    expect(repo.bands.single.isPublic, isFalse);
  });

  testWidgets('the public page fits in Georgian', (tester) async {
    appLanguage.value = const Locale('ka');
    addTearDown(() => appLanguage.value = null);
    await pump(
      tester,
      PublicBandScreen(
        source: FakePublicBands(band: riot),
        bandId: bandId,
        onJoin: () {},
      ),
    );
    expect(find.text('შემოუერთდი OCTAVA-ს'), findsOneWidget);
  });
}
