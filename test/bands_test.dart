import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/bands_repository.dart';
import 'package:octava/data/live_bands.dart';
import 'package:octava/data/live_updates.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/l10n/l10n.dart';
import 'package:octava/main.dart';
import 'package:octava/models/band_group.dart';
import 'package:octava/models/chat.dart';
import 'package:octava/screens/band_screen.dart';
import 'package:octava/screens/matches_screen.dart';

import 'chat_test.dart' show FakeChatRepository;

const me = BandPerson(id: 'me', name: 'Luka', instrumentId: 'guitar');
const nika = BandPerson(id: 'nika', name: 'Nika', instrumentId: 'drums');
const tamar = BandPerson(id: 'tamar', name: 'Tamar', instrumentId: 'keys');
const dato = BandPerson(id: 'dato', name: 'Dato', instrumentId: 'bass');

/// Bands in memory, following the same rules as the database functions.
class FakeBandsRepository implements BandsRepository {
  FakeBandsRepository({List<MyBand>? bands, List<BandInvite>? invites})
    : bands = [...?bands],
      invites = [...?invites];

  final List<MyBand> bands;
  final List<BandInvite> invites;
  final people = {
    for (final p in [me, nika, tamar, dato]) p.id: p,
  };
  final _changes = StreamController<void>.broadcast();

  /// The next action fails with this message.
  String? failNext;
  final votes = <String>[];

  @override
  String get myId => me.id;

  @override
  Future<BandsState> load() async =>
      (bands: List.of(bands), invites: List.of(invites));

  void _check() {
    final fail = failNext;
    failNext = null;
    if (fail != null) throw UserFacingException(fail);
  }

  void _replace(MyBand band) {
    bands[bands.indexWhere((b) => b.id == band.id)] = band;
    _changes.add(null);
  }

  @override
  Future<String> create(String name) async {
    _check();
    final id = 'band${bands.length + 1}';
    bands.add(MyBand(id: id, name: name, members: const [me]));
    _changes.add(null);
    return id;
  }

  @override
  Future<bool> propose(String bandId, String candidateId) async {
    _check();
    final band = bands.firstWhere((b) => b.id == bandId);
    final invited = band.members.length == 1;
    _replace(
      MyBand(
        id: band.id,
        name: band.name,
        members: band.members,
        proposals: [
          ...band.proposals,
          BandProposal(
            id: 'p-$candidateId',
            candidate: people[candidateId]!,
            proposedBy: me,
            invited: invited,
            approvedBy: {me.id},
          ),
        ],
      ),
    );
    return invited;
  }

  @override
  Future<void> vote(String proposalId, {required bool approve}) async {
    _check();
    votes.add('$proposalId:$approve');
    final band = bands.firstWhere(
      (b) => b.proposals.any((p) => p.id == proposalId),
    );
    _replace(
      MyBand(
        id: band.id,
        name: band.name,
        members: band.members,
        proposals: [
          for (final p in band.proposals)
            if (p.id != proposalId)
              p
            else if (approve)
              BandProposal(
                id: p.id,
                candidate: p.candidate,
                proposedBy: p.proposedBy,
                approvedBy: {...p.approvedBy, me.id},
                invited: band.members.every(
                  (m) => {...p.approvedBy, me.id}.contains(m.id),
                ),
              ),
        ],
      ),
    );
  }

  @override
  Future<void> answerInvite(String proposalId, {required bool accept}) async {
    _check();
    final invite = invites.firstWhere((i) => i.proposalId == proposalId);
    invites.remove(invite);
    if (accept) {
      bands.add(
        MyBand(
          id: invite.bandId,
          name: invite.bandName,
          members: [...invite.members, me],
        ),
      );
    }
    _changes.add(null);
  }

  final cancelled = <String>[];

  @override
  Future<void> cancel(String proposalId) async {
    _check();
    cancelled.add(proposalId);
    final band = bands.firstWhere(
      (b) => b.proposals.any((p) => p.id == proposalId),
    );
    _replace(
      MyBand(
        id: band.id,
        name: band.name,
        members: band.members,
        proposals: [
          for (final p in band.proposals)
            if (p.id != proposalId) p,
        ],
      ),
    );
  }

  @override
  Future<void> leave(String bandId) async {
    _check();
    bands.removeWhere((b) => b.id == bandId);
    _changes.add(null);
  }

  @override
  Stream<void> changes() => _changes.stream;
}

