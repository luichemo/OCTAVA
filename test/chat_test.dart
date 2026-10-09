import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/chat_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/chat.dart';
import 'package:octava/screens/matches_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

/// In-memory chat: sending adds to the live message stream, like Realtime.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.matches = const [], this.refuseSends = false});

  final List<MatchSummary> matches;
  final bool refuseSends;
  final _messages = <String, List<ChatMessage>>{};
  final _streams = <String, StreamController<List<ChatMessage>>>{};

  @override
  String get myId => 'me';

  @override
  Future<List<MatchSummary>> loadMatches() async => matches;

  @override
  Stream<List<ChatMessage>> messages(String matchId) {
    final controller = _streams.putIfAbsent(
      matchId,
      StreamController<List<ChatMessage>>.broadcast,
    );
    scheduleMicrotask(() => controller.add(List.of(_messages[matchId] ?? [])));
    return controller.stream;
  }

  @override
  Future<void> send(String matchId, String body) async {
    if (refuseSends) {
      throw const UserFacingException(
        "You can't send messages in this chat anymore.",
      );
    }
    receive(matchId, 'me', body);
  }

  /// A message arriving from either side.
  void receive(String matchId, String senderId, String body) {
    final list = _messages.putIfAbsent(matchId, () => []);
    list.add(
      ChatMessage(
        id: '${list.length}',
        senderId: senderId,
        body: body,
        sentAt: DateTime.now(),
      ),
    );
    _streams[matchId]?.add(List.of(list));
  }
}

void main() {
  final nika = MatchSummary(
    matchId: 'm1',
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

  testWidgets('lists matches and opens a chat', (tester) async {
    final chat = FakeChatRepository(matches: [nika]);
    await pump(tester, MatchesScreen(repository: chat));

    expect(find.text('New match. Say hi!'), findsOneWidget);

    await tester.tap(find.text('New match. Say hi!'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('You and Nika both want to jam'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'Hi Nika! Free on Thursday?',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Hi Nika! Free on Thursday?'), findsOneWidget);

    chat.receive('m1', 'nika', 'Yes! 7pm?');
    await tester.pumpAndSettle();
    expect(find.text('Yes! 7pm?'), findsOneWidget);
  });

  testWidgets('says so when there are no matches', (tester) async {
    await pump(tester, MatchesScreen(repository: FakeChatRepository()));
    expect(find.textContaining('No matches yet'), findsOneWidget);
  });

  testWidgets('explains a refused message and keeps the text', (tester) async {
    final chat = FakeChatRepository(matches: [nika], refuseSends: true);
    await pump(tester, MatchesScreen(repository: chat));
    await tester.tap(find.text('New match. Say hi!'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(
      find.text("You can't send messages in this chat anymore."),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Hello?'), findsOneWidget);
  });

  testWidgets('"Say hi" after a match opens the chat', (tester) async {
    String? openedMatch;
    await pump(
      tester,
      SwipeScreen(onOpenChat: (matchId, musician) => openedMatch = matchId),
    );

    await tester.tap(
      find.widgetWithText(FilledButton, 'Jam'),
    ); // Nika likes you
    await tester.pumpAndSettle();
    await tester.tap(find.text('Say hi'));
    await tester.pumpAndSettle();

    expect(openedMatch, isNotNull);
  });

  test('message times read naturally', () {
    final now = DateTime(2026, 10, 9, 18, 0);
    expect(formatMessageTime(DateTime(2026, 10, 9, 9, 5), now: now), '09:05');
    expect(
      formatMessageTime(DateTime(2026, 10, 8, 23, 0), now: now),
      'Yesterday',
    );
    expect(formatMessageTime(DateTime(2026, 9, 30, 12, 0), now: now), '30 Sep');
  });
}
