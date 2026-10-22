import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/rehearsal.dart';
import 'repositories.dart';

/// A rehearsal date with the band it's for (for reminders across bands).
typedef BandRehearsal = ({String bandId, String bandName, RehearsalDate date});

/// The band rehearsal calendar.
abstract interface class RehearsalRepository {
  String get myId;

  /// A band's rehearsal dates from now to [weeks] ahead, soonest first.
  Future<List<RehearsalDate>> upcoming(String bandId, {int weeks = 8});

  /// Your bands' rehearsals starting within [within], for reminders.
  Future<List<BandRehearsal>> soonForMe({
    Duration within = const Duration(hours: 24),
  });

  Future<void> add(String bandId, RehearsalDraft draft);
  Future<void> update(String rehearsalId, RehearsalDraft draft);

  /// Deletes the rehearsal (every date of a weekly one).
  Future<void> delete(String rehearsalId);

  /// Going (true) or can't (false) for one date.
  Future<void> answer(RehearsalDate date, {required bool going});

  /// Calls off one date of a weekly rehearsal, or ([cancelled] false)
  /// brings it back.
  Future<void> setCancelled(RehearsalDate date, {required bool cancelled});

  /// Fires when any rehearsal, answer or cancelled date you can see changes.
  Stream<void> changes();
}

class SupabaseRehearsalRepository implements RehearsalRepository {
  SupabaseRehearsalRepository(this._client);
  final SupabaseClient _client;

  @override
  String get myId => _client.auth.currentUser!.id;

  static const _columns =
      'id, band_id, starts_at, duration_minutes, place, notes, weekly, repeat_until, setlist_id';

  /// Expands [rows] into dates between [from] and [until], with answers and
  /// cancellations.
  Future<List<RehearsalDate>> _dates(
    List<Map<String, dynamic>> rows, {
    required DateTime from,
    required DateTime until,
  }) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r['id'] as String];
    final answerRows = await _client
        .from('rehearsal_answers')
        .select('rehearsal_id, occurs_on, member_id, going')
        .inFilter('rehearsal_id', ids);
    final cancelRows = await _client
        .from('rehearsal_cancellations')
        .select('rehearsal_id, occurs_on')
        .inFilter('rehearsal_id', ids);
    final answers = <(String, String), Map<String, bool>>{};
    for (final a in answerRows) {
      answers.putIfAbsent((
        a['rehearsal_id'] as String,
        a['occurs_on'] as String,
      ), () => {})[a['member_id'] as String] = a['going'] as bool;
    }
    return rehearsalDates(
      [for (final r in rows) Rehearsal.fromRow(r)],
      from: from,
      until: until,
      cancelled: {
        for (final c in cancelRows)
          (c['rehearsal_id'] as String, c['occurs_on'] as String): true,
      },
      answers: answers,
    );
  }

  @override
  Future<List<RehearsalDate>> upcoming(String bandId, {int weeks = 8}) async {
    try {
      final rows = await _client
          .from('rehearsals')
          .select(_columns)
          .eq('band_id', bandId)
          .order('starts_at');
      final now = DateTime.now();
      return await _dates(
        rows,
        from: now,
        until: now.add(Duration(days: 7 * weeks)),
      );
    } catch (_) {
      throw UserFacingException(L10n.current.errRehearsalsLoad);
    }
  }

  @override
  Future<List<BandRehearsal>> soonForMe({
    Duration within = const Duration(hours: 24),
  }) async {
    try {
      // Row-level security returns only your bands' rehearsals.
      final rows = await _client
          .from('rehearsals')
          .select('$_columns, bands(name)');
      final names = {
        for (final r in rows)
          r['band_id'] as String:
              (r['bands'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      };
      final now = DateTime.now();
      final dates = await _dates(rows, from: now, until: now.add(within));
      return [
        for (final d in dates)
          if (!d.cancelled)
            (
              bandId: d.rehearsal.bandId,
              bandName: names[d.rehearsal.bandId] ?? '',
              date: d,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// This device's time zone ("Europe/Berlin"), saved with each rehearsal
  /// so the reminder notifications work out its days, weekly repeats and
  /// clock time the way the band sees them. Null if it can't be read; the
  /// server then falls back to Tbilisi time.
  static Future<String?> _timeZone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _row(RehearsalDraft d) async {
    final zone = await _timeZone();
    return {
      'starts_at': d.startsAt.toUtc().toIso8601String(),
      'duration_minutes': d.durationMinutes,
      'place': d.place.trim().isEmpty ? null : d.place.trim(),
      'notes': d.notes.trim().isEmpty ? null : d.notes.trim(),
      'weekly': d.weekly,
      'repeat_until': d.weekly && d.repeatUntil != null
          ? dayKey(d.repeatUntil!)
          : null,
      'setlist_id': d.setlistId,
      'time_zone': ?zone,
    };
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw UserFacingException(L10n.current.errBandNotMember);
      }
      throw UserFacingException(L10n.current.errRehearsalSave);
    } catch (_) {
      throw UserFacingException(L10n.current.errBandAction);
    }
  }

  @override
  Future<void> add(String bandId, RehearsalDraft draft) => _write(
    () async => _client.from('rehearsals').insert({
      'band_id': bandId,
      'created_by': myId,
      ...await _row(draft),
    }),
  );

  @override
  Future<void> update(String rehearsalId, RehearsalDraft draft) => _write(
    () async => _client
        .from('rehearsals')
        .update(await _row(draft))
        .eq('id', rehearsalId),
  );

  @override
  Future<void> delete(String rehearsalId) =>
      _write(() => _client.from('rehearsals').delete().eq('id', rehearsalId));

  @override
  Future<void> answer(RehearsalDate date, {required bool going}) => _write(
    () => _client.from('rehearsal_answers').upsert({
      'rehearsal_id': date.rehearsal.id,
      'occurs_on': dayKey(date.day),
      'member_id': myId,
      'going': going,
      'answered_at': DateTime.now().toUtc().toIso8601String(),
    }),
  );

  @override
  Future<void> setCancelled(RehearsalDate date, {required bool cancelled}) =>
      _write(() async {
        final table = _client.from('rehearsal_cancellations');
        if (cancelled) {
          await table.upsert({
            'rehearsal_id': date.rehearsal.id,
            'occurs_on': dayKey(date.day),
            'cancelled_by': myId,
          });
        } else {
          await table
              .delete()
              .eq('rehearsal_id', date.rehearsal.id)
              .eq('occurs_on', dayKey(date.day));
        }
      });

  @override
  Stream<void> changes() {
    late final RealtimeChannel channel;
    final out = StreamController<void>(
      onCancel: () => _client.removeChannel(channel),
    );
    channel = _client.channel('rehearsals-$myId');
    for (final table in const [
      'rehearsals',
      'rehearsal_answers',
      'rehearsal_cancellations',
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
}
