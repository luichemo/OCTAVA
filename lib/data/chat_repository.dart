import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';
import 'clip_repository.dart';
import 'profile_options.dart';
import 'repositories.dart';
import '../l10n/l10n.dart';

/// Matches and one-on-one messages.
abstract interface class ChatRepository {
  /// The signed-in person's id, to tell your messages from theirs.
  String get myId;

  /// Your matches, newest activity first.
  Future<List<MatchSummary>> loadMatches();

  /// All messages in a match, oldest first, updated live as new ones arrive.
  Stream<List<ChatMessage>> messages(String matchId);

  Future<void> send(String matchId, String body);

  /// Uploads a voice recording and posts it in the match.
  Future<void> sendVoice(
    String matchId, {
    required Uint8List bytes,
    required String fileName,
    required int seconds,
  });

  /// Changes the text of your own message (within 15 minutes).
  Future<void> edit(String messageId, String body);

  /// A temporary link for playing a voice message (one-on-one or band).
  Future<String> voiceUrl(String path);

  /// Marks a chat read up to now (for unread counts and their "Seen").
  /// Failing quietly is fine: it's retried the next time.
  Future<void> markRead(String matchId);

  /// Deletes the match (and its chat) for both people.
  Future<void> unmatch(String matchId);

  /// Live changes to your matches, messages and read marks, until the
  /// subscription is cancelled.
  Stream<LiveChange> changes();
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
            'id, display_name, avatar_path, '
            'profile_instruments(instrument_id, is_primary)',
          )
          .inFilter('id', matches.map(otherOf).toList());
      final byId = {for (final p in people) p['id'] as String: p};
      final blocked = await _blockedIds(_client);

      // Newest first, so the first message seen per match is its latest.
      final recent = await _client
          .from('messages')
          .select('match_id, sender_id, body, audio_path, created_at')
          .inFilter('match_id', [for (final m in matches) m['id']])
          .order('created_at', ascending: false)
          .limit(500);
      final latest = <String, Map<String, dynamic>>{};
      for (final msg in recent) {
        latest.putIfAbsent(msg['match_id'] as String, () => msg);
      }

      // Read marks: yours for unread counts, theirs for "Seen".
      final reads = await _client
          .from('match_reads')
          .select('match_id, user_id, last_read_at')
          .inFilter('match_id', [for (final m in matches) m['id']]);
      final myRead = <String, DateTime>{};
      final theirRead = <String, DateTime>{};
      for (final r in reads) {
        final at = DateTime.parse(r['last_read_at'] as String).toLocal();
        (r['user_id'] == myId ? myRead : theirRead)[r['match_id'] as String] =
            at;
      }
      int unreadIn(String matchId) => recent.where((msg) {
        if (msg['match_id'] != matchId || msg['sender_id'] == myId) {
          return false;
        }
        final read = myRead[matchId];
        return read == null ||
            DateTime.parse(msg['created_at'] as String).toLocal().isAfter(read);
      }).length;

      final summaries = <MatchSummary>[];
      for (final m in matches) {
        // Someone may have deleted their profile since matching.
        final person = byId[otherOf(m)];
        if (person == null || blocked.contains(otherOf(m))) continue;
        final last = latest[m['id']];
        summaries.add(
          MatchSummary(
            matchId: m['id'] as String,
            otherUserId: otherOf(m),
            name: person['display_name'] as String,
            instrument: _mainInstrument(person),
            matchedAt: DateTime.parse(m['created_at'] as String).toLocal(),
            lastMessage: last == null
                ? null
                : messagePreview(last['body'] as String?),
            lastMessageAt: last == null
                ? null
                : DateTime.parse(last['created_at'] as String).toLocal(),
            lastMessageIsMine: last?['sender_id'] == myId,
            unreadCount: unreadIn(m['id'] as String),
            theirLastReadAt: theirRead[m['id']],
            avatarPath: person['avatar_path'] as String?,
          ),
        );
      }
      summaries.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      return summaries;
    } catch (_) {
      throw UserFacingException(L10n.current.errLoadMatches);
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
        throw UserFacingException(L10n.current.errSendBlocked);
      }
      throw UserFacingException(L10n.current.errSend);
    } catch (_) {
      throw UserFacingException(L10n.current.errSendOffline);
    }
  }

  @override
  Future<void> sendVoice(
    String matchId, {
    required Uint8List bytes,
    required String fileName,
    required int seconds,
  }) => uploadVoice(
    _client,
    folder: 'm/$matchId',
    bytes: bytes,
    fileName: fileName,
    seconds: seconds,
    insert: (path) => _client.from('messages').insert({
      'match_id': matchId,
      'audio_path': path,
      'audio_seconds': seconds,
    }),
  );

  @override
  Future<void> edit(String messageId, String body) =>
      editMessageRpc(_client, 'edit_message', messageId, body);

  @override
  Future<String> voiceUrl(String path) async {
    try {
      return await _client.storage.from('voice').createSignedUrl(path, 3600);
    } catch (_) {
      throw UserFacingException(L10n.current.errClipPlay);
    }
  }

  @override
  Future<void> markRead(String matchId) async {
    try {
      // The server sets last_read_at to its own clock (trigger).
      await _client.from('match_reads').upsert({
        'match_id': matchId,
        'user_id': myId,
      });
    } catch (_) {
      // Not worth bothering anyone; the next open marks it again.
    }
  }

  @override
  Future<void> unmatch(String matchId) async {
    try {
      // RLS lets either person delete; messages and read marks cascade.
      await _client.from('matches').delete().eq('id', matchId);
    } catch (_) {
      throw UserFacingException(L10n.current.errUnmatch);
    }
  }

  @override
  Stream<LiveChange> changes() {
    // One Realtime channel per listener. Row-level security decides which
    // rows reach us, so only your own matches' changes arrive (except
    // deletes, which Realtime sends to everyone with the id only).
    late final RealtimeChannel channel;
    final out = StreamController<LiveChange>(
      onCancel: () => _client.removeChannel(channel),
    );
    void on(
      String table,
      PostgresChangeEvent event,
      LiveChange? Function(Map<String, dynamic> row) toChange,
    ) {
      channel.onPostgresChanges(
        event: event,
        schema: 'public',
        table: table,
        callback: (payload) {
          final change = toChange(payload.newRecord);
          if (change != null && !out.isClosed) out.add(change);
        },
      );
    }

    channel = _client.channel('live-$myId');
    on(
      'messages',
      PostgresChangeEvent.insert,
      (row) => MessageArrived(
        matchId: row['match_id'] as String,
        senderId: row['sender_id'] as String,
        body: messagePreview(row['body'] as String?),
      ),
    );
    on(
      'matches',
      PostgresChangeEvent.insert,
      (row) => MatchMade(
        matchId: row['id'] as String,
        createdBy: row['created_by'] as String?,
      ),
    );
    on('matches', PostgresChangeEvent.delete, (_) => const MatchRemoved());
    on('match_reads', PostgresChangeEvent.all, (_) => const ReadMarked());
    // An edited message: reload, so the Matches preview shows the new text.
    on('messages', PostgresChangeEvent.update, (_) => const ReadMarked());
    channel.subscribe();
    return out.stream;
  }

  static String _mainInstrument(Map<String, dynamic> person) {
    final list = (person['profile_instruments'] as List)
        .cast<Map<String, dynamic>>();
    final primary =
        list.where((i) => i['is_primary'] == true).firstOrNull ??
        list.firstOrNull;
    return instrumentLabels[primary?['instrument_id']] ??
        L10n.current.musicianFallback;
  }
}

