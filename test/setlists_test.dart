import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/l10n/l10n.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band_group.dart';
import 'package:octava/models/rehearsal.dart';
import 'package:octava/models/setlist.dart';
import 'package:octava/models/song.dart';
import 'package:octava/screens/setlist_screen.dart';
import 'package:octava/widgets/rehearsals_section.dart';
import 'package:octava/widgets/setlists_section.dart';

import 'bands_test.dart' show me, nika, tamar;
import 'rehearsals_test.dart' show FakeRehearsalRepository;
import 'songs_test.dart' show FakeSongRepository;

void main() {
  const songs = [
    Song(id: 's1', bandId: 'b1', title: 'Opener', recordingSeconds: 200),
    Song(id: 's2', bandId: 'b1', title: 'Ballad', recordingSeconds: 250),
    Song(id: 's3', bandId: 'b1', title: 'Closer'),
  ];

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  Widget section(FakeSongRepository repo) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [SetlistsSection(repository: repo, bandId: 'b1')],
    ),
  );

  /// The song titles on the setlist screen, top to bottom.
  List<String> order(WidgetTester tester) {
    final titles = [
      for (final s in songs)
        if (find.text(s.title).evaluate().isNotEmpty) s.title,
    ];
    return titles..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
  }

  test('the length adds up the recordings and counts the rest', () {
    final length = setlistLength(songs);
    expect(length.seconds, 450);
    expect(length.unknown, 1);
    expect(setlistSummary(songs), '3 songs · 8 min · 1 without a recording');
    expect(setlistSummary(const []), 'No songs');
  });

  testWidgets('make a setlist and add songs in order', (tester) async {
    final repo = FakeSongRepository(songs);
    await pump(tester, section(repo));
    expect(find.textContaining('No setlists yet'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Friday gig');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    // The setlist opens, empty.
    expect(find.text('Friday gig'), findsOneWidget);
    expect(find.textContaining('No songs in this setlist'), findsOneWidget);

    await tester.tap(find.text('Add songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Closer'));
    await tester.tap(find.text('Opener'));
    await tester.pump();
    await tester.tap(find.text('Add 2'));
    await tester.pumpAndSettle();

    // Picked songs keep the band's order (ready first, then by title).
    expect(repo.setlistRows.single.songIds, ['s3', 's1']);
    expect(
      find.text('2 songs · 4 min · 1 without a recording'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Friday gig'), findsOneWidget);
    expect(
      find.text('2 songs · 4 min · 1 without a recording'),
      findsOneWidget,
    );
  });

  testWidgets('drag to reorder, and take a song out', (tester) async {
    final repo = FakeSongRepository(songs, const [
      Setlist(id: 'l1', bandId: 'b1', name: 'Set', songIds: ['s1', 's2', 's3']),
    ]);
    await pump(
      tester,
      SetlistScreen(repository: repo, setlist: repo.setlistRows.single),
    );
    expect(order(tester), ['Opener', 'Ballad', 'Closer']);

    // Drag the first song's handle below the last one.
    final handle = find.byIcon(Icons.drag_indicator_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(kLongPressTimeout);
    await gesture.moveBy(const Offset(0, 250));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(repo.setlistRows.single.songIds, ['s2', 's3', 's1']);
    expect(order(tester), ['Ballad', 'Closer', 'Opener']);

    await tester.tap(find.byTooltip('Remove from setlist').first);
    await tester.pumpAndSettle();
    expect(repo.setlistRows.single.songIds, ['s3', 's1']);
    expect(find.text('Ballad'), findsNothing);
  });

  testWidgets('rename, then delete after asking', (tester) async {
    final repo = FakeSongRepository(songs, const [
      Setlist(id: 'l1', bandId: 'b1', name: 'Set', songIds: ['s1']),
    ]);
    await pump(tester, section(repo));
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Big show');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();
    expect(repo.setlistRows.single.name, 'Big show');
    expect(find.text('Big show'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete setlist'));
    await tester.pumpAndSettle();
    expect(find.text('Delete “Big show”?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete setlist'));
    await tester.pumpAndSettle();
    expect(repo.setlistRows, isEmpty);
    // Back on the band page; the songs are still there.
    expect(find.textContaining('No setlists yet'), findsOneWidget);
    expect(repo.songs, hasLength(3));
  });

  testWidgets('a rehearsal links a setlist to practise', (tester) async {
    const band = MyBand(id: 'b1', name: 'Riot', members: [me, nika, tamar]);
    final songsRepo = FakeSongRepository(songs, const [
      Setlist(id: 'l1', bandId: 'b1', name: 'Friday gig', songIds: ['s1']),
    ]);
    final rehearsals = FakeRehearsalRepository();
    await pump(
      tester,
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RehearsalsSection(
              repository: rehearsals,
              band: band,
              songs: songsRepo,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Setlist to practise'), findsOneWidget);
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday gig').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(rehearsals.rehearsals.single.setlistId, 'l1');
    expect(find.text('Practise: Friday gig'), findsOneWidget);

    // The date's sheet opens the setlist.
    await tester.tap(find.text('Practise: Friday gig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practise: Friday gig').last);
    await tester.pumpAndSettle();
    expect(find.byType(SetlistScreen), findsOneWidget);
    expect(find.text('Opener'), findsOneWidget);
  });

  testWidgets('a rehearsal without setlists has no setlist choice', (
    tester,
  ) async {
    const band = MyBand(id: 'b1', name: 'Riot', members: [me]);
    await pump(
      tester,
      Scaffold(
        body: ListView(
          children: [
            RehearsalsSection(
              repository: FakeRehearsalRepository(),
              band: band,
              songs: FakeSongRepository(songs),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Setlist to practise'), findsNothing);
    expect(Rehearsal, isNotNull);
  });

  testWidgets('a setlist fits in Georgian', (tester) async {
    appLanguage.value = const Locale('ka');
    addTearDown(() => appLanguage.value = null);
    final repo = FakeSongRepository(songs, const [
      Setlist(
        id: 'l1',
        bandId: 'b1',
        name: 'კონცერტი',
        songIds: ['s1', 's2', 's3'],
      ),
    ]);
    await pump(tester, section(repo));
    expect(find.text('სეტლისტები'), findsOneWidget);
    await tester.tap(find.text('კონცერტი'));
    await tester.pumpAndSettle();
    expect(find.text('სიმღერების დამატება'), findsOneWidget);
  });
}
