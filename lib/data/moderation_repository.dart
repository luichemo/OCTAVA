import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/musician.dart';
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
    this.evidence = const [],
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
    evidence: [
      for (final e
          in (r['evidence'] as List? ?? const []).cast<Map<String, dynamic>>())
        ModEvidence.fromJson(e),
    ],
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

  /// For one-on-one reports: the reported person's last 20 messages to the
  /// reporter, oldest first, copied by the server when the report was filed.
  final List<ModEvidence> evidence;
}

/// One message in a report's evidence.
class ModEvidence {
  const ModEvidence({required this.at, this.body, this.voiceSeconds});

  factory ModEvidence.fromJson(Map<String, dynamic> e) => ModEvidence(
    at: DateTime.parse(e['at'] as String).toLocal(),
    body: e['body'] as String?,
    voiceSeconds: e['voice'] == true ? (e['seconds'] as int? ?? 0) : null,
  );

  final DateTime at;
  final String? body;

  /// Set for voice messages (their length); the audio itself isn't copied.
  final int? voiceSeconds;
  bool get isVoice => voiceSeconds != null;
}

/// A reported person's card, for moderators (from `mod_profile`).
class ModProfile {
  const ModProfile({required this.card, this.joinedAt, this.suspended = false});

  factory ModProfile.fromJson(Map<String, dynamic> j) => ModProfile(
    card: Musician.fromDeckRow(j),
    joinedAt: j['joined_at'] == null
        ? null
        : DateTime.parse(j['joined_at'] as String).toLocal(),
    suspended: j['suspended'] as bool? ?? false,
  );

  final Musician card;
  final DateTime? joinedAt;
  final bool suspended;
}

/// Someone in the admin's Moderators page: a current moderator, or a
/// search result (from `admin_moderators` / `admin_find_people`).
class ModPerson {
  const ModPerson({
    required this.id,
    required this.name,
    this.avatarPath,
    this.instrumentId,
    this.age,
    this.isModerator = false,
    this.isAdmin = false,
    this.suspended = false,
  });

  final String id;
  final String name;
  final String? avatarPath;
  final String? instrumentId;
  final int? age;
  final bool isModerator;

  /// Admins stay moderators; the app doesn't offer to remove them.
  final bool isAdmin;
  final bool suspended;
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

  /// The person's card (any age group); null if the account is gone.
  Future<ModProfile?> profile(String personId);

  /// Whether you're an admin (then the profile page shows Moderators).
  Future<bool> isAdmin();

  /// Admins only: current moderators, admins first.
  Future<List<ModPerson>> moderators();

  /// Admins only: accounts whose name contains [query] (2+ letters), up to 20.
  Future<List<ModPerson>> findPeople(String query);

  /// Admins only: makes someone a moderator, or stops them being one.
  Future<void> setModerator(String personId, bool make);
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

  @override
  Future<bool> isAdmin() async {
    try {
      final rows = await _client
          .from('admins')
          .select('profile_id')
          .eq('profile_id', _client.auth.currentUser!.id)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ModPerson>> moderators() async {
    try {
      final rows = await _client.rpc('admin_moderators') as List;
      return [
        for (final r in rows.cast<Map<String, dynamic>>())
          ModPerson(
            id: r['id'] as String,
            name: r['display_name'] as String? ?? '?',
            avatarPath: r['avatar_path'] as String?,
            instrumentId: r['instrument_id'] as String?,
            isModerator: true,
            isAdmin: r['is_admin'] as bool? ?? false,
          ),
      ];
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }

  @override
  Future<List<ModPerson>> findPeople(String query) async {
    try {
      final rows = await _client.rpc(
        'admin_find_people',
        params: {'query': query},
      ) as List;
      return [
        for (final r in rows.cast<Map<String, dynamic>>())
          ModPerson(
            id: r['id'] as String,
            name: r['display_name'] as String? ?? '?',
            avatarPath: r['avatar_path'] as String?,
            instrumentId: r['instrument_id'] as String?,
            age: r['age'] as int?,
            isModerator: r['is_moderator'] as bool? ?? false,
            suspended: r['suspended'] as bool? ?? false,
          ),
      ];
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }

  @override
  Future<void> setModerator(String personId, bool make) async {
    try {
      await _client.rpc(
        'admin_set_moderator',
        params: {'person': personId, 'make': make},
      );
    } on PostgrestException catch (e) {
      throw UserFacingException(
        e.message.contains('suspended')
            ? L10n.current.errModSuspendedCant
            : e.message.contains('admin stays')
            ? L10n.current.errModAdminStays
            : L10n.current.errModeration,
      );
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }

  @override
  Future<ModProfile?> profile(String personId) async {
    try {
      final row = await _client.rpc(
        'mod_profile',
        params: {'person': personId},
      );
      if (row == null) return null;
      return ModProfile.fromJson(row as Map<String, dynamic>);
    } catch (_) {
      throw UserFacingException(L10n.current.errModeration);
    }
  }
}
