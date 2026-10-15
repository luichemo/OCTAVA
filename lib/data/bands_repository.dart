import 'dart:async';

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/band_group.dart';
import '../models/chat.dart';
import 'clip_repository.dart';
import 'repositories.dart';

/// Bands you're in, invites to join one, and the votes on new members.
/// (Not to be confused with BandNeedsRepository, the roles in your lineup.)
abstract interface class BandsRepository {
  /// The signed-in person's id.
  String get myId;

  Future<BandsState> load();

  /// Creates a band with you as its first member. Returns its id.
  Future<String> create(String name);

  /// Proposes one of your matches. True when the invite went out straight
  /// away (you're the only member), false when it waits for votes.
  Future<bool> propose(String bandId, String candidateId);

  Future<void> vote(String proposalId, {required bool approve});

  Future<void> answerInvite(String proposalId, {required bool accept});

  /// Withdraws a proposal or invite you made.
  Future<void> cancel(String proposalId);

  Future<void> leave(String bandId);

  /// Saves the band's profile. Null leaves a field as it is; an empty
  /// description clears it.
  Future<void> updateProfile(
    String bandId, {
    String? name,
    String? description,
    List<String>? genres,
    List<String>? openRoles,
  });

  /// Uploads (or replaces) the band's clip, checking type, size and length.
  Future<void> uploadClip(
    String bandId, {
    required Uint8List bytes,
    required String fileName,
    int? knownSeconds,
  });

  Future<void> removeClip(String bandId);

  /// A temporary link for playing a band clip.
  Future<String> clipUrl(String path);

  /// A band's messages, oldest first, updated live.
  Stream<List<ChatMessage>> messages(String bandId);

  Future<void> send(String bandId, String body);

  /// Marks a band chat read up to now. Failing quietly is fine.
  Future<void> markRead(String bandId);

  /// Live changes to your bands and their chats.
  Stream<BandChange> changes();
}

class SupabaseBandsRepository implements BandsRepository {
  SupabaseBandsRepository(this._client);
  final SupabaseClient _client;

  @override
  String get myId => _client.auth.currentUser!.id;

  @override
  Future<BandsState> load() async {
    try {
      // Row-level security returns only bands you're in or invited to.
      final bands = await _client
          .from('bands')
          .select(
            'id, name, description, genres, open_roles, clip_path, clip_seconds',
          );
      if (bands.isEmpty) return (bands: <MyBand>[], invites: <BandInvite>[]);
      final bandIds = [for (final b in bands) b['id'] as String];

      final members = await _client
          .from('band_members')
          .select('band_id, profile_id, instrument_id')
          .inFilter('band_id', bandIds)
          .order('joined_at');
      final proposals = await _client
          .from('band_proposals')
          .select('id, band_id, candidate_id, proposed_by, status')
          .inFilter('band_id', bandIds)
          .inFilter('status', ['voting', 'invited'])
          .order('created_at');
      final votes = proposals.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('band_votes')
                .select('proposal_id, voter_id, approve')
                .inFilter('proposal_id', [for (final p in proposals) p['id']]);

      // Chat state for the bands you're in.
      final chatRows = await _client.rpc('my_band_chats') as List;
      final chatOpen = {
        for (final c in chatRows)
          c['band_id'] as String: c['chat_open'] as bool? ?? false,
      };
      final myBandIds = chatOpen.keys.toList();
      final recent = myBandIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('band_messages')
                .select('band_id, sender_id, body, created_at')
                .inFilter('band_id', myBandIds)
                .order('created_at', ascending: false)
                .limit(500);
      final reads = myBandIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('band_reads')
                .select('band_id, user_id, last_read_at')
                .inFilter('band_id', myBandIds);
      DateTime at(Object? v) => DateTime.parse(v as String).toLocal();
      final myRead = {
        for (final r in reads)
          if (r['user_id'] == myId)
            r['band_id'] as String: at(r['last_read_at']),
      };

      final peopleIds = {
        for (final m in members) m['profile_id'] as String,
        for (final p in proposals) p['candidate_id'] as String,
      };
      final people = await _client
          .from('profiles')
          .select(
            'id, display_name, avatar_path, '
            'profile_instruments(instrument_id, is_primary)',
          )
          .inFilter('id', peopleIds.toList());
      final byId = {for (final p in people) p['id'] as String: p};

      BandPerson? person(String? id, {String? instrumentId}) {
        final p = byId[id];
        if (p == null) return null;
        return BandPerson(
          id: id!,
          name: p['display_name'] as String,
          instrumentId: instrumentId ?? _mainInstrument(p),
          avatarPath: p['avatar_path'] as String?,
        );
      }

      List<BandPerson> membersOf(String bandId) => [
        for (final m in members)
          if (m['band_id'] == bandId)
            ?person(
              m['profile_id'] as String,
              instrumentId: m['instrument_id'] as String?,
            ),
      ];

      final myBands = <MyBand>[];
      final invites = <BandInvite>[];
      for (final b in bands) {
        final id = b['id'] as String;
        final inBand = members.any(
          (m) => m['band_id'] == id && m['profile_id'] == myId,
        );
        if (inBand) {
          final latest = recent.where((m) => m['band_id'] == id).firstOrNull;
          final bandMembers = membersOf(id);
          myBands.add(
            MyBand(
              id: id,
              name: b['name'] as String,
              description: b['description'] as String?,
              genres: (b['genres'] as List? ?? const []).cast<String>(),
              openRoles: (b['open_roles'] as List? ?? const []).cast<String>(),
              clipPath: b['clip_path'] as String?,
              clipSeconds: b['clip_seconds'] as int?,
              members: bandMembers,
              chatOpen: chatOpen[id] ?? false,
              unreadCount: recent.where((m) {
                if (m['band_id'] != id || m['sender_id'] == myId) return false;
                final read = myRead[id];
                return read == null || at(m['created_at']).isAfter(read);
              }).length,
              lastMessage: latest == null
                  ? null
                  : BandMessagePreview(
                      senderId: latest['sender_id'] as String,
                      senderName:
                          bandMembers
                              .where((p) => p.id == latest['sender_id'])
                              .firstOrNull
                              ?.name ??
                          L10n.current.musicianFallback,
                      body: latest['body'] as String,
                      sentAt: at(latest['created_at']),
                    ),
              readMarks: {
                for (final r in reads)
                  if (r['band_id'] == id && r['user_id'] != myId)
                    r['user_id'] as String: at(r['last_read_at']),
              },
              proposals: [
                for (final p in proposals)
                  if (p['band_id'] == id)
                    if (person(p['candidate_id'] as String) case final c?)
                      BandProposal(
                        id: p['id'] as String,
                        candidate: c,
                        proposedBy: person(p['proposed_by'] as String?),
                        invited: p['status'] == 'invited',
                        approvedBy: {
                          for (final v in votes)
                            if (v['proposal_id'] == p['id'] &&
                                v['approve'] == true)
                              v['voter_id'] as String,
                        },
                      ),
              ],
            ),
          );
        } else {
          final invite = proposals
              .where((p) => p['band_id'] == id && p['candidate_id'] == myId)
              .firstOrNull;
          if (invite == null) continue;
          invites.add(
            BandInvite(
              proposalId: invite['id'] as String,
              bandId: id,
              bandName: b['name'] as String,
              members: membersOf(id),
            ),
          );
        }
      }
      return (bands: myBands, invites: invites);
    } catch (_) {
      throw UserFacingException(L10n.current.errBandLoad);
    }
  }

