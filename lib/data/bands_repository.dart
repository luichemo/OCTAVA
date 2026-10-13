import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/band_group.dart';
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

  /// Fires whenever a band, member, proposal or vote you can see changes.
  Stream<void> changes();
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
      final bands = await _client.from('bands').select('id, name');
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
          myBands.add(
            MyBand(
              id: id,
              name: b['name'] as String,
              members: membersOf(id),
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
  Stream<void> changes() {
    late final RealtimeChannel channel;
    final out = StreamController<void>(
      onCancel: () => _client.removeChannel(channel),
    );
    channel = _client.channel('bands-$myId');
    for (final table in const [
      'bands',
      'band_members',
      'band_proposals',
      'band_votes',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          if (!out.isClosed) out.add(null);
        },
      );
    }
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
  return t.errBandAction;
}
