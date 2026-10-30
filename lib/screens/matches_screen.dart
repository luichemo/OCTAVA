import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/avatar_repository.dart';
import '../data/chat_repository.dart';
import '../data/clip_repository.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/rehearsal_repository.dart';
import '../data/song_repository.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../models/band_group.dart';
import '../models/chat.dart';
import '../models/musician.dart' show listJoin;
import '../theme.dart';
import '../widgets/person_avatar.dart';
import 'band_chat_screen.dart';
import 'band_screen.dart';
import 'chat_screen.dart';
import 'match_card_screen.dart';

/// The pages behind the bottom bar's buttons (owner, 2026-10-26: separate
/// pages instead of one long list).
enum InboxPage {
  /// One-on-one chats with your matches.
  messages,

  /// Everything waiting for your answer: band invites, votes in your bands,
  /// and your own requests to join.
  requests,

  /// Your bands, and Create a band.
  bands,
}

/// One of the [InboxPage]s, updated live: your matches (newest activity
/// first; tap one to chat), your requests, or your bands ([bands] is needed
/// for the last two).
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
    required this.repository,
    this.page = InboxPage.messages,
    this.live,
    this.safety,
    this.avatars,
    this.bands,
    this.player,
    this.rehearsals,
    this.songs,
  });

  /// Band calendars and songs, on band pages.
  final RehearsalRepository? rehearsals;
  final SongRepository? songs;

  /// Plays band clips on band pages.
  final ClipPlayer? player;

  final InboxPage page;

  /// Your bands, invites and requests, for the Requests and Bands pages.
  final LiveBands? bands;

  /// Shows people's AI avatars. Without it, their initial.
  final AvatarRepository? avatars;

  final ChatRepository repository;

  /// The session's live matches. Without it the screen makes its own.
  final LiveUpdates? live;

  /// Passed on to chats for block and report.
  final SafetyRepository? safety;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // `widget.live ?? ...`: use the shared one, or own a private one.
  late final LiveUpdates _live =
      widget.live ?? (LiveUpdates(widget.repository)..start());

  @override
  void dispose() {
    if (widget.live == null) _live.dispose();
    super.dispose();
  }

  Future<void> _open(MatchSummary match) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          repository: widget.repository,
          live: _live,
          matchId: match.matchId,
          otherUserId: match.otherUserId,
          safety: widget.safety,
          name: match.name,
          instrument: match.instrument,
          player: widget.player,
          avatars: widget.avatars,
        ),
      ),
    );
    // Blocking in the chat removes it from the list.
    if (mounted) _live.refresh();
  }

  /// Their card, with Open chat underneath.
  Future<void> _openCard(MatchSummary match) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (cardContext) => MatchCardScreen(
            load: () => widget.repository.matchCard(match.otherUserId),
            name: match.name,
            player: widget.player,
            avatars: widget.avatars,
            onChat: () {
              Navigator.of(cardContext).pop();
              _open(match);
            },
          ),
        ),
      );

  Future<void> _openBand(String bandId) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BandChatScreen(
        bands: widget.bands!,
        bandId: bandId,
        matches: _live,
        avatars: widget.avatars,
        safety: widget.safety,
        player: widget.player,
        rehearsals: widget.rehearsals,
        songs: widget.songs,
      ),
    ),
  );

  Future<void> _createBand() async {
    final bands = widget.bands!;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateBandDialog(),
    );
    if (name == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await bands.repository.create(name);
      await bands.refresh();
      if (mounted) await _openBand(id);
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _withdraw(MyBandRequest request) async {
    final bands = widget.bands!;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      await bands.repository.withdrawRequest(request.proposalId);
      await bands.refresh();
      messenger.showSnackBar(SnackBar(content: Text(t.bandWithdrawn)));
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _answer(BandInvite invite, {required bool accept}) async {
    final bands = widget.bands!;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      await bands.repository.answerInvite(invite.proposalId, accept: accept);
      await bands.refresh();
      if (accept) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.bandJoined(invite.bandName))),
        );
      }
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Opens a band's page, where its votes are.
  Future<void> _openBandPage(String bandId) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BandScreen(
        bands: widget.bands!,
        bandId: bandId,
        matches: _live,
        avatars: widget.avatars,
        player: widget.player,
        rehearsals: widget.rehearsals,
        songs: widget.songs,
      ),
    ),
  );

  /// A vote on a request to join (Reject asks first). The person joins as
  /// soon as the last member approves.
  Future<void> _voteOnRequest(
    MyBand band,
    BandProposal p, {
    required bool approve,
  }) async {
    final bands = widget.bands!;
    if (!approve && !await confirmReject(context, p.candidate.name)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      await bands.repository.vote(p.id, approve: approve);
      await bands.refresh();
      if (approve &&
          (bands.bandById(band.id)?.hasMember(p.candidate.id) ?? false)) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.bandMemberJoined(p.candidate.name))),
        );
      }
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Loading and error states while [bands] has nothing yet, else null.
  Widget? _bandsNotReady(LiveBands bands) {
    if (bands.bands != null) return null;
    final error = bands.error;
    if (error != null) {
      return _Message(
        text: error is UserFacingException
            ? error.message
            : context.t.errBandAction,
        action: context.t.tryAgain,
        onAction: bands.refresh,
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  /// Requests: invites to you, votes waiting in your bands, then the bands
  /// you asked to join.
  Widget _requestsPage(LiveBands bands) {
    final t = context.t;
    final notReady = _bandsNotReady(bands);
    if (notReady != null) return notReady;
    final me = bands.repository.myId;
    final votes = [
      for (final band in bands.bands!) ...[
        for (final p in band.proposals)
          if (!p.requested && !p.invited && !p.approvedBy.contains(me))
            _VoteTile(
              person: p.candidate,
              line: p.proposedBy == null
                  ? t.requestVoteAsked(band.name)
                  : t.requestVoteProposed(band.name, p.proposedBy!.name),
              avatars: widget.avatars,
              onTap: () => _openBandPage(band.id),
            ),
        for (final r in band.removals)
          if (!r.votedBy.contains(me))
            _VoteTile(
              person: r.target,
              line: t.requestVoteRemoval(band.name),
              avatars: widget.avatars,
              onTap: () => _openBandPage(band.id),
            ),
      ],
    ];
    // Requests to join your bands (Jams on their cards), voted on right here
    // (owner, 2026-10-30), until every member has said yes.
    final asked = [
      for (final band in bands.bands!)
        for (final p in band.proposals)
          if (p.requested && !p.invited)
            ProposalCard(
              proposal: p,
              memberCount: band.members.length,
              me: me,
              avatars: widget.avatars,
              bandName: band.name,
              onSeeCard: () => showBandPersonCard(
                context,
                repository: bands.repository,
                person: p.candidate,
                player: widget.player,
                avatars: widget.avatars,
              ),
              onVote: (approve) => _voteOnRequest(band, p, approve: approve),
            ),
    ];
    if (bands.invites.isEmpty &&
        asked.isEmpty &&
        votes.isEmpty &&
        bands.requests.isEmpty) {
      return _Message(text: t.requestsEmpty);
    }
    return RefreshIndicator(
      onRefresh: bands.refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (bands.invites.isNotEmpty) ...[
            _SectionHeading(t.requestsInvites),
            for (final invite in bands.invites)
              _InviteCard(
                invite: invite,
                onAnswer: (accept) => _answer(invite, accept: accept),
              ),
          ],
          if (asked.isNotEmpty) ...[
            _SectionHeading(t.bandRequestsHeading),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: asked),
            ),
          ],
          if (votes.isNotEmpty) ...[_SectionHeading(t.requestsVotes), ...votes],
          if (bands.requests.isNotEmpty) ...[
            _SectionHeading(t.requestsMine),
            for (final request in bands.requests)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: OctavaColors.yellow,
                  foregroundColor: OctavaColors.ink,
                  child: Icon(Icons.hourglass_top_rounded),
                ),
                title: Text(
                  request.bandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(t.bandRequestWaiting),
                trailing: TextButton(
                  onPressed: () => _withdraw(request),
                  child: Text(t.bandWithdraw),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Bands: Create a band, then one row per band.
  Widget _bandsPage(LiveBands bands) {
    final t = context.t;
    final notReady = _bandsNotReady(bands);
    if (notReady != null) return notReady;
    final me = bands.repository.myId;
    final mine = bands.bands!;
    return RefreshIndicator(
      onRefresh: bands.refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: OutlinedButton.icon(
              onPressed: _createBand,
              icon: const Icon(Icons.add),
              label: Text(t.bandCreate),
            ),
          ),
          if (mine.isEmpty)
            _Message(text: t.bandsEmpty)
          else
            for (final band in mine)
              _BandTile(
                band: band,
                votesWaiting: band.bandPageVotesFor(me),
                onTap: () => _openBand(band.id),
              ),
        ],
      ),
    );
  }

  Widget _messagesPage() {
    final colors = Theme.of(context).colorScheme;
    final matches = _live.matches;
    final error = _live.error;
    if (error != null && matches == null) {
      return _Message(
        text: error is UserFacingException
            ? error.message
            : context.t.errLoadMatches,
        action: context.t.tryAgain,
        onAction: _live.refresh,
      );
    }
    if (matches == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (matches.isEmpty) {
      return _Message(text: context.t.matchesEmpty);
    }
    return RefreshIndicator(
      onRefresh: _live.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: matches.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: colors.outlineVariant),
        itemBuilder: (context, i) => _MatchTile(
          match: matches[i],
          avatars: widget.avatars,
          onTap: () => _open(matches[i]),
          onCard: () => _openCard(matches[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final bands = widget.bands;
    // Requests and Bands need bands; without them, Messages.
    final page = bands == null ? InboxPage.messages : widget.page;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(switch (page) {
          InboxPage.messages => t.navMessages,
          InboxPage.requests => t.navRequests,
          InboxPage.bands => t.bandsTitle,
        }, style: displayStyle(size: 32, color: colors.onSurface)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: Listenable.merge([_live, ?bands]),
            builder: (context, _) => switch (page) {
              InboxPage.messages => _messagesPage(),
              InboxPage.requests => _requestsPage(bands!),
              InboxPage.bands => _bandsPage(bands!),
            },
          ),
        ),
      ),
    );
  }
}

/// A vote waiting for you in one of your bands; opens the band's page,
/// where you vote (and can see their card).
class _VoteTile extends StatelessWidget {
  const _VoteTile({
    required this.person,
    required this.line,
    required this.onTap,
    this.avatars,
  });

  final BandPerson person;
  final String line;
  final VoidCallback onTap;
  final AvatarRepository? avatars;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: PersonAvatar(
      name: person.name,
      avatarPath: person.avatarPath,
      avatars: avatars,
    ),
    title: Text(
      person.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    required this.onTap,
    required this.onCard,
    this.avatars,
  });

  final MatchSummary match;
  final AvatarRepository? avatars;
  final VoidCallback onTap;

  /// Tapping their picture opens their card.
  final VoidCallback onCard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = match.unreadCount > 0;
    final preview = match.lastMessage == null
        ? context.t.newMatchSayHi
        : (match.lastMessageIsMine
              ? context.t.youPrefix(match.lastMessage!)
              : match.lastMessage!);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Tooltip(
        message: context.t.seeTheirCard,
        child: InkResponse(
          onTap: onCard,
          radius: 28,
          child: PersonAvatar(
            name: match.name,
            avatarPath: match.avatarPath,
            avatars: avatars,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: match.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: '  ${match.instrument}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatMessageTime(match.lastActivity),
            style: TextStyle(
              fontSize: 13,
              color: unread ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
      trailing: unread
          ? Badge(
              label: Text('${match.unreadCount}'),
              backgroundColor: OctavaColors.pink,
              textColor: OctavaColors.ink,
            )
          : null,
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: match.lastMessage == null || unread
              ? colors.onSurface
              : colors.onSurfaceVariant,
          fontWeight: match.lastMessage == null || unread
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (action != null)
            OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: displayStyle(
              size: 26,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}

/// An invite to join a band, with who's in it, and Accept / Decline.
class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.onAnswer});

  final BandInvite invite;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: printBox(
        context,
        color: OctavaColors.yellow,
        radius: 20,
        borderColor: OctavaColors.ink,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            t.bandInviteTitle(invite.bandName),
            style: displayStyle(size: 24, color: OctavaColors.ink),
          ),
          Text(
            listJoin([
              for (final m in invite.members) '${m.name} (${m.instrument})',
            ]),
            style: TextStyle(color: OctavaColors.ink),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => onAnswer(true),
                child: Text(t.bandAccept),
              ),
              OutlinedButton(
                onPressed: () => onAnswer(false),
                child: Text(t.bandDecline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BandTile extends StatelessWidget {
  const _BandTile({
    required this.band,
    required this.votesWaiting,
    required this.onTap,
  });

  final MyBand band;
  final int votesWaiting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final waiting = votesWaiting > 0;
    final unread = band.unreadCount;
    final last = band.lastMessage;
    final bold = waiting || unread > 0;
    // Votes come first; then the latest message; then who's in it.
    final subtitle = waiting
        ? t.bandVotesWaiting(votesWaiting)
        : last != null
        ? t.bandMessagePreview(last.senderName, last.body)
        : t.bandMemberCount(band.members.length);
    final count = votesWaiting + unread;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: OctavaColors.aqua,
        foregroundColor: OctavaColors.ink,
        child: Icon(Icons.groups_rounded),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              band.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (last != null)
            Text(
              formatMessageTime(last.sentAt),
              style: TextStyle(
                fontSize: 13,
                color: bold ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: bold ? colors.onSurface : colors.onSurfaceVariant,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: count > 0
          ? Badge(
              label: Text('$count'),
              backgroundColor: OctavaColors.pink,
              textColor: OctavaColors.ink,
            )
          : null,
    );
  }
}

/// Asks for the new band's name. Pops it, trimmed, or null.
class _CreateBandDialog extends StatefulWidget {
  const _CreateBandDialog();

  @override
  State<_CreateBandDialog> createState() => _CreateBandDialogState();
}

class _CreateBandDialogState extends State<_CreateBandDialog> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = context.t.bandNameError;
      });
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.bandCreateTitle),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: t.bandNameLabel,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(t.bandCreateConfirm)),
      ],
    );
  }
}
