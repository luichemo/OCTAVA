import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'swipe_helpers.dart';

import 'package:octava/data/deck.dart';
import 'package:octava/data/live_updates.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band.dart';
import 'package:octava/models/chat.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/screens/matches_screen.dart';
import 'package:octava/screens/swipe_screen.dart';
import 'package:octava/widgets/live_banner.dart';

import 'chat_test.dart' show FakeChatRepository;

/// Sample people whose band members and undos can be checked.
class RecordingDeck extends SampleDeck {
  RecordingDeck();

  final undone = <String>[];
  final members = <BandMember>[];

  @override
  Future<void> undo(Musician musician) async => undone.add(musician.name);

  @override
  Future<({String? myRole, List<BandMember> members})> loadBand() async =>
      (myRole: 'guitar', members: List.of(members));
}

void main() {
  final nika = MatchSummary(
    matchId: 'm1',
    otherUserId: 'nika',
    name: 'Nika',
    instrument: 'Drums',
    matchedAt: DateTime.now().subtract(const Duration(hours: 1)),
  );

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  /// The swipe screen as the app shows it: with live updates and banners.
  Future<(LiveUpdates, List<String>)> pumpSwipe(
    WidgetTester tester,
    FakeChatRepository chat, {
    DeckSource? deck,
  }) async {
    final live = LiveUpdates(chat)..start();
    addTearDown(live.dispose);
    final opened = <String>[];
    await pump(
      tester,
      LiveBannerListener(
        live: live,
        onOpen: (m) => opened.add(m.matchId),
        child: SwipeScreen(
          source: deck ?? const SampleDeck(),
          live: live,
          onOpenMatches: () {},
        ),
      ),
    );
    return (live, opened);
  }

  group('while swiping', () {
    testWidgets('a message shows a banner and an unread badge', (tester) async {
      final chat = FakeChatRepository(matches: [nika]);
      final (live, opened) = await pumpSwipe(tester, chat);
      expect(find.byType(Badge).evaluate().where(_visibleBadge), isEmpty);

      chat.receive('m1', 'nika', 'Rehearsal on Friday?');
      await tester.pump();
      await tester.pump();

      expect(live.unreadTotal, 1);
      expect(find.text('Rehearsal on Friday?'), findsOneWidget);
      expect(find.widgetWithText(Badge, '1'), findsOneWidget);
      // The sender's picture (here their initial), not a generic icon.
      expect(find.text('N'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsNothing);

      await tester.tap(find.text('Rehearsal on Friday?'));
      await tester.pump();
      expect(opened, ['m1']);
      expect(find.text('Rehearsal on Friday?'), findsNothing);
    });

    testWidgets('banners go away by themselves', (tester) async {
      final chat = FakeChatRepository(matches: [nika]);
      await pumpSwipe(tester, chat);
      chat.receive('m1', 'nika', 'Hey');
      await tester.pump();
      await tester.pump();
      expect(find.text('Hey'), findsOneWidget);

      await tester.pump(LiveBannerListener.showFor);
      expect(find.text('Hey'), findsNothing);
    });

    testWidgets("someone else's match shows a banner and fills the band", (
      tester,
    ) async {
      final chat = FakeChatRepository();
      final deck = RecordingDeck();
      await pumpSwipe(tester, chat, deck: deck);
      expect(find.text('Open'), findsNWidgets(4));

      deck.members.add((name: 'Nika', role: 'drums'));
      chat.matchWith(nika);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Nika wants to jam too'), findsOneWidget);
      expect(find.text('Open'), findsNWidgets(3));
      await tester.pump(LiveBannerListener.showFor);
    });

    testWidgets('your own match shows no banner (you saw the dialog)', (
      tester,
    ) async {
      final chat = FakeChatRepository();
      await pumpSwipe(tester, chat);
      chat.matchWith(nika, createdBy: 'me');
      await tester.pump();
      await tester.pump();
      expect(find.text('Nika wants to jam too'), findsNothing);
    });

    testWidgets('a pass can be undone from the message', (tester) async {
      final deck = RecordingDeck();
      await pumpSwipe(tester, FakeChatRepository(), deck: deck);

      await swipePass(tester);
      await tester.pumpAndSettle();
      expect(find.text('Nika, 24'), findsNothing);
      expect(find.text('Passed on Nika.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(deck.undone, ['Nika']);
      expect(find.text('Nika, 24'), findsOneWidget);
    });
  });

  group('matches and chat', () {
    testWidgets('the list updates live and opening a chat reads it', (
      tester,
    ) async {
      final chat = FakeChatRepository(matches: [nika]);
      await pump(tester, MatchesScreen(repository: chat));
      expect(find.text('New match. Say hi!'), findsOneWidget);

      chat.receive('m1', 'nika', 'Are you free Thursday?');
      await tester.pumpAndSettle();
      expect(find.text('Are you free Thursday?'), findsOneWidget);
      expect(find.widgetWithText(Badge, '1'), findsOneWidget);

      await tester.tap(find.text('Are you free Thursday?'));
      await tester.pumpAndSettle();
      expect(chat.myReads.containsKey('m1'), isTrue);
      expect(find.text('Today'), findsOneWidget); // day separator

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Badge, '1'), findsNothing);
    });

    testWidgets('"Seen" appears when they read your message', (tester) async {
      final chat = FakeChatRepository(matches: [nika]);
      await pump(tester, MatchesScreen(repository: chat));
      await tester.tap(find.text('New match. Say hi!'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hi!');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Seen'), findsNothing);

      await tester.pump(const Duration(milliseconds: 5));
      chat.theyRead('m1');
      await tester.pumpAndSettle();
      expect(find.text('Seen'), findsOneWidget);
    });

    testWidgets('unmatching closes the chat and empties the list', (
      tester,
    ) async {
      final chat = FakeChatRepository(matches: [nika]);
      await pump(tester, MatchesScreen(repository: chat));
      await tester.tap(find.text('New match. Say hi!'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unmatch'));
      await tester.pumpAndSettle();
      expect(find.text('Unmatch Nika?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unmatch'));
      await tester.pumpAndSettle();

      expect(chat.unmatched, ['m1']);
      expect(find.byType(MatchesScreen), findsOneWidget);
      expect(find.textContaining('No matches yet'), findsOneWidget);
    });
  });

  test('day separators read naturally', () {
    final now = DateTime(2026, 10, 12, 18, 0);
    expect(formatDay(DateTime(2026, 10, 12, 9, 0), now: now), 'Today');
    expect(formatDay(DateTime(2026, 10, 11, 23, 0), now: now), 'Yesterday');
    expect(formatDay(DateTime(2026, 9, 30), now: now), 'Sep 30');
    expect(formatDay(DateTime(2025, 9, 30), now: now), 'Sep 30, 2025');
  });
}

bool _visibleBadge(Element e) => (e.widget as Badge).isLabelVisible;
