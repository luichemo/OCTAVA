import '../l10n/l10n.dart';

import 'package:intl/intl.dart';

/// One of your matches, as listed on the Matches screen.
class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.otherUserId,
    required this.name,
    required this.instrument,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageIsMine = false,
    this.unreadCount = 0,
    this.theirLastReadAt,
    this.avatarPath,
  });

  /// Their AI avatar in the `avatars` bucket, if they made one.
  final String? avatarPath;

  final String matchId;

  /// The other person's id, for blocking and reporting.
  final String otherUserId;

  /// The other person's name and main instrument label.
  final String name;
  final String instrument;
  final DateTime matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool lastMessageIsMine;

  /// Their messages you haven't read yet.
  final int unreadCount;

  /// When they last read this chat, for "Seen". Null if never.
  final DateTime? theirLastReadAt;

  /// The same match with fewer fields changed (Dart has no spread for
  /// classes, so immutable models get a `copyWith` by hand).
  MatchSummary copyWith({int? unreadCount}) => MatchSummary(
    matchId: matchId,
    otherUserId: otherUserId,
    name: name,
    instrument: instrument,
    matchedAt: matchedAt,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
    lastMessageIsMine: lastMessageIsMine,
    unreadCount: unreadCount ?? this.unreadCount,
    theirLastReadAt: theirLastReadAt,
    avatarPath: avatarPath,
  );

  /// When anything last happened, for sorting newest first.
  DateTime get lastActivity => lastMessageAt ?? matchedAt;
}

/// Something that changed in your matches, pushed live by the server.
///
/// `sealed` means these subclasses are the only kinds there are, so a
/// `switch` over a LiveChange must handle each one (like a TypeScript
/// discriminated union).
sealed class LiveChange {
  const LiveChange();
}

/// A new message in one of your matches (from either side).
class MessageArrived extends LiveChange {
  const MessageArrived({
    required this.matchId,
    required this.senderId,
    required this.body,
  });
  final String matchId;
  final String senderId;
  final String body;
}

/// A new match. [createdBy] is whoever's swipe completed it.
class MatchMade extends LiveChange {
  const MatchMade({required this.matchId, this.createdBy});
  final String matchId;
  final String? createdBy;
}

/// Someone unmatched.
class MatchRemoved extends LiveChange {
  const MatchRemoved();
}

/// Someone read a chat (yours or theirs).
class ReadMarked extends LiveChange {
  const ReadMarked();
}

/// One chat message.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> row) => ChatMessage(
    id: row['id'] as String,
    senderId: row['sender_id'] as String,
    body: row['body'] as String,
    sentAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );

  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
}

/// "14:05" for today, "Yesterday", or a short date like "Oct 12", in the
/// app's language.
String formatMessageTime(DateTime t, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = DateTime(t.year, t.month, t.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final locale = L10n.current.localeName;
  if (day == todayDay) return DateFormat.Hm(locale).format(t);
  if (todayDay.difference(day).inDays == 1) return L10n.current.yesterday;
  return DateFormat.MMMd(locale).format(t);
}

/// "14:05", in the app's language: the time on a chat bubble (the day is
/// shown by the separator above).
String formatClock(DateTime t) =>
    DateFormat.Hm(L10n.current.localeName).format(t);

/// "Today", "Yesterday", "Oct 12", or "Oct 12, 2025" for another year: the
/// separator between days in a chat.
String formatDay(DateTime t, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = DateTime(t.year, t.month, t.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final locale = L10n.current.localeName;
  if (day == todayDay) return L10n.current.today;
  if (todayDay.difference(day).inDays == 1) return L10n.current.yesterday;
  if (t.year == today.year) return DateFormat.MMMd(locale).format(t);
  return DateFormat.yMMMd(locale).format(t);
}