void main() {
  final nikaMatch = MatchSummary(
    matchId: 'm-nika',
    otherUserId: 'nika',
    name: 'Nika',
    instrument: 'Drums',
    matchedAt: DateTime(2026, 10, 1),
  );
  final datoMatch = MatchSummary(
    matchId: 'm-dato',
    otherUserId: 'dato',
    name: 'Dato',
    instrument: 'Bass',
    matchedAt: DateTime(2026, 10, 2),
  );

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  /// The Matches screen as the app shows it: bands above matches.
  Future<(FakeBandsRepository, LiveBands)> pumpMatches(
    WidgetTester tester, {
    List<MyBand>? bands,
    List<BandInvite>? invites,
  }) async {
    final repo = FakeBandsRepository(bands: bands, invites: invites);
    final live = LiveBands(repo)..start();
    final chat = FakeChatRepository(matches: [nikaMatch, datoMatch]);
    final matches = LiveUpdates(chat)..start();
    addTearDown(live.dispose);
    addTearDown(matches.dispose);
    await pump(
      tester,
      MatchesScreen(repository: chat, live: matches, bands: live),
    );
    return (repo, live);
  }

  test('band rule errors are shown in the app\'s language', () {
    expect(
      bandErrorMessage('You can only propose people you\'ve matched with'),
      'You can only propose people you\'ve matched with.',
    );
    expect(
      bandErrorMessage(
        'A band needs at least 2 members before someone of another age group can join',
      ),
      'A band needs at least 2 members before someone from another age group can join.',
    );
    expect(bandErrorMessage('something new'), L10n.current.errBandAction);
  });

  test('the badge counts invites and votes waiting for you', () async {
    final repo = FakeBandsRepository(
      bands: [
        const MyBand(
          id: 'b1',
          name: 'Riot',
          members: [me, nika],
          proposals: [
            BandProposal(
              id: 'p1',
              candidate: tamar,
              proposedBy: nika,
              invited: false,
              approvedBy: {'nika'},
            ),
            BandProposal(
              id: 'p2',
              candidate: dato,
              proposedBy: me,
              invited: false,
              approvedBy: {'me'},
            ),
          ],
        ),
      ],
      invites: [
        const BandInvite(
          proposalId: 'p3',
          bandId: 'b2',
          bandName: 'Other',
          members: [tamar],
        ),
      ],
    );
    final live = LiveBands(repo)..start();
    addTearDown(live.dispose);
    await live.refresh();
    // One invite + one vote (Tamar); Dato is already approved by you.
    expect(live.actionCount, 2);
  });

  testWidgets('create a band: it opens with you as its only member', (
    tester,
  ) async {
    final (repo, _) = await pumpMatches(tester);
    expect(find.text('Bands'), findsOneWidget);

    await tester.tap(find.text('Create a band'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Give your band a name'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Night Shift ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(repo.bands.single.name, 'Night Shift');
    expect(find.byType(BandScreen), findsOneWidget);
    expect(find.text('Night Shift'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('accepting an invite puts the band in your list', (tester) async {
    final (repo, _) = await pumpMatches(
      tester,
      invites: [
        const BandInvite(
          proposalId: 'p1',
          bandId: 'b1',
          bandName: 'Riot',
          members: [nika, tamar],
        ),
      ],
    );
    expect(find.text('Riot wants you to join'), findsOneWidget);
    expect(find.text('Nika (Drums) and Tamar (Keys)'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(repo.invites, isEmpty);
    expect(find.text('Riot wants you to join'), findsNothing);
    expect(find.text('You joined Riot!'), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
  });

  testWidgets('a band with a vote waiting shows it in the list', (
    tester,
  ) async {
    await pumpMatches(
      tester,
      bands: [
        const MyBand(
          id: 'b1',
          name: 'Riot',
          members: [me, nika],
          proposals: [
            BandProposal(
              id: 'p1',
              candidate: tamar,
              proposedBy: nika,
              invited: false,
              approvedBy: {'nika'},
            ),
          ],
        ),
      ],
    );
    expect(find.text('1 vote waiting for you'), findsOneWidget);
  });

  group('band page', () {
    Future<FakeBandsRepository> pumpBand(
      WidgetTester tester,
      MyBand band,
    ) async {
      final repo = FakeBandsRepository(bands: [band]);
      final live = LiveBands(repo)..start();
      final matches = LiveUpdates(
        FakeChatRepository(matches: [nikaMatch, datoMatch]),
      )..start();
      addTearDown(live.dispose);
      addTearDown(matches.dispose);
      await pump(
        tester,
        BandScreen(bands: live, bandId: band.id, matches: matches),
      );
      return repo;
    }

    const voting = MyBand(
      id: 'b1',
      name: 'Riot',
      members: [me, nika, dato],
      proposals: [
        BandProposal(
          id: 'p1',
          candidate: tamar,
          proposedBy: nika,
          invited: false,
          approvedBy: {'nika'},
        ),
      ],
    );

    testWidgets('approving counts your vote', (tester) async {
      final repo = await pumpBand(tester, voting);
      expect(find.text('Proposed by Nika · 1 of 3 approved'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(repo.votes, ['p1:true']);
      expect(find.text('You approved'), findsOneWidget);
      expect(find.text('Proposed by Nika · 2 of 3 approved'), findsOneWidget);
    });

    testWidgets('rejecting asks first, then removes the proposal', (
      tester,
    ) async {
      final repo = await pumpBand(tester, voting);
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(find.text('Reject Tamar?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();
      expect(repo.votes, ['p1:false']);
      expect(find.text('Tamar'), findsNothing);
    });

    testWidgets('add member lists only matches not already in the band', (
      tester,
    ) async {
      final repo = await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Riot', members: [me, nika]),
      );
      await tester.tap(find.text('Add member'));
      await tester.pumpAndSettle();
      expect(find.text('Propose one of your matches'), findsOneWidget);
      // Nika is already a member; Dato can be proposed.
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Nika'),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Dato'));
      await tester.pumpAndSettle();
      expect(repo.bands.single.proposals.single.candidate.id, 'dato');
      expect(
        find.text('Proposed Dato. Your bandmates will vote.'),
        findsOneWidget,
      );
    });

    testWidgets('in a band of one, proposing sends the invite at once', (
      tester,
    ) async {
      await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Solo', members: [me]),
      );
      await tester.tap(find.text('Add member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nika'));
      await tester.pumpAndSettle();
      expect(find.text('Invite sent to Nika.'), findsOneWidget);
      expect(
        find.textContaining('Invited, waiting for their answer'),
        findsOneWidget,
      );
    });

    testWidgets('a refused action shows the rule', (tester) async {
      final repo = await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Solo', members: [me]),
      );
      repo.failNext = L10n.current.errBandAgeRule;
      await tester.tap(find.text('Add member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nika'));
      await tester.pumpAndSettle();
      expect(find.text(L10n.current.errBandAgeRule), findsOneWidget);
      expect(find.text('Invite sent to Nika.'), findsNothing);
    });

    testWidgets('you can cancel a request you made, after a confirm', (
      tester,
    ) async {
      final repo = await pumpBand(
        tester,
        const MyBand(
          id: 'b1',
          name: 'Riot',
          members: [me, nika],
          proposals: [
            BandProposal(
              id: 'mine',
              candidate: dato,
              proposedBy: me,
              invited: false,
              approvedBy: {'me'},
            ),
            BandProposal(
              id: 'theirs',
              candidate: tamar,
              proposedBy: nika,
              invited: true,
              approvedBy: {'me', 'nika'},
            ),
          ],
        ),
      );
      // Only on your own request, not on Nika's.
      expect(find.text('Cancel request'), findsOneWidget);
      expect(find.text('You approved'), findsOneWidget);

      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel the request for Dato?'), findsOneWidget);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, isEmpty);

      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel request'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, ['mine']);
      expect(find.text('Dato'), findsNothing);
      expect(find.text('Request for Dato cancelled.'), findsOneWidget);
    });

    testWidgets('an invite you sent can be cancelled too', (tester) async {
      final repo = await pumpBand(
        tester,
        const MyBand(
          id: 'b1',
          name: 'Solo',
          members: [me],
          proposals: [
            BandProposal(
              id: 'p1',
              candidate: nika,
              proposedBy: me,
              invited: true,
              approvedBy: {'me'},
            ),
          ],
        ),
      );
      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel request'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, ['p1']);
    });

    testWidgets('leaving asks first and goes back', (tester) async {
      final repo = await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Riot', members: [me, nika]),
      );
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave band'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Riot?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Leave band'));
      await tester.pumpAndSettle();
      expect(repo.bands, isEmpty);
    });
  });

  group('in Georgian', () {
    setUp(() => appLanguage.value = const Locale('ka'));
    tearDown(() => appLanguage.value = null);

    testWidgets('the band page and an invite fit', (tester) async {
      await pumpMatches(
        tester,
        bands: [
          const MyBand(
            id: 'b1',
            name: 'Riot',
            members: [me, nika],
            proposals: [
              BandProposal(
                id: 'p1',
                candidate: tamar,
                proposedBy: nika,
                invited: false,
                approvedBy: {'nika'},
              ),
            ],
          ),
        ],
        invites: [
          const BandInvite(
            proposalId: 'p2',
            bandId: 'b2',
            bandName: 'Night Shift',
            members: [dato],
          ),
        ],
      );
      expect(find.text('ბენდები'), findsOneWidget);
      expect(find.text('მიღება'), findsOneWidget);

      await tester.tap(find.text('Riot'));
      await tester.pumpAndSettle();
      expect(find.text('წევრები'), findsOneWidget);
      expect(find.text('თანხმობა'), findsOneWidget);
    });
  });
}
