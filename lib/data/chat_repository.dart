import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';
import 'profile_options.dart';
import 'repositories.dart';

/// Matches and one-on-one messages.
abstract interface class ChatRepository {
  /// The signed-in person's id, to tell your messages from theirs.
  String get myId;

  /// Your matches, newest activity first.
  Future<List<MatchSummary>> loadMatches();

  /// All messages in a match, oldest first, updated live as new ones arrive.
  Stream<List<ChatMessage>> messages(String matchId);

  Future<void> send(String matchId, String body);
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);
  final SupabaseClient _client;

  @override
  String get myId => _client.auth.currentUser!.id;

  @override
  Future<List<MatchSummary>> loadMatches() async {
    try {
      final matches = await _client
          .from('matches')
          .select('id, user_a, user_b, created_at');
      if (matches.isEmpty) return [];

      String otherOf(Map<String, dynamic> m) =>
          (m['user_a'] == myId ? m['user_b'] : m['user_a']) as String;
      final people = await _client
          .from('profiles')
          .select(
            'id, display_name, profile_instruments(instrument_id, is_primary)',
          )
          .inFilter('id', matches.map(otherOf).toList());
      final byId = {for (final p in people) p['id'] as String: p};

      // Newest first, so the first message seen per match is its latest.
      final recent = await _client
          .from('messages')
          .select('match_id, sender_id, body, created_at')
          .inFilter('match_id', [for (final m in matches) m['id']])
          .order('created_at', ascending: false)
          .limit(500);
      final latest = <String, Map<String, dynamic>>{};
      for (final msg in recent) {
        latest.putIfAbsent(msg['match_id'] as String, () => msg);
      }

      final summaries = <MatchSummary>[];
      for (final m in matches) {
        // Someone may have deleted their profile since matching.
        final person = byId[otherOf(m)];
        if (person == null) continue;
        final last = latest[m['id']];
        summaries.add(
          MatchSummary(
            matchId: m['id'] as String,
            name: person['display_name'] as String,
            instrument: _mainInstrument(person),
            matchedAt: DateTime.parse(m['created_at'] as String).toLocal(),
            lastMessage: last?['body'] as String?,
            lastMessageAt: last == null
                ? null
                : DateTime.parse(last['created_at'] as String).toLocal(),
            lastMessageIsMine: last?['sender_id'] == myId,
          ),
        );
      }
      summaries.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      return summaries;
    } catch (_) {
      throw const UserFacingException(
        "Couldn't load your matches. Check your connection and try again.",
      );
    }
  }

  @override
  Stream<List<ChatMessage>> messages(String matchId) => _client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('match_id', matchId)
      .order('created_at', ascending: true)
      .map((rows) => [for (final row in rows) ChatMessage.fromRow(row)]);

  @override
  Future<void> send(String matchId, String body) async {
    try {
      await _client.from('messages').insert({
        'match_id': matchId,
        'body': body.trim(),
      });
    } on PostgrestException catch (e) {
      // 42501: the row-level rules refused it (blocked, unmatched, or the
      // age rule after a birthday).
      if (e.code == '42501') {
        throw const UserFacingException(
          "You can't send messages in this chat anymore.",
        );
      }
      throw const UserFacingException("Couldn't send your message. Try again.");
    } catch (_) {
      throw const UserFacingException(
        "Couldn't send your message. Check your connection and try again.",
      );
    }
  }

  static String _mainInstrument(Map<String, dynamic> person) {
    final list = (person['profile_instruments'] as List)
        .cast<Map<String, dynamic>>();
    final primary =
        list.where((i) => i['is_primary'] == true).firstOrNull ??
        list.firstOrNull;
    return instrumentLabels[primary?['instrument_id']] ?? 'Musician';
  }
}
