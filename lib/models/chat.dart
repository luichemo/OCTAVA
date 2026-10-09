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
  });

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

  /// When anything last happened, for sorting newest first.
  DateTime get lastActivity => lastMessageAt ?? matchedAt;
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
