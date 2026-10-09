import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/deck.dart';
import 'package:octava/data/safety_repository.dart';
import 'package:octava/main.dart';
import 'package:octava/models/chat.dart';
import 'package:octava/models/deck_filters.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/screens/matches_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

import 'chat_test.dart' show FakeChatRepository;

class FakeSafetyRepository implements SafetyRepository {
  final blocked = <String>[];
  final reports = <(String, String, String)>[];

  @override
  Future<void> block(String userId) async => blocked.add(userId);

  @override
  Future<void> report(String userId, String reason, String details) async =>
      reports.add((userId, reason, details));
}

/// Sample people with database-style ids, so they can be blocked.
class IdDeck extends SampleDeck {
  const IdDeck();

  @override
  Future<List<Musician>> loadDeck(
    DeckFilters filters, {
    required bool hasLocation,
  }) async => const [
    Musician(id: 'nika-id', name: 'Nika', age: 24, instrument: 'Drums'),
    Musician(id: 'mariam-id', name: 'Mariam', age: 27, instrument: 'Bass'),
  ];
}

void main() {
  final nika = MatchSummary(
    matchId: 'm1',
    otherUserId: 'nika-id',
    name: 'Nika',
    instrument: 'Drums',
    matchedAt: DateTime.now(),
  );

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  Future<void> openNikasChat(
    WidgetTester tester,
    FakeSafetyRepository safety,
  ) async {
    await pump(
      tester,
      MatchesScreen(
        repository: FakeChatRepository(matches: [nika]),
        safety: safety,
      ),
    );
    await tester.tap(find.text('New match. Say hi!'));
    await tester.pumpAndSettle();
  }

  testWidgets('blocking from a chat closes it', (tester) async {
    final safety = FakeSafetyRepository();
    await openNikasChat(tester, safety);

    await tester.tap(find.byTooltip('Block or report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Nika'));
    await tester.pumpAndSettle();
    expect(find.text('Block Nika?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Block Nika'));
    await tester.pumpAndSettle();

    expect(safety.blocked, ['nika-id']);
    expect(find.text('You blocked Nika.'), findsOneWidget);
    expect(find.byType(MatchesScreen), findsOneWidget);
  });

  testWidgets('cancelling a block does nothing', (tester) async {
    final safety = FakeSafetyRepository();
    await openNikasChat(tester, safety);

    await tester.tap(find.byTooltip('Block or report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Nika'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(safety.blocked, isEmpty);
    expect(
      find.textContaining('You and Nika both want to jam'),
      findsOneWidget,
    );
  });

  testWidgets('a report needs a reason and also blocks by default', (
    tester,
  ) async {
    final safety = FakeSafetyRepository();
    await openNikasChat(tester, safety);

    await tester.tap(find.byTooltip('Block or report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report Nika'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(FilledButton, 'Send report');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.text('Harassment or hate'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Details (optional)'),
      'Rude messages',
    );
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(safety.reports, [('nika-id', 'harassment', 'Rude messages')]);
    expect(safety.blocked, ['nika-id']);
    expect(
      find.text('Thanks for reporting. You also blocked Nika.'),
      findsOneWidget,
    );
  });

  testWidgets('blocking from a card removes it from the deck', (tester) async {
    final safety = FakeSafetyRepository();
    await pump(tester, SwipeScreen(source: const IdDeck(), safety: safety));
    expect(find.text('Nika, 24'), findsOneWidget);

    await tester.tap(find.byTooltip('Block or report').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Nika'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Block Nika'));
    await tester.pumpAndSettle();

    expect(safety.blocked, ['nika-id']);
    expect(find.text('Nika, 24'), findsNothing);
    expect(find.text('Mariam, 27'), findsOneWidget);
  });
}
