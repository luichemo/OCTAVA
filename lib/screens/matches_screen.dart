import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/avatar_repository.dart';
import '../data/chat_repository.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../models/band_group.dart';
import '../models/chat.dart';
import '../models/musician.dart' show listJoin;
import '../theme.dart';
import '../widgets/person_avatar.dart';
import 'band_screen.dart';
import 'chat_screen.dart';

/// Your bands and band invites (with [bands]), then everyone you've matched
/// with, newest activity first, updated live. Tap a match to chat.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
    required this.repository,
    this.live,
    this.safety,
    this.avatars,
    this.bands,
  });

  /// Your bands and invites, shown above the matches. Without it, matches only.
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
        ),
      ),
    );
    // Blocking in the chat removes it from the list.
    if (mounted) _live.refresh();
  }

  Future<void> _openBand(String bandId) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BandScreen(
        bands: widget.bands!,
        bandId: bandId,
        matches: _live,
        avatars: widget.avatars,
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

  /// The Bands section: Create a band, invites and your bands.
  List<Widget> _bandItems(LiveBands bands) {
    final t = context.t;
    final me = bands.repository.myId;
    final error = bands.error;
    return [
      _SectionHeading(
        t.bandsTitle,
        action: TextButton.icon(
          onPressed: _createBand,
          icon: const Icon(Icons.add),
          label: Text(t.bandCreate),
        ),
      ),
      for (final invite in bands.invites)
        _InviteCard(
          invite: invite,
          onAnswer: (accept) => _answer(invite, accept: accept),
        ),
      for (final band in bands.bands ?? const <MyBand>[])
        _BandTile(
          band: band,
          votesWaiting: band.votesWaitingFor(me),
          onTap: () => _openBand(band.id),
        ),
      if (bands.bands == null && error is UserFacingException)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(error.message),
        ),
      _SectionHeading(t.navMatches),
    ];
  }

  /// Bands first, then matches, in one scrolling list.
  Widget _withBands(LiveBands bands) {
    final colors = Theme.of(context).colorScheme;
    final matches = _live.matches;
    final error = _live.error;
    return RefreshIndicator(
      onRefresh: () => Future.wait([_live.refresh(), bands.refresh()]),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          ..._bandItems(bands),
          if (matches == null && error != null)
            _Message(
              text: error is UserFacingException
                  ? error.message
                  : context.t.errLoadMatches,
              action: context.t.tryAgain,
              onAction: _live.refresh,
            )
          else if (matches == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (matches.isEmpty)
            _Message(text: context.t.matchesEmpty)
          else
            for (final (i, m) in matches.indexed) ...[
              if (i > 0) Divider(height: 1, color: colors.outlineVariant),
              _MatchTile(
                match: m,
                avatars: widget.avatars,
                onTap: () => _open(m),
              ),
            ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bands = widget.bands;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          context.t.navMatches,
          style: displayStyle(size: 32, color: colors.onSurface),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: Listenable.merge([_live, ?bands]),
            builder: (context, _) {
              if (bands != null) return _withBands(bands);
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.onTap, this.avatars});

  final MatchSummary match;
  final AvatarRepository? avatars;
  final VoidCallback onTap;

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
      leading: PersonAvatar(
        name: match.name,
        avatarPath: match.avatarPath,
        avatars: avatars,
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
  const _SectionHeading(this.text, {this.action});

  final String text;
  final Widget? action;

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
        ?action,
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
            style: const TextStyle(color: OctavaColors.ink),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: const CircleAvatar(
        radius: 24,
        backgroundColor: OctavaColors.aqua,
        foregroundColor: OctavaColors.ink,
        child: Icon(Icons.groups_rounded),
      ),
      title: Text(
        band.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        waiting
            ? t.bandVotesWaiting(votesWaiting)
            : t.bandMemberCount(band.members.length),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: waiting ? colors.onSurface : colors.onSurfaceVariant,
          fontWeight: waiting ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: waiting
          ? Badge(
              label: Text('$votesWaiting'),
              backgroundColor: OctavaColors.pink,
              textColor: OctavaColors.ink,
            )
          : const Icon(Icons.chevron_right),
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
