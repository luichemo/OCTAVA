import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/musician.dart';
import 'profile_options.dart';
import 'repositories.dart';
import 'sample_musicians.dart';

enum Decision { pass, jam }

/// Where the swipe screen gets people and sends swipes.
abstract interface class DeckSource {
  /// Short text for the header, e.g. "Tbilisi, within 10 km".
  String get description;

  Future<List<Musician>> loadDeck();

  /// Records the choice. Returns the match id when it's a match, else null.
  Future<String?> swipe(Musician musician, Decision decision);

  /// Band lineup: role → member name ("You" for yourself), null when open.
  /// Map order is display order.
  Future<Map<String, String?>> loadLineup();
}

/// The 8 sample people, kept in memory. Used by tests and design previews.
class SampleDeck implements DeckSource {
  const SampleDeck({this.musicians = sampleMusicians});

  final List<Musician> musicians;

  @override
  String get description => 'Tbilisi, within 10 km';

  @override
  Future<List<Musician>> loadDeck() async => List.of(musicians);

  @override
  Future<String?> swipe(Musician musician, Decision decision) async =>
      decision == Decision.jam && musician.likesYou
      ? 'sample-${musician.key}'
      : null;

  @override
  Future<Map<String, String?>> loadLineup() async => {
    'Guitar': 'You',
    'Drums': null,
    'Bass': null,
    'Vocals': null,
    'Keys': null,
  };
}

/// Real people and swipes, through the database functions get_deck and
/// record_swipe (see supabase/migrations).
class SupabaseDeck implements DeckSource {
  SupabaseDeck(this._client);
  final SupabaseClient _client;

  static const _roles = ['Vocals', 'Guitar', 'Bass', 'Drums', 'Keys'];

  // No location yet, so the deck isn't limited by distance.
  @override
  String get description => 'Everywhere';

  @override
  Future<List<Musician>> loadDeck() async {
    try {
      final rows =
          await _client.rpc('get_deck', params: {'max_km': null}) as List;
      return [
        for (final row in rows)
          Musician.fromDeckRow(row as Map<String, dynamic>),
      ];
    } catch (_) {
      throw const UserFacingException(
        "Couldn't load musicians. Check your connection and try again.",
      );
    }
  }

  @override
  Future<String?> swipe(Musician musician, Decision decision) async {
    try {
      return await _client.rpc(
        'record_swipe',
        params: {'target': musician.id, 'decision': decision.name},
      ) as String?;
    } catch (_) {
      throw const UserFacingException(
        "Couldn't save that. Check your connection and try again.",
      );
    }
  }

  @override
  Future<Map<String, String?>> loadLineup() async {
    try {
      final me = _client.auth.currentUser!.id;
      final matches = await _client.from('matches').select('user_a, user_b');
      final blocks = await _client.from('blocks').select('blocked_id');
      final blocked = {for (final b in blocks) b['blocked_id'] as String};
      final others = [
        for (final m in matches)
          m['user_a'] == me ? m['user_b'] as String : m['user_a'] as String,
      ].where((id) => !blocked.contains(id));
      // Embeds each person's instruments through the profile_instruments foreign key.
      final people = await _client
          .from('profiles')
          .select(
            'id, display_name, profile_instruments(instrument_id, is_primary)',
          )
          .inFilter('id', [me, ...others]);

      String? roleOf(Map<String, dynamic> person) {
        final list = (person['profile_instruments'] as List)
            .cast<Map<String, dynamic>>();
        final primary =
            list.where((i) => i['is_primary'] == true).firstOrNull ??
            list.firstOrNull;
        return instrumentLabels[primary?['instrument_id']];
      }

      final myRole = roleOf(people.firstWhere((p) => p['id'] == me));
      final band = <String, String?>{
        // An instrument outside the usual five gets its own slot, first.
        if (myRole != null && !_roles.contains(myRole)) myRole: 'You',
        for (final role in _roles) role: role == myRole ? 'You' : null,
      };
      for (final person in people.where((p) => p['id'] != me)) {
        final role = roleOf(person);
        if (role != null && band.containsKey(role) && band[role] == null) {
          band[role] = person['display_name'] as String;
        }
      }
      return band;
    } catch (_) {
      throw const UserFacingException(
        "Couldn't load your band. Check your connection and try again.",
      );
    }
  }
}
