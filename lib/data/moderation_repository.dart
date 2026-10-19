import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import 'repositories.dart';

/// An open report, as moderators see it (from `mod_reports()`).
class ModReport {
  const ModReport({
    required this.id,
    required this.createdAt,
    required this.reason,
    required this.reportedId,
    this.reportedName,
    this.reporterName,
    this.details,
    this.reportedText,
    this.messageStillThere = false,
    this.reportedSuspended = false,
    this.openAgainst = 1,
  });

  factory ModReport.fromRow(Map<String, dynamic> r) => ModReport(
    id: r['id'] as String,
    createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    reason: r['reason'] as String,
    reportedId: r['reported_id'] as String,
    reportedName: r['reported_name'] as String?,
    reporterName: r['reporter_name'] as String?,
    details: r['details'] as String?,
    reportedText: r['reported_text'] as String?,
    messageStillThere: r['message_still_there'] as bool? ?? false,
    reportedSuspended: r['reported_suspended'] as bool? ?? false,
    openAgainst: r['open_against'] as int? ?? 1,
  );

  final String id;
  final DateTime createdAt;

  /// A `report_reason` value (see reportReasonLabels).
  final String reason;
  final String reportedId;
  final String? reportedName;
  final String? reporterName;
  final String? details;

  /// The reported band message's text, when a message was reported.
  final String? reportedText;

  /// Whether that message still exists (so it can be removed).
  final bool messageStillThere;
  final bool reportedSuspended;

  /// Open reports against the same person, this one included.
  final int openAgainst;
}

/// What a moderator can do with a report.
enum ModAction { dismiss, removeMessage, suspend }

/// Reviewing reports. Only moderators (the `moderators` table) can use it;
/// the database refuses everyone else.
abstract interface class ModerationRepository {
  /// Whether you're a moderator (then the profile page shows Reports).
  Future<bool> isModerator();

  /// Open reports, newest first.
  Future<List<ModReport>> openReports();

  Future<void> resolve(String reportId, ModAction action, {String? note});

  Future<void> unsuspend(String personId);
}

class SupabaseModeration implements ModerationRepository {
  SupabaseModeration(this._client);
  final SupabaseClient _client;

  @override
  Future<bool> isModerator() async {
    try {
      final rows = await _client
          .from('moderators')
          .select('profile_id')
          .eq('profile_id', _client.auth.currentUser!.id)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ModReport>> openReports() async {
    try {
      final rows = await _client.rpc('mod_reports') as List;
      return [
        for (final r in rows) ModReport.fromRow(r as Map<String, dynamic>),
      ];
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }

  @override
  Future<void> resolve(
    String reportId,
    ModAction action, {
    String? note,
  }) async {
    try {
      await _client.rpc(
        'mod_resolve_report',
        params: {
          'report': reportId,
          'action': switch (action) {
            ModAction.dismiss => 'dismiss',
            ModAction.removeMessage => 'remove_message',
            ModAction.suspend => 'suspend',
          },
          'note': note,
        },
      );
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }

  @override
  Future<void> unsuspend(String personId) async {
    try {
      await _client.rpc('mod_unsuspend', params: {'person': personId});
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }
}
