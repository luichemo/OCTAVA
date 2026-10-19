import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/moderation_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/screens/moderation_screen.dart';
import 'package:octava/screens/moderators_screen.dart';

import 'signup_flow_test.dart' show FakeProfileRepository;

/// Reports in memory, resolved like mod_resolve_report does.
class FakeModeration implements ModerationRepository {
  FakeModeration({this.moderator = true, List<ModReport>? reports})
    : reports = [...?reports];

  final bool moderator;
  final List<ModReport> reports;
  final suspended = <String>{};
  final actions = <String>[];

  @override
  Future<bool> isModerator() async => moderator;

  @override
  Future<List<ModReport>> openReports() async => [
    for (final r in reports)
      ModReport(
        id: r.id,
        createdAt: r.createdAt,
        reason: r.reason,
        reportedId: r.reportedId,
        reportedName: r.reportedName,
        reporterName: r.reporterName,
        details: r.details,
        reportedText: r.reportedText,
        messageStillThere: r.messageStillThere,
        evidence: r.evidence,
        reportedSuspended: suspended.contains(r.reportedId),
        openAgainst: reports.where((o) => o.reportedId == r.reportedId).length,
      ),
  ];

  @override
  Future<void> resolve(
    String reportId,
    ModAction action, {
    String? note,
  }) async {
    actions.add('${action.name}:$reportId');
    final r = reports.firstWhere((r) => r.id == reportId);
    if (action == ModAction.suspend) {
      suspended.add(r.reportedId);
      // Suspending closes all their open reports.
      reports.removeWhere((o) => o.reportedId == r.reportedId);
    } else {
      reports.remove(r);
    }
  }

  @override
  Future<void> unsuspend(String personId) async => suspended.remove(personId);

  /// Cards by person id; anyone missing is a deleted account.
  final profiles = <String, ModProfile>{};

  @override
  Future<ModProfile?> profile(String personId) async => profiles[personId];

  bool admin = false;

  /// Everyone who could be found, by id; [mods] holds the moderators.
  final people = <String, ModPerson>{};
  final mods = <String>{};
  final admins = <String>{};

  ModPerson _with(ModPerson p) => ModPerson(
    id: p.id,
    name: p.name,
    age: p.age,
    suspended: p.suspended,
    isModerator: mods.contains(p.id),
    isAdmin: admins.contains(p.id),
  );

  @override
  Future<bool> isAdmin() async => admin;

  @override
  Future<List<ModPerson>> moderators() async => [
    for (final id in [...admins, ...mods.difference(admins)])
      _with(people[id]!),
  ];

  @override
  Future<List<ModPerson>> findPeople(String query) async => [
    for (final p in people.values)
      if (p.name.toLowerCase().contains(query.toLowerCase())) _with(p),
  ];

  @override
  Future<void> setModerator(String personId, bool make) async {
    if (make) {
      if (people[personId]!.suspended) {
        throw const UserFacingException('suspended');
      }
      mods.add(personId);
    } else {
      if (admins.contains(personId)) {
        throw const UserFacingException('admin');
      }
      mods.remove(personId);
    }
  }
}

