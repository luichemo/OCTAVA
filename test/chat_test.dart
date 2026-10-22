import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'record_test.dart' show FakeRecorder;
import 'swipe_helpers.dart';

import 'package:octava/data/chat_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/data/sample_musicians.dart';
import 'package:octava/widgets/musician_card.dart';
import 'package:octava/main.dart';
import 'package:octava/models/chat.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/screens/chat_screen.dart';
import 'package:octava/screens/matches_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

/// In-memory chat: sending adds to the live message stream, and every
/// change is also announced on [changes], like Realtime.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    List<MatchSummary> matches = const [],
    this.refuseSends = false,
  }) : matches = [...matches];

  final List<MatchSummary> matches;
  final bool refuseSends;
  final _messages = <String, List<ChatMessage>>{};
  final _streams = <String, StreamController<List<ChatMessage>>>{};
  final _changes = StreamController<LiveChange>.broadcast();

  /// When you / they last read each match.
  final myReads = <String, DateTime>{};
  final theirReads = <String, DateTime>{};
  final unmatched = <String>[];

  @override
  String get myId => 'me';

  /// Cards for matched people, by id; anyone else gets null.
  final cards = <String, Musician>{};

  @override
  Future<Musician?> matchCard(String personId) async => cards[personId];

  @override
  Future<List<MatchSummary>> loadMatches() async => [
    for (final m in matches)
      MatchSummary(
        matchId: m.matchId,
        otherUserId: m.otherUserId,
        name: m.name,
        instrument: m.instrument,
        matchedAt: m.matchedAt,
        lastMessage: _messages[m.matchId]?.lastOrNull?.body,
        lastMessageAt: _messages[m.matchId]?.lastOrNull?.sentAt,
        lastMessageIsMine: _messages[m.matchId]?.lastOrNull?.senderId == 'me',
        unreadCount: (_messages[m.matchId] ?? [])
            .where(
              (msg) =>
                  msg.senderId != 'me' &&
                  (myReads[m.matchId] == null ||
                      msg.sentAt.isAfter(myReads[m.matchId]!)),
            )
            .length,
        theirLastReadAt: theirReads[m.matchId],
      ),
  ];

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

  @override
  Future<void> markRead(String matchId) async {
    myReads[matchId] = DateTime.now();
    _changes.add(const ReadMarked());
  }

  @override
  Future<void> unmatch(String matchId) async {
    unmatched.add(matchId);
    matches.removeWhere((m) => m.matchId == matchId);
    _changes.add(const MatchRemoved());
  }

  @override
  Stream<LiveChange> changes() => _changes.stream;

  /// A message arriving from either side.
  void receive(
    String matchId,
    String senderId,
    String body, {
    String? audioPath,
    int? audioSeconds,
  }) {
    final list = _messages.putIfAbsent(matchId, () => []);
    list.add(
      ChatMessage(
        id: '${list.length}',
        senderId: senderId,
        body: body,
        sentAt: DateTime.now(),
        audioPath: audioPath,
        audioSeconds: audioSeconds,
      ),
    );
    _streams[matchId]?.add(List.of(list));
    _changes.add(
      MessageArrived(
        matchId: matchId,
        senderId: senderId,
        body: messagePreview(body),
      ),
    );
  }

  /// Voice messages sent, as "matchId:seconds".
  final voiceSent = <String>[];

  @override
  Future<void> sendVoice(
    String matchId, {
    required Uint8List bytes,
    required String fileName,
    required int seconds,
  }) async {
    if (refuseSends) {
      throw const UserFacingException(
        "You can't send messages in this chat anymore.",
      );
    }
    voiceSent.add('$matchId:$seconds');
    receive(
      matchId,
      'me',
      '',
      audioPath: 'm/$matchId/$fileName',
      audioSeconds: seconds,
    );
  }

  @override
  Future<String> voiceUrl(String path) async => 'https://example.invalid/$path';

  final edits = <String>[];

  @override
  Future<void> edit(String messageId, String body) async {
    edits.add('$messageId:$body');
    _editIn(_messages, messageId, body);
  }

  /// Replaces a message's text, marking it edited (like the database).
  void _editIn(
    Map<String, List<ChatMessage>> all,
    String messageId,
    String body,
  ) {
    for (final entry in all.entries) {
      final list = entry.value;
      final i = list.indexWhere((m) => m.id == messageId);
      if (i < 0) continue;
      final m = list[i];
      list[i] = ChatMessage(
        id: m.id,
        senderId: m.senderId,
        body: body.trim(),
        sentAt: m.sentAt,
        editedAt: DateTime.now(),
      );
      _streams[entry.key]?.add(List.of(list));
      return;
    }
  }

  /// Someone else's swipe completes a match with you.
  void matchWith(MatchSummary match, {String createdBy = 'them'}) {
    matches.add(match);
    _changes.add(MatchMade(matchId: match.matchId, createdBy: createdBy));
  }

  /// The other person reads the chat.
  void theyRead(String matchId) {
    theirReads[matchId] = DateTime.now();
    _changes.add(const ReadMarked());
  }
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

  group("a match's card", () {
    testWidgets('opens from their name at the top of the chat', (tester) async {
      final chat = FakeChatRepository(matches: [nika])
        ..cards['nika'] = sampleMusicians.first;
      await pump(tester, MatchesScreen(repository: chat));
      await tester.tap(find.text('New match. Say hi!'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('See their card'));
      await tester.pumpAndSettle();
      expect(find.byType(MusicianCard), findsOneWidget);
      expect(find.text('Open chat'), findsNothing); // Back goes to the chat
    });

    testWidgets('opens from their picture in Matches, with Open chat', (
      tester,
    ) async {
      final chat = FakeChatRepository(matches: [nika])
        ..cards['nika'] = sampleMusicians.first;
      await pump(tester, MatchesScreen(repository: chat));

      await tester.tap(find.byTooltip('See their card'));
      await tester.pumpAndSettle();
      expect(find.byType(MusicianCard), findsOneWidget);

      await tester.tap(find.text('Open chat'));
      await tester.pumpAndSettle();
      expect(find.byType(MusicianCard), findsNothing);
      expect(
        find.textContaining('You and Nika both want to jam'),
        findsOneWidget,
      );
    });

    testWidgets('says so when the card is gone', (tester) async {
      // Unmatched or blocked since the list loaded: no card comes back.
      final chat = FakeChatRepository(matches: [nika]);
      await pump(tester, MatchesScreen(repository: chat));
      await tester.tap(find.byTooltip('See their card'));
      await tester.pumpAndSettle();
      expect(find.text("This card isn't available any more."), findsOneWidget);
    });
  });

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
    await tester.pump(); // the mic turns into Send
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
    await tester.pump(); // the mic turns into Send
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(
      find.text("You can't send messages in this chat anymore."),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Hello?'), findsOneWidget);
  });

  test('messages can be edited by their sender for 15 minutes', () {
    final sent = DateTime(2026, 10, 16, 12);
    final msg = ChatMessage(id: '1', senderId: 'me', body: 'hi', sentAt: sent);
    expect(
      msg.canEdit('me', now: sent.add(const Duration(minutes: 14))),
      isTrue,
    );
    expect(
      msg.canEdit('me', now: sent.add(const Duration(minutes: 16))),
      isFalse,
    );
    expect(msg.canEdit('you', now: sent), isFalse);
  });

  testWidgets('long-press your own message to edit it', (tester) async {
    final chat = FakeChatRepository(matches: [nika]);
    chat.receive(nika.matchId, 'me', 'see you at 7');
    chat.receive(nika.matchId, 'nika', 'cool');
    await pump(
      tester,
      ChatScreen(
        repository: chat,
        matchId: nika.matchId,
        otherUserId: nika.otherUserId,
        name: nika.name,
        instrument: nika.instrument,
      ),
    );
    // Someone else's message: nothing to edit.
    await tester.longPress(find.text('cool'));
    await tester.pumpAndSettle();
    expect(find.text('Edit message'), findsNothing);

    await tester.longPress(find.text('see you at 7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit message'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'see you at 8',
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(chat.edits, ['0:see you at 8']);
    expect(find.text('see you at 8'), findsOneWidget);
    expect(find.textContaining('edited ·'), findsOneWidget);
  });

  testWidgets('send a voice message in a one-on-one chat', (tester) async {
    final chat = FakeChatRepository(matches: [nika]);
    await pump(
      tester,
      ChatScreen(
        repository: chat,
        matchId: nika.matchId,
        otherUserId: nika.otherUserId,
        name: nika.name,
        instrument: nika.instrument,
        recorder: () => FakeRecorder(seconds: 9),
      ),
    );
    await tester.tap(find.byTooltip('Record a voice message'));
    await tester.pump();
    await tester.tap(find.byTooltip('Send voice message'));
    await tester.pumpAndSettle();
    expect(chat.voiceSent, ['${nika.matchId}:9']);
    expect(find.text('0:09'), findsOneWidget);
  });

  testWidgets('"Say hi" after a match opens the chat', (tester) async {
    String? openedMatch;
    await pump(
      tester,
      SwipeScreen(onOpenChat: (matchId, musician) => openedMatch = matchId),
    );

    await swipeJam(tester); // Nika likes you
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
    expect(formatMessageTime(DateTime(2026, 9, 30, 12, 0), now: now), 'Sep 30');
  });
}
