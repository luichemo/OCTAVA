import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories.dart';

/// Blocking and reporting people.
abstract interface class SafetyRepository {
  Future<void> block(String userId);

  /// [reason] is a `report_reason` value (see reportReasonLabels).
  Future<void> report(String userId, String reason, String details);
}

/// `report_reason` enum → what people see when picking one.
const reportReasonLabels = <String, String>{
  'harassment': 'Harassment or hate',
  'inappropriate': 'Inappropriate messages or content',
  'spam': 'Spam or a scam',
  'fake_profile': 'Fake profile',
  'underage': 'Seems to be under 16',
  'other': 'Something else',
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
      throw const UserFacingException("Couldn't block. Try again.");
    } catch (_) {
      throw const UserFacingException(
        "Couldn't block. Check your connection and try again.",
      );
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
      throw const UserFacingException(
        "Couldn't send your report. Check your connection and try again.",
      );
    }
  }
}