  @override
  Future<String> create(String name) =>
      _call('create_band', {'name': name.trim()}).then((id) => id as String);

  @override
  Future<bool> propose(String bandId, String candidateId) async {
    final proposalId = await _call('propose_band_member', {
      'band': bandId,
      'candidate': candidateId,
    });
    try {
      final row = await _client
          .from('band_proposals')
          .select('status')
          .eq('id', proposalId as String)
          .single();
      return row['status'] == 'invited';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> vote(String proposalId, {required bool approve}) =>
      _call('vote_band_member', {'proposal': proposalId, 'approve': approve});

  @override
  Future<void> answerInvite(String proposalId, {required bool accept}) =>
      _call('answer_band_invite', {'proposal': proposalId, 'accept': accept});

  @override
  Future<void> cancel(String proposalId) =>
      _call('cancel_band_proposal', {'proposal': proposalId});

  @override
  Future<void> leave(String bandId) => _call('leave_band', {'band': bandId});

  Future<dynamic> _call(String fn, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw UserFacingException(bandErrorMessage(e.message));
    } catch (_) {
      throw UserFacingException(L10n.current.errBandAction);
    }
  }

  @override
  Future<void> updateProfile(
    String bandId, {
    String? name,
    String? description,
    List<String>? genres,
    List<String>? openRoles,
  }) => _call('update_band', {
    'band': bandId,
    'name': name?.trim(),
    'description': description,
    'genres': genres,
    'open_roles': openRoles,
  });

  StorageFileApi get _clips => _client.storage.from('band-clips');

  @override
  Future<void> uploadClip(
    String bandId, {
    required Uint8List bytes,
    required String fileName,
    int? knownSeconds,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final mime = clipMimeTypes[ext];
    if (mime == null) throw UserFacingException(L10n.current.errClipType);
    if (bytes.length > maxClipBytes) {
      throw UserFacingException(L10n.current.errClipSize);
    }
    final path = '$bandId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _clips.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime),
      );
    } catch (_) {
      throw UserFacingException(L10n.current.errClipUpload);
    }
    Future<void> discard() =>
        _clips.remove([path]).catchError((_) => <FileObject>[]);
    final seconds =
        knownSeconds ?? await measureClipSeconds(await clipUrl(path));
    if (seconds == null || seconds > maxClipSeconds) {
      await discard();
      throw UserFacingException(
        seconds == null
            ? L10n.current.errClipUnreadable
            : L10n.current.errClipTooLong(clipLength(seconds)),
      );
    }
    final old = await _currentClip(bandId);
    try {
      await _call('set_band_clip', {
        'band': bandId,
        'path': path,
        'seconds': seconds,
      });
    } catch (_) {
      await discard();
      rethrow;
    }
    // The previous clip's file isn't needed any more.
    if (old != null) {
      await _clips.remove([old]).catchError((_) => <FileObject>[]);
    }
  }

