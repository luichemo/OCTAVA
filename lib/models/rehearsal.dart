/// A rehearsal as saved: once, or every week from [startsAt] (until
/// [repeatUntil], or open-ended).
class Rehearsal {
  const Rehearsal({
    required this.id,
    required this.bandId,
    required this.startsAt,
    this.durationMinutes = 120,
    this.place,
    this.notes,
    this.weekly = false,
    this.repeatUntil,
  });

  factory Rehearsal.fromRow(Map<String, dynamic> row) => Rehearsal(
    id: row['id'] as String,
    bandId: row['band_id'] as String,
    startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
    durationMinutes: row['duration_minutes'] as int? ?? 120,
    place: row['place'] as String?,
    notes: row['notes'] as String?,
    weekly: row['weekly'] as bool? ?? false,
    repeatUntil: switch (row['repeat_until']) {
      final String d => DateTime.parse(d),
      _ => null,
    },
  );

  final String id;
  final String bandId;

  /// The first (or only) time it starts, in local time.
  final DateTime startsAt;
  final int durationMinutes;
  final String? place;
  final String? notes;
  final bool weekly;

  /// The last day a weekly rehearsal can fall on; null means no end.
  final DateTime? repeatUntil;
}

/// What a member enters in the rehearsal form.
typedef RehearsalDraft = ({
  DateTime startsAt,
  int durationMinutes,
  String place,
  String notes,
  bool weekly,
  DateTime? repeatUntil,
});

/// One date of a rehearsal: when it starts, whether it's called off, and
/// who's coming.
class RehearsalDate {
  const RehearsalDate({
    required this.rehearsal,
    required this.startsAt,
    this.cancelled = false,
    this.answers = const {},
  });

  final Rehearsal rehearsal;
  final DateTime startsAt;

  /// A single date of a weekly rehearsal can be called off.
  final bool cancelled;

  /// Member id → going (true) or can't (false). Missing: no answer yet.
  final Map<String, bool> answers;

  DateTime get endsAt =>
      startsAt.add(Duration(minutes: rehearsal.durationMinutes));

  /// The calendar day, as the database stores it (`occurs_on`).
  DateTime get day => DateTime(startsAt.year, startsAt.month, startsAt.day);

  int get going => answers.values.where((g) => g).length;
  int get cant => answers.values.where((g) => !g).length;
}

/// "2026-10-23", for `occurs_on`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Every date of [rehearsals] that hasn't ended by [from] and starts before
/// [until], soonest first. Weekly rehearsals keep their local start time
/// (so 19:00 stays 19:00 across daylight-saving changes).
List<RehearsalDate> rehearsalDates(
  List<Rehearsal> rehearsals, {
  required DateTime from,
  required DateTime until,
  Map<(String, String), bool> cancelled = const {},
  Map<(String, String), Map<String, bool>> answers = const {},
}) {
  final out = <RehearsalDate>[];
  for (final r in rehearsals) {
    final first = r.startsAt;
    for (var week = 0; ; week++) {
      // DateTime's constructor with day + 7 * week keeps the wall time.
      final start = DateTime(
        first.year,
        first.month,
        first.day + 7 * week,
        first.hour,
        first.minute,
      );
      if (!start.isBefore(until)) break;
      final repeatEnd = r.repeatUntil;
      if (week > 0 &&
          repeatEnd != null &&
          DateTime(start.year, start.month, start.day).isAfter(repeatEnd)) {
        break;
      }
      final end = start.add(Duration(minutes: r.durationMinutes));
      if (end.isAfter(from)) {
        final key = (r.id, dayKey(start));
        out.add(
          RehearsalDate(
            rehearsal: r,
            startsAt: start,
            cancelled: cancelled[key] ?? false,
            answers: answers[key] ?? const {},
          ),
        );
      }
      if (!r.weekly) break;
    }
  }
  out.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return out;
}
