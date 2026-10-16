import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/rehearsal_reminders.dart';
import 'package:octava/data/rehearsal_repository.dart';
import 'package:octava/l10n/l10n.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band_group.dart';
import 'package:octava/models/rehearsal.dart';
import 'package:octava/widgets/rehearsals_section.dart';

import 'bands_test.dart' show me, nika, tamar;

/// Rehearsals in memory, expanded the same way as the real repository.
class FakeRehearsalRepository implements RehearsalRepository {
  final rehearsals = <Rehearsal>[];
  final answers = <(String, String), Map<String, bool>>{};
  final cancelled = <(String, String), bool>{};
  final _changes = StreamController<void>.broadcast();

  /// What soonForMe returns (for reminder tests).
  List<BandRehearsal> soon = const [];
  int soonCalls = 0;

  @override
  String get myId => me.id;

  @override
  Future<List<RehearsalDate>> upcoming(String bandId, {int weeks = 8}) async {
    final now = DateTime.now();
    return rehearsalDates(
      [
        for (final r in rehearsals)
          if (r.bandId == bandId) r,
      ],
      from: now,
      until: now.add(Duration(days: 7 * weeks)),
      cancelled: cancelled,
      answers: answers,
    );
  }

  @override
  Future<List<BandRehearsal>> soonForMe({
    Duration within = const Duration(hours: 24),
  }) async {
    soonCalls++;
    return soon;
  }