  @override
  Future<void> removeClip(String bandId) async {
    final old = await _currentClip(bandId);
    await _call('set_band_clip', {
      'band': bandId,
      'path': null,
      'seconds': null,
    });
    if (old != null) {
      await _clips.remove([old]).catchError((_) => <FileObject>[]);
    }
  }

  Future<String?> _currentClip(String bandId) async {
    try {
      final row = await _client
          .from('bands')
          .select('clip_path')
          .eq('id', bandId)
          .single();
      return row['clip_path'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> clipUrl(String path) async {
    try {
      return await _clips.createSignedUrl(path, 60 * 60);
    } catch (_) {
      throw UserFacingException(L10n.current.errClipPlay);
    }
  }

  @override
  Stream<List<ChatMessage>> messages(String bandId) => _client
      .from('band_messages')
      .stream(primaryKey: ['id'])
      .eq('band_id', bandId)
      .order('created_at', ascending: true)
      .map((rows) => [for (final row in rows) ChatMessage.fromRow(row)]);

  @override
  Future<void> send(String bandId, String body) async {
    try {
      await _client.from('band_messages').insert({
        'band_id': bandId,
        'body': body.trim(),
      });
    } on PostgrestException catch (e) {
      // 42501: the chat is closed (too few members, or you left).
      if (e.code == '42501') {
        throw UserFacingException(L10n.current.errBandSendClosed);
      }
      throw UserFacingException(L10n.current.errSend);
    } catch (_) {
      throw UserFacingException(L10n.current.errSendOffline);
    }
  }

  @override
  Future<void> markRead(String bandId) async {
    try {
      await _client.from('band_reads').upsert({
        'band_id': bandId,
        'user_id': myId,
      });
    } catch (_) {
      // The next open marks it again.
    }
  }

  @override
  Stream<BandChange> changes() {
    late final RealtimeChannel channel;
    final out = StreamController<BandChange>(
      onCancel: () => _client.removeChannel(channel),
    );
    void add(BandChange change) {
      if (!out.isClosed) out.add(change);
    }

    channel = _client.channel('bands-$myId');
    for (final table in const [
      'bands',
      'band_members',
      'band_proposals',
      'band_votes',
      'band_reads',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => add(const BandsChanged()),
      );
    }
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'band_messages',
      callback: (payload) => add(
        BandMessageArrived(
          bandId: payload.newRecord['band_id'] as String,
          senderId: payload.newRecord['sender_id'] as String,
          body: payload.newRecord['body'] as String,
        ),
      ),
    );
    channel.subscribe();
    return out.stream;
  }

  static String? _mainInstrument(Map<String, dynamic> person) {
    final list = (person['profile_instruments'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final primary =
        list.where((i) => i['is_primary'] == true).firstOrNull ??
        list.firstOrNull;
    return primary?['instrument_id'] as String?;
  }
}

/// How a band clip is named to the session's ClipPlayer, which also plays
/// people's clips from another bucket: `band:<path>`.
String bandClipKey(String path) => '$_bandClipPrefix$path';

const _bandClipPrefix = 'band:';

/// The band-clips path inside a [bandClipKey], or null for a person's clip.
String? bandClipPath(String key) => key.startsWith(_bandClipPrefix)
    ? key.substring(_bandClipPrefix.length)
    : null;

/// The database's band rules answer in English (see the bands migration);
/// this turns each one into the app's language.
String bandErrorMessage(String serverMessage) {
  final t = L10n.current;
  final m = serverMessage.toLowerCase();
  if (m.contains('matched with')) return t.errBandNotMatched;
  if (m.contains('already in the band')) return t.errBandAlreadyIn;
  if (m.contains('already been proposed')) return t.errBandAlreadyProposed;
  if (m.contains('at most 12') || m.contains('band is full')) {
    return t.errBandFull;
  }
  if (m.contains('at most 10 bands')) return t.errBandTooMany;
  if (m.contains('another age group')) return t.errBandAgeRule;
  if (m.contains('isn\'t available')) return t.errBandUnavailable;
  if (m.contains('vote on this person is over')) return t.errBandVoteOver;
  if (m.contains('invite isn\'t open')) return t.errBandInviteClosed;
  if (m.contains('not in this band')) return t.errBandNotMember;
  if (m.contains('who proposed them can cancel')) {
    return t.errBandCancelNotYours;
  }
  if (m.contains('profile first')) return t.errBandNeedsProfile;
  if (m.contains('genres from the list') || m.contains('instruments from')) {
    return t.errBandProfile;
  }
  return t.errBandAction;
}
