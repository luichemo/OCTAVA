import 'dart:async';
import 'dart:typed_data';

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
import 'package:octava/screens/band_chat_screen.dart';
import 'package:octava/screens/band_screen.dart';
import 'package:octava/screens/matches_screen.dart';
import 'package:octava/widgets/live_banner.dart';

import 'chat_test.dart' show FakeChatRepository;
import 'profile_edit_test.dart' show FakeClipPlayer;
import 'record_test.dart' show FakeRecorder;
import 'safety_test.dart' show FakeSafetyRepository;

const me = BandPerson(id: 'me', name: 'Luka', instrumentId: 'guitar');
const nika = BandPerson(id: 'nika', name: 'Nika', instrumentId: 'drums');
const tamar = BandPerson(id: 'tamar', name: 'Tamar', instrumentId: 'keys');
const dato = BandPerson(id: 'dato', name: 'Dato', instrumentId: 'bass');

/// Bands in memory, following the same rules as the database functions.
class FakeBandsRepository implements BandsRepository {
  FakeBandsRepository({
    List<MyBand>? bands,
    List<BandInvite>? invites,
    List<MyBandRequest>? requests,
  }) : bands = [...?bands],
       invites = [...?invites],
       requests = [...?requests];

  /// Bands you asked to join, still voting.
  final List<MyBandRequest> requests;

  final List<MyBand> bands;
  final List<BandInvite> invites;
  final people = {
    for (final p in [me, nika, tamar, dato]) p.id: p,
  };
  final _changes = StreamController<BandChange>.broadcast();

  /// The next action fails with this message.
  String? failNext;
  final votes = <String>[];

  @override
  String get myId => me.id;

  @override
  Future<BandsState> load() async => (
    bands: [
      for (final b in bands)
        MyBand(
          id: b.id,
          name: b.name,
          members: b.members,
          proposals: b.proposals,
          description: b.description,
          genres: b.genres,
          openRoles: b.openRoles,
          clipPath: b.clipPath,
          clipSeconds: b.clipSeconds,
          removals: b.removals,
          chatOpen: b.members.length > 1 && !closedChats.contains(b.id),
          unreadCount: (_messages[b.id] ?? const <ChatMessage>[])
              .where(
                (m) =>
                    m.senderId != me.id &&
                    (myReads[b.id] == null || m.sentAt.isAfter(myReads[b.id]!)),
              )
              .length,
          lastMessage: switch (_messages[b.id]?.lastOrNull) {
            final m? => BandMessagePreview(
              senderId: m.senderId,
              senderName: people[m.senderId]?.name ?? '?',
              body: messagePreview(m.body),
              sentAt: m.sentAt,
            ),
            null => null,
          },
          readMarks: Map.of(otherReads[b.id] ?? const {}),
        ),
    ],
    invites: List.of(invites),
    requests: List.of(requests),
  );

  void _check() {
    final fail = failNext;
    failNext = null;
    if (fail != null) throw UserFacingException(fail);
  }

  void _replace(MyBand band) {
    bands[bands.indexWhere((b) => b.id == band.id)] = band;
    _changes.add(const BandsChanged());
  }

  @override
  Future<String> create(String name) async {
    _check();
    final id = 'band${bands.length + 1}';
    bands.add(MyBand(id: id, name: name, members: const [me]));
    _changes.add(const BandsChanged());
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
    final voted = band.proposals.firstWhere((p) => p.id == proposalId);
    final everyone = band.members.every(
      (m) => {...voted.approvedBy, me.id}.contains(m.id),
    );
    if (approve && voted.requested && everyone) {
      // They asked, so they're in as soon as the last member approves.
      _replace(
        MyBand(
          id: band.id,
          name: band.name,
          members: [...band.members, voted.candidate],
          proposals: [
            for (final p in band.proposals)
              if (p.id != proposalId) p,
          ],
        ),
      );
      return;
    }
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
    _changes.add(const BandsChanged());
  }

  final cancelled = <String>[];

