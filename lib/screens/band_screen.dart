import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../models/band_group.dart';
import '../models/chat.dart';
import '../theme.dart';
import '../widgets/person_avatar.dart';

/// One of your bands: its members, the people proposed to join (with your
/// vote), Add member and Leave band. Updates live.
class BandScreen extends StatefulWidget {
  const BandScreen({
    super.key,
    required this.bands,
    required this.bandId,
    this.matches,
    this.avatars,
  });

  final LiveBands bands;
  final String bandId;

  /// Your matches, to pick who to propose. Without it there's no Add member.
  final LiveUpdates? matches;

  final AvatarRepository? avatars;

  @override
  State<BandScreen> createState() => _BandScreenState();
}

class _BandScreenState extends State<BandScreen> {
  bool _busy = false;

  String get _me => widget.bands.repository.myId;

  /// Runs a band action, then reloads. Problems show as a message.
  Future<bool> _run(Future<void> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
    });
    try {
      await action();
      await widget.bands.refresh();
      if (done != null) {
        messenger.showSnackBar(SnackBar(content: Text(done)));
      }
      return true;
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _addMember(MyBand band) async {
    final t = context.t;
    final picked = await showModalBottomSheet<MatchSummary>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PickMatchSheet(
        matches: [
          for (final m in widget.matches?.matches ?? const <MatchSummary>[])
            if (!band.hasMember(m.otherUserId) &&
                !band.proposals.any((p) => p.candidate.id == m.otherUserId))
              m,
        ],
        avatars: widget.avatars,
      ),
    );
    if (picked == null || !mounted) return;
    var invitedNow = false;
    final ok = await _run(() async {
      invitedNow = await widget.bands.repository.propose(
        band.id,
        picked.otherUserId,
      );
    });
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          invitedNow
              ? t.bandProposedInvite(picked.name)
              : t.bandProposedVote(picked.name),
        ),
      ),
    );
  }

  Future<void> _vote(BandProposal p, {required bool approve}) async {
    if (!approve) {
      final t = context.t;
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.bandRejectTitle(p.candidate.name)),
          content: Text(t.bandRejectBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.bandReject),
            ),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }
    await _run(() => widget.bands.repository.vote(p.id, approve: approve));
  }

  Future<void> _cancel(BandProposal p) async {
    final t = context.t;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.bandCancelTitle(p.candidate.name)),
        content: Text(t.bandCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.bandCancelKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.bandCancelRequest),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run(
      () => widget.bands.repository.cancel(p.id),
      done: t.bandCancelled(p.candidate.name),
    );
  }

  Future<void> _leave(MyBand band) async {
    final t = context.t;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.bandLeaveTitle(band.name)),
        content: Text(t.bandLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.bandLeave),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final navigator = Navigator.of(context);
    if (await _run(() => widget.bands.repository.leave(band.id))) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.bands,
      builder: (context, _) {
        final band = widget.bands.bandById(widget.bandId);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              band?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (band != null)
                PopupMenuButton<void>(
                  tooltip: t.chatMore,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () => _leave(band),
                      child: Text(t.bandLeave),
                    ),
                  ],
                ),
            ],
          ),
          body: band == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AbsorbPointer(
                      absorbing: _busy,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _Heading(t.bandMembers),
                          for (final m in band.members)
                            _PersonTile(
                              person: m,
                              avatars: widget.avatars,
                              trailing: m.id == _me
                                  ? Text(
                                      t.bandYou,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          if (widget.matches != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _addMember(band),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: Text(t.bandAddMember),
                              ),
                            ),
                          ],
                          if (band.proposals.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _Heading(t.bandWaiting),
                            for (final p in band.proposals)
                              _ProposalCard(
                                proposal: p,
                                memberCount: band.members.length,
                                me: _me,
                                avatars: widget.avatars,
                                onVote: (approve) => _vote(p, approve: approve),
                                // Yours, or left behind by someone who left.
                                onCancel:
                                    p.proposedBy?.id == _me ||
                                        !band.hasMember(p.proposedBy?.id ?? '')
                                    ? () => _cancel(p)
                                    : null,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
    child: Text(
      text,
      style: displayStyle(
        size: 26,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, this.avatars, this.trailing});

  final BandPerson person;
  final AvatarRepository? avatars;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
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
    subtitle: Text(person.instrument),
    trailing: trailing,
  );
}

/// Someone proposed to join: who proposed them, how many approved, and your
/// Approve / Reject (or where it stands).
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.memberCount,
    required this.me,
    required this.onVote,
    this.onCancel,
    this.avatars,
  });

  /// Shown as Cancel request when you may withdraw it.
  final VoidCallback? onCancel;

  final BandProposal proposal;
  final int memberCount;
  final String me;
  final ValueChanged<bool> onVote;
  final AvatarRepository? avatars;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final p = proposal;
    final status = p.invited
        ? t.bandInvited
        : t.bandApprovals(p.approvedBy.length, memberCount);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
      decoration: printBox(context, radius: 20, shadow: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PersonTile(person: p.candidate, avatars: avatars),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              [
                if (p.proposedBy case final by?) t.bandProposedBy(by.name),
                status,
              ].join(' · '),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
          if (onCancel != null && (p.invited || p.approvedBy.contains(me)))
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  if (!p.invited)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: OctavaColors.pink,
                        ),
                        Text(
                          t.bandYouApproved,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(t.bandCancelRequest),
                  ),
                ],
              ),
            )
          else if (!p.invited) ...[
            const SizedBox(height: 10),
            if (p.approvedBy.contains(me))
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  spacing: 6,
                  children: [
                    const Icon(Icons.check_circle, color: OctavaColors.pink),
                    Text(
                      t.bandYouApproved,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => onVote(true),
                      child: Text(t.bandApprove),
                    ),
                    OutlinedButton(
                      onPressed: () => onVote(false),
                      child: Text(t.bandReject),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Your matches who aren't in the band or already proposed.
class _PickMatchSheet extends StatelessWidget {
  const _PickMatchSheet({required this.matches, this.avatars});

  final List<MatchSummary> matches;
  final AvatarRepository? avatars;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                t.bandAddMemberTitle,
                style: displayStyle(
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Text(t.bandAddMemberEmpty),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final m in matches)
                      ListTile(
                        leading: PersonAvatar(
                          name: m.name,
                          avatarPath: m.avatarPath,
                          avatars: avatars,
                        ),
                        title: Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(m.instrument),
                        onTap: () => Navigator.pop(context, m),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
