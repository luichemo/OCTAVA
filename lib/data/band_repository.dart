import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import 'repositories.dart';

/// The roles your band needs: instrument id → how many, in display order.
abstract interface class BandNeedsRepository {
  /// Null while you haven't chosen yet (then `defaultBandNeeds` applies).
  Future<Map<String, int>?> load();

  /// Replaces all your roles. [needs] must have at least one role.
  Future<void> save(Map<String, int> needs);
}

/// Kept in memory only: for tests and the sample deck.
class MemoryBandNeeds implements BandNeedsRepository {
  MemoryBandNeeds([this.needs]);

  Map<String, int>? needs;

  @override
  Future<Map<String, int>?> load() async => needs == null ? null : {...needs!};

  @override
  Future<void> save(Map<String, int> needs) async => this.needs = {...needs};
}

/// The `band_roles` table (own rows only, by RLS).
class SupabaseBandNeeds implements BandNeedsRepository {
  SupabaseBandNeeds(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, int>?> load() async {
    try {
      final rows = await _client
          .from('band_roles')
          .select('instrument_id, slots')
          .order('sort_order');
      if (rows.isEmpty) return null;
      return {
        for (final r in rows) r['instrument_id'] as String: r['slots'] as int,
      };
    } catch (_) {
      throw UserFacingException(L10n.current.errLoadBand);
    }
  }

  @override
  Future<void> save(Map<String, int> needs) async {
    final me = _client.auth.currentUser!.id;
    try {
      // Delete then insert, like profile_instruments. The database checks
      // the limits (1–4 of a role, 8 in total).
      await _client.from('band_roles').delete().eq('profile_id', me);
      await _client.from('band_roles').insert([
        for (final (i, MapEntry(key: role, value: count))
            in needs.entries.indexed)
          {
            'profile_id': me,
            'instrument_id': role,
            'slots': count,
            'sort_order': i,
          },
      ]);
    } catch (_) {
      throw UserFacingException(L10n.current.errSaveBand);
    }
  }
}