  @override
  Future<void> withdrawRequest(String proposalId) async {
    _check();
    requests.removeWhere((r) => r.proposalId == proposalId);
    _changes.add(const BandsChanged());
  }

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
    _changes.add(const BandsChanged());
  }

  @override
  Stream<BandChange> changes() => _changes.stream;

  // ------------------------------------------------------------ profile
  MyBand _copy(
    MyBand b, {
    String? name,
    String? description,
    List<String>? genres,
    List<String>? openRoles,
    String? clipPath,
    int? clipSeconds,
    bool clearClip = false,
  }) => MyBand(
    id: b.id,
    name: name ?? b.name,
    members: b.members,
    proposals: b.proposals,
    description: description ?? b.description,
    genres: genres ?? b.genres,
    openRoles: openRoles ?? b.openRoles,
    clipPath: clearClip ? null : clipPath ?? b.clipPath,
    clipSeconds: clearClip ? null : clipSeconds ?? b.clipSeconds,
    removals: b.removals,
  );

  MyBand _band(String id) => bands.firstWhere((b) => b.id == id);

  @override
  Future<void> updateProfile(
    String bandId, {
    String? name,
    String? description,
    List<String>? genres,
    List<String>? openRoles,
  }) async {
    _check();
    _replace(
      _copy(
        _band(bandId),
        name: name?.trim(),
        description: description,
        genres: genres,
        openRoles: openRoles,
      ),
    );
  }

  @override
  Future<void> uploadClip(
    String bandId, {
    required Uint8List bytes,
    required String fileName,
    int? knownSeconds,
  }) async {
    _check();
    _replace(
      _copy(
        _band(bandId),
        clipPath: '$bandId/$fileName',
        clipSeconds: knownSeconds ?? 30,
      ),
    );
  }

  @override
  Future<void> removeClip(String bandId) async {
    _check();
    _replace(_copy(_band(bandId), clearClip: true));
  }

  @override
  Future<String> clipUrl(String path) async => 'https://example.invalid/$path';

  // ------------------------------------------------------------ removals
  final removalVotes = <String>[];

  /// Applies the majority rule, like private.settle_removal. True when
  /// [removal] removed its target.
  bool _settleRemoval(String bandId, BandRemoval removal) {
    final band = _band(bandId);
    final others = band.members.length - 1;
    final needed = removal.neededIn(band.members.length);
    final no = removal.votedBy.length - removal.yesBy.length;
    final removed = removal.yesBy.length >= needed;
    final refused = !removed && others - no < needed;
    _replace(
      MyBand(
        id: band.id,
        name: band.name,
        members: [
          for (final m in band.members)
            if (!removed || m.id != removal.target.id) m,
        ],
        proposals: band.proposals,
        removals: [
          for (final r in band.removals)
            if (r.id != removal.id) r else if (!removed && !refused) removal,
        ],
      ),
    );
    return removed;
  }

  @override
  Future<bool> proposeRemoval(String bandId, String targetId) async {
    _check();
    final band = _band(bandId);
    final removal = BandRemoval(
      id: 'r-$targetId',
      target: people[targetId]!,
      proposedBy: me,
      yesBy: {me.id},
      votedBy: {me.id},
    );
    _replace(
      MyBand(
        id: band.id,
        name: band.name,
        members: band.members,
        proposals: band.proposals,
        removals: [...band.removals, removal],
      ),
    );
    return _settleRemoval(bandId, removal);
  }

  @override
  Future<void> voteRemoval(String removalId, {required bool approve}) async {
    _check();
    removalVotes.add('$removalId:$approve');
    final band = bands.firstWhere(
      (b) => b.removals.any((r) => r.id == removalId),
    );
    final r = band.removals.firstWhere((r) => r.id == removalId);
    _settleRemoval(
      band.id,
      BandRemoval(
        id: r.id,
        target: r.target,
        proposedBy: r.proposedBy,
        yesBy: {...r.yesBy, if (approve) me.id},
        votedBy: {...r.votedBy, me.id},
      ),
    );
  }

  @override
  Future<void> cancelRemoval(String removalId) async {
    _check();
    final band = bands.firstWhere(
      (b) => b.removals.any((r) => r.id == removalId),
    );
    _replace(
      MyBand(
        id: band.id,
        name: band.name,
        members: band.members,
        proposals: band.proposals,
        removals: [
          for (final r in band.removals)
            if (r.id != removalId) r,
        ],
      ),
    );
  }

  // ------------------------------------------------------------ chat
  final _messages = <String, List<ChatMessage>>{};
  final _streams = <String, StreamController<List<ChatMessage>>>{};
  final myReads = <String, DateTime>{};
  final otherReads = <String, Map<String, DateTime>>{};
  final sent = <String>[];

  /// Bands whose chat is closed.
  final closedChats = <String>{};

  @override
  Stream<List<ChatMessage>> messages(String bandId) {
    final controller = _streams.putIfAbsent(
      bandId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    scheduleMicrotask(() => controller.add(List.of(_messages[bandId] ?? [])));
    return controller.stream;
  }

  void _post(
    String bandId,
    String senderId,
    String body, {
    String? audioPath,
    int? audioSeconds,
  }) {
    final list = _messages.putIfAbsent(bandId, () => []);
    list.add(
      ChatMessage(
        id: 'msg${list.length}',
        senderId: senderId,
        body: body,
        sentAt: DateTime.now(),
        audioPath: audioPath,
        audioSeconds: audioSeconds,
      ),
    );
    _streams[bandId]?.add(List.of(list));
    _changes.add(
      BandMessageArrived(
        bandId: bandId,
        senderId: senderId,
        body: messagePreview(body),
      ),
    );
  }

  final voiceSent = <String>[];

  @override
  Future<void> sendVoice(
    String bandId, {
    required Uint8List bytes,
    required String fileName,
    required int seconds,
  }) async {
    _check();
    if (closedChats.contains(bandId)) {
      throw UserFacingException(L10n.current.errBandSendClosed);
    }
    voiceSent.add('$bandId:$seconds');
    _post(
      bandId,
      me.id,
      '',
      audioPath: 'b/$bandId/$fileName',
      audioSeconds: seconds,
    );
  }

  /// A bandmate sends a voice message.
  void receiveVoice(String bandId, String senderId, int seconds) => _post(
    bandId,
    senderId,
    '',
    audioPath: 'b/$bandId/v$seconds.m4a',
    audioSeconds: seconds,
  );

  @override
  Future<void> send(String bandId, String body) async {
    _check();
    if (closedChats.contains(bandId)) {
      throw UserFacingException(L10n.current.errBandSendClosed);
    }
    sent.add(body);
    _post(bandId, me.id, body);
  }

  /// A bandmate posts.
  void receive(String bandId, String senderId, String body) =>
      _post(bandId, senderId, body);

  /// A bandmate reads the chat now.
  void readBy(String bandId, String userId) {
    otherReads.putIfAbsent(bandId, () => {})[userId] = DateTime.now().add(
      const Duration(seconds: 1),
    );
    _changes.add(const BandsChanged());
  }

  @override
  Future<void> markRead(String bandId) async =>
      myReads[bandId] = DateTime.now().add(const Duration(seconds: 1));
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
    // The new band's chat opens; alone, it asks you to add a member.
    expect(find.byType(BandChatScreen), findsOneWidget);
    expect(find.text('Night Shift'), findsOneWidget);
    expect(find.text('Add a member to start the band chat.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Members'));
    await tester.pumpAndSettle();
    expect(find.byType(BandScreen), findsOneWidget);
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

  testWidgets('your pending request shows, and can be withdrawn', (
    tester,
  ) async {
    final repo = FakeBandsRepository(
      requests: [
        const MyBandRequest(proposalId: 'req', bandId: 'b9', bandName: 'Riot'),
      ],
    );
    final live = LiveBands(repo)..start();
    final chat = FakeChatRepository(matches: [nikaMatch]);
    final matches = LiveUpdates(chat)..start();
    addTearDown(live.dispose);
    addTearDown(matches.dispose);
    await pump(
      tester,
      MatchesScreen(repository: chat, live: matches, bands: live),
    );
    expect(find.text('Riot'), findsOneWidget);
    expect(find.textContaining('waiting for the band'), findsOneWidget);

    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    expect(repo.requests, isEmpty);
    expect(find.text('Request withdrawn.'), findsOneWidget);
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
      await tester.ensureVisible(find.text('Reject'));
      await tester.pumpAndSettle();
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

    testWidgets('edit the band profile: roles and description', (tester) async {
      final repo = await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Riot', members: [me, nika]),
      );
      expect(find.textContaining('Add a description, genres'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit band'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'About the band'),
        'Loud and late',
      );
      for (final role in ['Keys', 'Bass']) {
        final chip = find.widgetWithText(FilterChip, role);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pump();
      }
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.bands.single.openRoles, ['keys', 'bass']);
      expect(find.text('Loud and late'), findsOneWidget);
      expect(find.text('Looking for: Keys and Bass'), findsOneWidget);
      expect(find.text('Band profile saved.'), findsOneWidget);
    });

    testWidgets('the band clip plays, and can be removed', (tester) async {
      final repo = FakeBandsRepository(
        bands: [
          const MyBand(
            id: 'b1',
            name: 'Riot',
            members: [me, nika],
            clipPath: 'b1/song.m4a',
            clipSeconds: 42,
          ),
        ],
      );
      final live = LiveBands(repo)..start();
      final player = FakeClipPlayer();
      addTearDown(live.dispose);
      await pump(tester, BandScreen(bands: live, bandId: 'b1', player: player));
      expect(find.text('Band clip · 0:42'), findsOneWidget);

      await tester.tap(find.byTooltip('Play the band clip'));
      await tester.pump();
      expect(player.toggled, ['band:b1/song.m4a']);

      await tester.tap(find.byTooltip('Remove the band clip'));
      await tester.pumpAndSettle();
      expect(repo.bands.single.clipPath, isNull);
      expect(find.text('No band clip yet'), findsOneWidget);
    });

    testWidgets('start a vote to remove a member, after a confirm', (
      tester,
    ) async {
      final repo = await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Riot', members: [me, nika, tamar]),
      );
      final options = find.byTooltip('Options for Tamar');
      await tester.ensureVisible(options);
      await tester.pumpAndSettle();
      await tester.tap(options);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from band'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Tamar from Riot?'), findsOneWidget);
      await tester.tap(find.text('Start the vote'));
      await tester.pumpAndSettle();

      // 3 members: both others must agree; your yes is the first of 2.
      expect(find.text('Vote started on removing Tamar.'), findsOneWidget);
      expect(find.text('Removing members'), findsOneWidget);
      expect(find.textContaining('1 of 2 needed'), findsOneWidget);
      expect(find.text('You agreed'), findsOneWidget);
      expect(repo.bands.single.members, hasLength(3));
    });

    testWidgets('a removal passes with a majority of the others', (
      tester,
    ) async {
      final repo = await pumpBand(
        tester,
        const MyBand(
          id: 'b1',
          name: 'Riot',
          members: [me, nika, tamar],
          removals: [
            BandRemoval(
              id: 'r1',
              target: tamar,
              proposedBy: nika,
              yesBy: {'nika'},
              votedBy: {'nika'},
            ),
          ],
        ),
      );
      final remove = find.widgetWithText(FilledButton, 'Remove');
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(repo.removalVotes, ['r1:true']);
      expect(repo.bands.single.members.map((m) => m.id), ['me', 'nika']);
      expect(find.text('Removing members'), findsNothing);
    });

    testWidgets('in a band of two, removing happens at once', (tester) async {
      final repo = await pumpBand(
        tester,
        const MyBand(id: 'b1', name: 'Duo', members: [me, nika]),
      );
      await tester.tap(find.byTooltip('Options for Nika'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from band'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start the vote'));
      await tester.pumpAndSettle();
      expect(find.text('Nika was removed from the band.'), findsOneWidget);
      expect(repo.bands.single.members.single.id, 'me');
    });

    testWidgets('a request to join is voted on, and joins when all agree', (
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
              id: 'req',
              candidate: dato,
              invited: false,
              requested: true,
              approvedBy: {'nika'},
            ),
          ],
        ),
      );
      expect(find.text('Asked to join'), findsOneWidget);
      expect(find.textContaining('1 of 2 approved'), findsOneWidget);
      final approve = find.text('Approve');
      await tester.ensureVisible(approve);
      await tester.pumpAndSettle();
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(repo.bands.single.members.map((m) => m.id), [
        'me',
        'nika',
        'dato',
      ]);
      expect(find.text('Dato joined the band!'), findsOneWidget);
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

  group('band chat', () {
    const riot = MyBand(id: 'b1', name: 'Riot', members: [me, nika, tamar]);

    Future<(FakeBandsRepository, LiveBands)> pumpChat(
      WidgetTester tester, {
      MyBand band = riot,
      Set<String> closed = const {},
    }) async {
      final repo = FakeBandsRepository(bands: [band])
        ..closedChats.addAll(closed);
      final live = LiveBands(repo)..start();
      addTearDown(live.dispose);
      await live.refresh();
      await pump(tester, BandChatScreen(bands: live, bandId: band.id));
      return (repo, live);
    }

    testWidgets('send and receive, with who wrote what', (tester) async {
      final (repo, _) = await pumpChat(tester);
      expect(find.text('No messages yet. Say hi to the band!'), findsOneWidget);
      expect(find.text('Luka, Nika and Tamar'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Rehearsal Friday?');
      await tester.pump(); // the mic turns into Send
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(repo.sent, ['Rehearsal Friday?']);
      expect(find.text('Rehearsal Friday?'), findsOneWidget);

      repo.receive('b1', 'nika', 'I\'m in');
      repo.receive('b1', 'nika', 'bringing my snare');
      await tester.pumpAndSettle();
      // No names: one avatar for Nika's run; tapping it shows who she is.
      expect(find.text('Nika'), findsNothing);
      final avatar = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Nika',
      );
      expect(avatar, findsOneWidget);
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      expect(find.text('Nika'), findsOneWidget);
      expect(find.text('Drums in Riot'), findsOneWidget);
      expect(find.text('bringing my snare'), findsOneWidget);
    });

    testWidgets('long-press a message from a bandmate to report it', (
      tester,
    ) async {
      final repo = FakeBandsRepository(bands: [riot]);
      final live = LiveBands(repo)..start();
      final safety = FakeSafetyRepository();
      addTearDown(live.dispose);
      await live.refresh();
      repo.receive('b1', 'nika', 'something rude');
      await pump(
        tester,
        BandChatScreen(bands: live, bandId: 'b1', safety: safety),
      );

      await tester.longPress(find.text('something rude'));
      await tester.pumpAndSettle();
      // Straight to the report form, quoting it; no Block in bands.
      expect(find.text('Report this message'), findsOneWidget);
      expect(find.text('“something rude”'), findsOneWidget);
      expect(find.textContaining('Block'), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
      await tester.tap(find.text('Harassment or hate'));
      await tester.pump();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(safety.reports.single.$1, 'nika');
      expect(safety.reportedMessages, ['msg0']);
    });

    testWidgets('record and send a voice message; it plays', (tester) async {
      final repo = FakeBandsRepository(bands: [riot]);
      final live = LiveBands(repo)..start();
      final player = FakeClipPlayer();
      addTearDown(live.dispose);
      await live.refresh();
      await pump(
        tester,
        BandChatScreen(
          bands: live,
          bandId: 'b1',
          player: player,
          recorder: () => FakeRecorder(seconds: 7),
        ),
      );
      // With nothing typed, the button records.
      await tester.tap(find.byTooltip('Record a voice message'));
      await tester.pump();
      expect(find.textContaining('Recording…'), findsOneWidget);
      await tester.tap(find.byTooltip('Send voice message'));
      await tester.pumpAndSettle();
      expect(repo.voiceSent, ['b1:7']);
      expect(find.text('0:07'), findsOneWidget);

      await tester.tap(find.byTooltip('Play voice message'));
      await tester.pump();
      expect(player.toggled, ['voice:b/b1/Recording.wav']);
    });

    testWidgets('a cancelled recording sends nothing', (tester) async {
      final repo = FakeBandsRepository(bands: [riot]);
      final live = LiveBands(repo)..start();
      addTearDown(live.dispose);
      await live.refresh();
      await pump(
        tester,
        BandChatScreen(
          bands: live,
          bandId: 'b1',
          recorder: () => FakeRecorder(),
        ),
      );
      await tester.tap(find.byTooltip('Record a voice message'));
      await tester.pump();
      await tester.tap(find.byTooltip('Cancel recording'));
      await tester.pumpAndSettle();
      expect(repo.voiceSent, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a bandmate\'s voice message shows in the list as such', (
      tester,
    ) async {
      final (repo, _) = await pumpMatches(tester, bands: [riot]);
      repo.receiveVoice('b1', 'nika', 12);
      await tester.pumpAndSettle();
      expect(find.text('Nika: 🎤 Voice message'), findsOneWidget);
    });

    testWidgets('your newest message says who has seen it', (tester) async {
      final (repo, _) = await pumpChat(tester);
      await tester.enterText(find.byType(TextField), 'Setlist ready');
      await tester.pump(); // the mic turns into Send
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Seen'), findsNothing);

      repo.readBy('b1', 'nika');
      await tester.pumpAndSettle();
      expect(find.text('Seen by 1'), findsOneWidget);
      repo.readBy('b1', 'tamar');
      await tester.pumpAndSettle();
      expect(find.text('Seen by everyone'), findsOneWidget);
    });

    testWidgets('a band of one asks for a member instead of a message box', (
      tester,
    ) async {
      await pumpChat(
        tester,
        band: const MyBand(id: 'b1', name: 'Solo', members: [me]),
      );
      expect(find.text('Add a member to start the band chat.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a paused mixed band explains why', (tester) async {
      await pumpChat(
        tester,
        band: const MyBand(id: 'b1', name: 'Duo', members: [me, nika]),
        closed: {'b1'},
      );
      expect(find.textContaining('needs at least 3 members'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('the band row shows the latest message and unread count', (
      tester,
    ) async {
      final (repo, live) = await pumpMatches(tester, bands: [riot]);
      repo.receive('b1', 'tamar', 'new song idea');
      await tester.pumpAndSettle();
      expect(find.text('Tamar: new song idea'), findsOneWidget);
      expect(live.unreadTotal, 1);
      expect(live.badgeCount, 1);

      await tester.tap(find.text('Riot'));
      await tester.pumpAndSettle();
      expect(find.byType(BandChatScreen), findsOneWidget);
      expect(live.unreadTotal, 0);
    });

    testWidgets('a band message elsewhere shows a banner that opens the chat', (
      tester,
    ) async {
      final repo = FakeBandsRepository(bands: [riot]);
      final live = LiveBands(repo)..start();
      addTearDown(live.dispose);
      await live.refresh();
      final opened = <String>[];
      await pump(
        tester,
        LiveBannerListener(
          live: null,
          bands: live,
          onOpen: (_) {},
          onOpenBand: opened.add,
          child: const Scaffold(body: Text('feed')),
        ),
      );
      repo.receive('b1', 'nika', 'gig on Saturday!');
      await tester.pumpAndSettle();
      expect(find.text('Riot'), findsOneWidget);
      expect(find.text('Nika: gig on Saturday!'), findsOneWidget);

      await tester.tap(find.text('Nika: gig on Saturday!'));
      await tester.pumpAndSettle();
      expect(opened, ['b1']);
    });

    testWidgets('your own messages don\'t make a banner', (tester) async {
      final repo = FakeBandsRepository(bands: [riot]);
      final live = LiveBands(repo)..start();
      addTearDown(live.dispose);
      await live.refresh();
      await pump(
        tester,
        LiveBannerListener(
          live: null,
          bands: live,
          onOpen: (_) {},
          child: const Scaffold(body: Text('feed')),
        ),
      );
      await repo.send('b1', 'from me');
      await tester.pumpAndSettle();
      expect(find.text('Luka: from me'), findsNothing);
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
      expect(
        find.text('შეტყობინებები ჯერ არაა. მიესალმე ბენდს!'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('წევრები'));
      await tester.pumpAndSettle();
      expect(find.text('წევრები'), findsOneWidget);
      expect(find.text('თანხმობა'), findsOneWidget);
    });
  });
}