/// How a voice message is named to the session's ClipPlayer:
/// `voice:<path>`. ProfileGate resolves it with [ChatRepository.voiceUrl].
String voiceKey(String path) => '$_voicePrefix$path';

const _voicePrefix = 'voice:';

/// The voice-bucket path inside a [voiceKey], or null for other clips.
String? voicePath(String key) =>
    key.startsWith(_voicePrefix) ? key.substring(_voicePrefix.length) : null;

/// Uploads a voice recording to `voice/<folder>/<millis>.<ext>`, then
/// [insert]s the message row. The file is removed again if posting fails.
/// A refusal from the rules (blocked, age rule, closed band chat) becomes
/// errSendBlocked.
Future<void> uploadVoice(
  SupabaseClient client, {
  required String folder,
  required Uint8List bytes,
  required String fileName,
  required int seconds,
  required Future<void> Function(String path) insert,
}) async {
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : 'm4a';
  final mime = clipMimeTypes[ext] ?? 'audio/mp4';
  final path = '$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
  final bucket = client.storage.from('voice');
  try {
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mime),
    );
  } on StorageException {
    throw UserFacingException(L10n.current.errSendBlocked);
  } catch (_) {
    throw UserFacingException(L10n.current.errSendOffline);
  }
  try {
    await insert(path);
  } catch (e) {
    await bucket.remove([path]).catchError((_) => <FileObject>[]);
    if (e is PostgrestException && e.code == '42501') {
      throw UserFacingException(L10n.current.errSendBlocked);
    }
    throw UserFacingException(L10n.current.errSend);
  }
}

/// Calls an edit function and explains its refusals.
Future<void> editMessageRpc(
  SupabaseClient client,
  String fn,
  String messageId,
  String body,
) async {
  try {
    await client.rpc(fn, params: {'message': messageId, 'body': body.trim()});
  } on PostgrestException catch (e) {
    final m = e.message.toLowerCase();
    throw UserFacingException(
      m.contains('15 minutes')
          ? L10n.current.errEditTooLate
          : m.contains('send messages in this chat')
          ? L10n.current.errSendBlocked
          : L10n.current.errEdit,
    );
  } catch (_) {
    throw UserFacingException(L10n.current.errSendOffline);
  }
}

/// Ids of people the signed-in user has blocked.
Future<Set<String>> _blockedIds(SupabaseClient client) async {
  final rows = await client.from('blocks').select('blocked_id');
  return {for (final r in rows) r['blocked_id'] as String};
}
