import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories.dart';
import '../l10n/l10n.dart';

/// Blocking and reporting people.
abstract interface class SafetyRepository {
  Future<void> block(String userId);

  /// [reason] is a `report_reason` value (see reportReasonLabels).
  Future<void> report(String userId, String reason, String details);
}

/// `report_reason` enum → what people see when picking one.
Map<String, String> get reportReasonLabels => {
  'harassment': L10n.current.reasonHarassment,
  'inappropriate': L10n.current.reasonInappropriate,
  'spam': L10n.current.reasonSpam,
  'fake_profile': L10n.current.reasonFake,
  'underage': L10n.current.reasonUnderage,
  'other': L10n.current.reasonOther,
};

class SupabaseSafetyRepository implements SafetyRepository {
  SupabaseSafetyRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> block(String userId) async {
    try {
      // blocker_id defaults to the signed-in user in the database.
      await _client.from('blocks').insert({'blocked_id': userId});
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // already blocked
      throw UserFacingException(L10n.current.errBlock);
    } catch (_) {
      throw UserFacingException(L10n.current.errBlockOffline);
    }
  }

  @override
  Future<void> report(String userId, String reason, String details) async {
    try {
      await _client.from('reports').insert({
        'reported_id': userId,
        'reason': reason,
        if (details.trim().isNotEmpty) 'details': details.trim(),
      });
    } catch (_) {
      throw UserFacingException(L10n.current.errReport);
    }
  }
}