void main() {
  final when = DateTime(2026, 10, 19, 12, 30);
  List<ModReport> sample() => [
    ModReport(
      id: 'r1',
      createdAt: when,
      reason: 'harassment',
      reportedId: 'bad',
      reportedName: 'Troll',
      reporterName: 'Nika',
      details: 'Rude in chat',
      reportedText: 'you play like a toaster',
      messageStillThere: true,
    ),
    ModReport(
      id: 'r2',
      createdAt: when,
      reason: 'spam',
      reportedId: 'bad',
      reportedName: 'Troll',
      reporterName: 'Ana',
    ),
    ModReport(
      id: 'r3',
      createdAt: when,
      reason: 'fake_profile',
      reportedId: 'other',
      reportedName: 'Sam',
      reporterName: 'Dato',
    ),
  ];

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  FakeProfileRepository profile() =>
      FakeProfileRepository(hasBirthDate: true, hasProfile: true)
        ..saved = const ProfileDraft(
          displayName: 'Luka',
          instruments: {'guitar': 'pro'},
        );

  testWidgets('only moderators see Reports on the profile page', (
    tester,
  ) async {
    await pump(
      tester,
      EditProfileScreen(
        repository: profile(),
        moderation: FakeModeration(moderator: false, reports: sample()),
      ),
    );
    expect(find.text('Reports'), findsNothing);
    // A fresh screen, so it checks again.
    await tester.pumpWidget(const SizedBox());

    await pump(
      tester,
      EditProfileScreen(
        repository: profile(),
        moderation: FakeModeration(reports: sample()),
      ),
    );
    expect(find.text('MODERATION'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('3 open reports'), findsOneWidget);
  });

  testWidgets('a report shows who, why, by whom and the message', (
    tester,
  ) async {
    await pump(
      tester,
      ModerationScreen(repository: FakeModeration(reports: sample())),
    );
    expect(find.text('Troll'), findsNWidgets(2));
    expect(find.text('Harassment or hate'), findsOneWidget);
    expect(find.textContaining('Reported by Nika'), findsOneWidget);
    expect(find.text('Rude in chat'), findsOneWidget);
    expect(find.text('“you play like a toaster”'), findsOneWidget);
    expect(find.text('2 open reports against them'), findsNWidgets(2));
    // Remove message only where a message is still there.
    expect(find.text('Remove message'), findsOneWidget);
  });

  testWidgets('Dismiss and Remove message close one report', (tester) async {
    final mod = FakeModeration(reports: sample());
    await pump(tester, ModerationScreen(repository: mod));

    await tester.tap(find.text('Remove message'));
    await tester.pumpAndSettle();
    expect(mod.actions, ['removeMessage:r1']);
    expect(find.text('Message removed.'), findsOneWidget);
    expect(find.textContaining('toaster'), findsNothing);

    await tester.tap(find.text('Dismiss').last);
    await tester.pumpAndSettle();
    expect(mod.actions.last, 'dismiss:r3');
    expect(find.text('Sam'), findsNothing);
  });

  testWidgets('Suspend asks first, then closes all their reports', (
    tester,
  ) async {
    final mod = FakeModeration(reports: sample());
    await pump(tester, ModerationScreen(repository: mod));

    await tester.tap(find.text('Suspend').first);
    await tester.pumpAndSettle();
    expect(find.text('Suspend Troll?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(mod.actions, isEmpty);

    await tester.tap(find.text('Suspend').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
    await tester.pumpAndSettle();
    expect(mod.suspended, {'bad'});
    expect(find.text('Troll is suspended.'), findsOneWidget);
    expect(find.text('Troll'), findsNothing);
    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('a one-on-one report folds their recent messages', (
    tester,
  ) async {
    final mod = FakeModeration(
      reports: [
        ModReport(
          id: 'r9',
          createdAt: when,
          reason: 'harassment',
          reportedId: 'bad',
          reportedName: 'Troll',
          reporterName: 'Nika',
          evidence: [
            ModEvidence(at: when, body: 'hey'),
            ModEvidence(at: when, body: 'answer me'),
            ModEvidence(at: when, voiceSeconds: 7),
          ],
        ),
      ],
    );
    await pump(tester, ModerationScreen(repository: mod));
    expect(find.text('Their last 3 messages to Nika'), findsOneWidget);
    expect(find.text('answer me'), findsNothing);

    await tester.tap(find.text('Their last 3 messages to Nika'));
    await tester.pumpAndSettle();
    expect(find.text('hey'), findsOneWidget);
    expect(find.text('answer me'), findsOneWidget);
    expect(find.text('🎤 Voice message · 0:07'), findsOneWidget);
  });

  testWidgets('View profile opens their card, or says it is gone', (
    tester,
  ) async {
    final mod = FakeModeration(reports: sample())
      ..profiles['bad'] = ModProfile(
        card: const Musician(name: 'Troll', age: 17, instrumentId: 'drums'),
        joinedAt: DateTime(2026, 10, 1),
      );
    await pump(tester, ModerationScreen(repository: mod));

    await tester.tap(find.text('View profile').first);
    await tester.pumpAndSettle();
    expect(find.text('Joined Oct 1, 2026'), findsOneWidget);
    expect(find.text('Troll, 17'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('View profile').last);
    await tester.pumpAndSettle();
    expect(find.text('This account no longer exists.'), findsOneWidget);
  });

  FakeModeration adminSetup() => FakeModeration()
    ..admin = true
    ..people.addAll({
      'me': const ModPerson(id: 'me', name: 'Luichemo'),
      'lui': const ModPerson(id: 'lui', name: 'Lui'),
      'nika': const ModPerson(id: 'nika', name: 'Nika', age: 24),
      'saba': const ModPerson(id: 'saba', name: 'Saba', age: 16),
      'bad': const ModPerson(id: 'bad', name: 'Nikoloz', suspended: true),
    })
    ..admins.add('me')
    ..mods.addAll({'me', 'lui'});

  testWidgets('only admins see Moderators on the profile page', (tester) async {
    await pump(
      tester,
      EditProfileScreen(
        repository: profile(),
        moderation: FakeModeration(reports: sample()),
      ),
    );
    expect(find.text('Moderators'), findsNothing);
    await tester.pumpWidget(const SizedBox());

    await pump(
      tester,
      EditProfileScreen(repository: profile(), moderation: adminSetup()),
    );
    expect(find.text('Moderators'), findsOneWidget);
    expect(find.text('2 moderators'), findsOneWidget);
  });

  testWidgets('an admin finds someone and makes them a moderator', (
    tester,
  ) async {
    final mod = adminSetup();
    await pump(tester, ModeratorsScreen(repository: mod));
    // The admin can't be removed; other moderators can.
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ni');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Nika'), findsOneWidget);
    // Suspended accounts can't be picked.
    expect(find.text('Nikoloz'), findsOneWidget);
    expect(find.text('Make moderator'), findsOneWidget);

    await tester.tap(find.text('Make moderator'));
    await tester.pumpAndSettle();
    expect(find.text('Make Nika a moderator?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Make moderator'));
    await tester.pumpAndSettle();
    expect(mod.mods, contains('nika'));
    expect(find.text('Nika is now a moderator.'), findsOneWidget);
    expect(find.text('Moderator'), findsOneWidget);
  });

  testWidgets('Remove asks first, then takes them off the list', (
    tester,
  ) async {
    final mod = adminSetup();
    await pump(tester, ModeratorsScreen(repository: mod));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Lui as a moderator?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(mod.mods, {'me'});
    expect(find.text('Lui is no longer a moderator.'), findsOneWidget);
    expect(find.text('Lui'), findsNothing);
  });

  testWidgets('no open reports says so', (tester) async {
    await pump(tester, ModerationScreen(repository: FakeModeration()));
    expect(find.text('No open reports. All clear.'), findsOneWidget);
  });
}