  @override
  Future<void> add(String bandId, RehearsalDraft d) async {
    rehearsals.add(
      Rehearsal(
        id: 'r${rehearsals.length + 1}',
        bandId: bandId,
        startsAt: d.startsAt,
        durationMinutes: d.durationMinutes,
        place: d.place.isEmpty ? null : d.place,
        notes: d.notes.isEmpty ? null : d.notes,
        weekly: d.weekly,
        repeatUntil: d.repeatUntil,
        setlistId: d.setlistId,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> update(String rehearsalId, RehearsalDraft d) async {}

  @override
  Future<void> delete(String rehearsalId) async {
    rehearsals.removeWhere((r) => r.id == rehearsalId);
    _changes.add(null);
  }

  @override
  Future<void> answer(RehearsalDate date, {required bool going}) async {
    answers.putIfAbsent((
      date.rehearsal.id,
      dayKey(date.day),
    ), () => {})[me.id] = going;
    _changes.add(null);
  }

  @override
  Future<void> setCancelled(
    RehearsalDate date, {
    required bool cancelled,
  }) async {
    final key = (date.rehearsal.id, dayKey(date.day));
    cancelled ? this.cancelled[key] = true : this.cancelled.remove(key);
    _changes.add(null);
  }

  @override
  Stream<void> changes() => _changes.stream;
}

void main() {
  const band = MyBand(id: 'b1', name: 'Riot', members: [me, nika, tamar]);

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  Widget section(FakeRehearsalRepository repo) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [RehearsalsSection(repository: repo, band: band)],
    ),
  );

  group('dates', () {
    final friday = DateTime(2026, 10, 23, 19);

    test('a weekly rehearsal repeats at the same time, until its end day', () {
      final dates = rehearsalDates(
        [
          Rehearsal(
            id: 'r',
            bandId: 'b',
            startsAt: friday,
            weekly: true,
            repeatUntil: DateTime(2026, 11, 6),
          ),
        ],
        from: DateTime(2026, 10, 20),
        until: DateTime(2027),
      );
      expect(
        [for (final d in dates) d.startsAt],
        [friday, DateTime(2026, 10, 30, 19), DateTime(2026, 11, 6, 19)],
      );
    });

    test('past dates are left out, and one-off rehearsals happen once', () {
      final dates = rehearsalDates(
        [
          Rehearsal(id: 'once', bandId: 'b', startsAt: friday),
          Rehearsal(id: 'weekly', bandId: 'b', startsAt: friday, weekly: true),
        ],
        from: DateTime(2026, 10, 28),
        until: DateTime(2026, 11, 14),
      );
      expect(
        [for (final d in dates) '${d.rehearsal.id} ${d.day.day}'],
        ['weekly 30', 'weekly 6', 'weekly 13'],
      );
    });

    test('answers and called-off dates are matched by day', () {
      final dates = rehearsalDates(
        [Rehearsal(id: 'r', bandId: 'b', startsAt: friday, weekly: true)],
        from: DateTime(2026, 10, 20),
        until: DateTime(2026, 11, 1),
        cancelled: {('r', '2026-10-30'): true},
        answers: {
          ('r', '2026-10-23'): {'me': true, 'nika': false},
        },
      );
      expect(dates.first.going, 1);
      expect(dates.first.cant, 1);
      expect(dates.last.cancelled, isTrue);
    });
  });

  testWidgets('add a rehearsal and answer Going', (tester) async {
    final repo = FakeRehearsalRepository();
    await pump(tester, section(repo));
    expect(find.textContaining('No rehearsals planned'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Add rehearsal'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Place (optional)'),
      'Studio 4',
    );
    await tester.tap(find.text('Repeat every week'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repo.rehearsals.single.weekly, isTrue);
    expect(find.text('Rehearsal added.'), findsOneWidget);
    // Only the next 7 days show: the first week of the weekly rehearsal.
    expect(find.text('Studio 4'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();
    expect(find.text('Studio 4'), findsNWidgets(8));
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Going').first);
    await tester.pumpAndSettle();
    expect(find.text('1 going · 0 can\'t'), findsOneWidget);
  });

  testWidgets('a date shows who\'s coming; one week can be called off', (
    tester,
  ) async {
    final repo = FakeRehearsalRepository();
    final start = DateTime.now().add(const Duration(days: 2));
    repo.rehearsals.add(
      Rehearsal(
        id: 'r1',
        bandId: 'b1',
        startsAt: DateTime(start.year, start.month, start.day, 19),
        place: 'Studio 4',
        weekly: true,
      ),
    );
    repo.answers[('r1', dayKey(start))] = {'nika': true, 'tamar': false};
    await pump(tester, section(repo));

    await tester.tap(find.textContaining('1 going').first);
    await tester.pumpAndSettle();
    expect(find.text('Going: Nika'), findsOneWidget);
    expect(find.text('Can\'t: Tamar'), findsOneWidget);
    expect(find.text('No answer yet: Luka'), findsOneWidget);

    await tester.tap(find.text('Call off this date'));
    await tester.pumpAndSettle();
    expect(find.text('Called off'), findsOneWidget);
    expect(find.text('That date is called off.'), findsOneWidget);
  });

  testWidgets('a rehearsal after this week waits behind Show all', (
    tester,
  ) async {
    final repo = FakeRehearsalRepository();
    repo.rehearsals.add(
      Rehearsal(
        id: 'r1',
        bandId: 'b1',
        startsAt: DateTime.now().add(const Duration(days: 10)),
        place: 'Later',
      ),
    );
    await pump(tester, section(repo));
    expect(find.text('Nothing in the next 7 days.'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();
    expect(find.text('Later'), findsOneWidget);
  });

  testWidgets('deleting asks first', (tester) async {
    final repo = FakeRehearsalRepository();
    repo.rehearsals.add(
      Rehearsal(
        id: 'r1',
        bandId: 'b1',
        startsAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await pump(tester, section(repo));
    await tester.tap(find.textContaining('0 going'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete rehearsal'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this rehearsal?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete rehearsal'));
    await tester.pumpAndSettle();
    expect(repo.rehearsals, isEmpty);
    expect(find.textContaining('No rehearsals planned'), findsOneWidget);
  });

  test('a reminder is announced once per rehearsal date', () async {
    final repo = FakeRehearsalRepository();
    final date = RehearsalDate(
      rehearsal: Rehearsal(
        id: 'r1',
        bandId: 'b1',
        startsAt: DateTime.now().add(const Duration(minutes: 40)),
      ),
      startsAt: DateTime.now().add(const Duration(minutes: 40)),
    );
    repo.soon = [(bandId: 'b1', bandName: 'Riot', date: date)];
    final reminders = RehearsalReminders(repo);
    final seen = <String>[];
    reminders.banners.listen((r) => seen.add(r.bandName));
    await reminders.check();
    await reminders.check();
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['Riot']);
    reminders.dispose();
  });

  testWidgets('the calendar fits in Georgian', (tester) async {
    appLanguage.value = const Locale('ka');
    addTearDown(() => appLanguage.value = null);
    final repo = FakeRehearsalRepository();
    repo.rehearsals.add(
      Rehearsal(
        id: 'r1',
        bandId: 'b1',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        place: 'სტუდია 4',
        weekly: true,
      ),
    );
    await pump(tester, section(repo));
    expect(find.text('რეპეტიციები'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'მოვალ'), findsWidgets);
    expect(L10n.current.localeName, 'ka');
  });
}
