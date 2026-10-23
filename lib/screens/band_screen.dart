import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/bands_repository.dart';
import '../data/clip_repository.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/rehearsal_repository.dart';
import '../data/song_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../models/band_group.dart';
import '../models/chat.dart';
import '../models/musician.dart' show listJoin;
import '../theme.dart';
import '../widgets/person_avatar.dart';
import '../widgets/public_page_card.dart';
import '../widgets/record_sheet.dart';
import '../widgets/rehearsals_section.dart';
import '../widgets/setlists_section.dart';
import '../widgets/songs_section.dart';
import 'band_profile_screen.dart';
import 'match_card_screen.dart';

/// One of your bands: its public profile (Edit band, the band clip), its
/// members, the people proposed to join (with your vote), Add member and
/// Leave band. Updates live.
class BandScreen extends StatefulWidget {
  const BandScreen({
    super.key,
    required this.bands,
    required this.bandId,
    this.matches,
    this.avatars,
    this.player,
    this.rehearsals,
    this.songs,
  });

  /// The band's songs. Without it there's no Songs section.
  final SongRepository? songs;

  /// Plays the band clip.
  final ClipPlayer? player;

  /// The rehearsal calendar. Without it there's no Rehearsals section.
  final RehearsalRepository? rehearsals;

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

  void _openCard(BandPerson person) => showBandPersonCard(
    context,
    repository: widget.bands.repository,
    person: person,
    player: widget.player,
    avatars: widget.avatars,
  );

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

  Future<void> _editProfile(MyBand band) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BandProfileScreen(repository: widget.bands.repository, band: band),
      ),
    );
    if (saved == true) {
      await widget.bands.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.t.bandProfileSaved)));
      }
    }
  }

  Future<void> _recordClip(MyBand band) async {
    final t = context.t;
    await widget.player?.stop();
    if (!mounted) return;
    await showRecordSheet(
      context,
      save: ({required bytes, required fileName, int? knownSeconds}) =>
          widget.bands.repository.uploadClip(
            band.id,
            bytes: bytes,
            fileName: fileName,
            knownSeconds: knownSeconds,
          ),
      saveLabel: t.bandClipSave,
      savedMessage: t.bandClipSaved,
    );
    await widget.bands.refresh();
  }

  Future<void> _removeClip(MyBand band) async {
    final done = context.t.bandClipRemoved;
    await widget.player?.stop();
    await _run(() => widget.bands.repository.removeClip(band.id), done: done);
  }

  Future<void> _setPublic(MyBand band, bool public) {
    final t = context.t;
    return _run(
      () => widget.bands.repository.setPublic(band.id, public: public),
      done: public ? t.publicPageTurnedOn : t.publicPageTurnedOff,
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
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    await _run(() => widget.bands.repository.vote(p.id, approve: approve));
    // A request joins as soon as the last member approves.
    final band = widget.bands.bandById(widget.bandId);
    if (approve && p.requested && (band?.hasMember(p.candidate.id) ?? false)) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.bandMemberJoined(p.candidate.name))),
      );
    }
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

  Future<void> _proposeRemoval(MyBand band, BandPerson person) async {
    final t = context.t;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.bandRemoveTitle(person.name, band.name)),
        content: Text(t.bandRemoveBody(person.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.bandRemoveConfirm),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    var removedNow = false;
    final ok = await _run(() async {
      removedNow = await widget.bands.repository.proposeRemoval(
        band.id,
        person.id,
      );
    });
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removedNow
              ? t.bandRemovedNow(person.name)
              : t.bandRemoveStarted(person.name),
        ),
      ),
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
                          _BandProfileCard(
                            band: band,
                            player: widget.player,
                            onEdit: () => _editProfile(band),
                            onRecordClip: () => _recordClip(band),
                            onRemoveClip: () => _removeClip(band),
                          ),
                          PublicPageCard(
                            bandId: band.id,
                            isPublic: band.isPublic,
                            onChanged: (on) => _setPublic(band, on),
                          ),
                          if (widget.rehearsals case final rehearsals?)
                            RehearsalsSection(
                              repository: rehearsals,
                              band: band,
                              songs: widget.songs,
                              player: widget.player,
                            ),
                          if (widget.songs case final songs?)
                            SongsSection(
                              repository: songs,
                              bandId: band.id,
                              player: widget.player,
                            ),
                          if (widget.songs case final songs?)
                            SetlistsSection(
                              repository: songs,
                              bandId: band.id,
                              player: widget.player,
                            ),
                          _Heading(t.bandMembers),
                          for (final m in band.members)
                            _PersonTile(
                              person: m,
                              avatars: widget.avatars,
                              onTap: m.id == _me ? null : () => _openCard(m),
                              trailing: m.id == _me
                                  ? Text(
                                      t.bandYou,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  // Others: Remove from band (unless a vote
                                  // on that is already open).
                                  : band.removals.any(
                                      (r) => r.target.id == m.id,
                                    )
                                  ? null
                                  : PopupMenuButton<void>(
                                      tooltip: t.bandMemberOptions(m.name),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          onTap: () => _proposeRemoval(band, m),
                                          child: Text(t.bandRemoveMember),
                                        ),
                                      ],
                                    ),
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
                          if (band.removals.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _Heading(t.bandRemovalsHeading),
                            for (final r in band.removals)
                              _RemovalCard(
                                removal: r,
                                needed: r.neededIn(band.members.length),
                                me: _me,
                                avatars: widget.avatars,
                                onSeeCard: () => _openCard(r.target),
                                onVote: (yes) => _run(
                                  () => widget.bands.repository.voteRemoval(
                                    r.id,
                                    approve: yes,
                                  ),
                                ),
                                // Yours, or left by someone who left.
                                onCancel:
                                    r.proposedBy?.id == _me ||
                                        !band.hasMember(r.proposedBy?.id ?? '')
                                    ? () => _run(
                                        () => widget.bands.repository
                                            .cancelRemoval(r.id),
                                        done: t.bandRemovalCancelled,
                                      )
                                    : null,
                              ),
                          ],
                          // People who asked to join (Jam on the band card).
                          if (band.proposals.any((p) => p.requested)) ...[
                            const SizedBox(height: 16),
                            _Heading(t.bandRequestsHeading),
                            for (final p in band.proposals.where(
                              (p) => p.requested,
                            ))
                              _ProposalCard(
                                proposal: p,
                                memberCount: band.members.length,
                                me: _me,
                                avatars: widget.avatars,
                                onSeeCard: () => _openCard(p.candidate),
                                onVote: (approve) => _vote(p, approve: approve),
                              ),
                          ],
                          if (band.proposals.any((p) => !p.requested)) ...[
                            const SizedBox(height: 16),
                            _Heading(t.bandWaiting),
                            for (final p in band.proposals.where(
                              (p) => !p.requested,
                            ))
                              _ProposalCard(
                                proposal: p,
                                memberCount: band.members.length,
                                me: _me,
                                avatars: widget.avatars,
                                onSeeCard: () => _openCard(p.candidate),
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

/// Opens [person]'s swipe card (owner, 2026-10-23): a bandmate's, from the
/// band chat or the member list, or a candidate's, before voting on them.
Future<void> showBandPersonCard(
  BuildContext context, {
  required BandsRepository repository,
  required BandPerson person,
  ClipPlayer? player,
  AvatarRepository? avatars,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (_) => MatchCardScreen(
      load: () => repository.personCard(person.id),
      name: person.name,
      player: player,
      avatars: avatars,
    ),
  ),
);

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    this.avatars,
    this.trailing,
    this.onTap,
  });

  final BandPerson person;
  final AvatarRepository? avatars;
  final Widget? trailing;

  /// Opens their card.
  final VoidCallback? onTap;

  // Inside printBox cards the tap ripple needs its own transparent Material.
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: _tile(),
  );

  Widget _tile() => ListTile(
    onTap: onTap,
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
    this.onSeeCard,
  });

  /// Shown as Cancel request when you may withdraw it.
  final VoidCallback? onCancel;

  /// Opens the candidate's card, to see who they are before voting.
  final VoidCallback? onSeeCard;

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
          _PersonTile(
            person: p.candidate,
            avatars: avatars,
            onTap: onSeeCard,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              [
                if (p.requested)
                  t.bandAskedToJoinLabel
                else if (p.proposedBy case final by?)
                  t.bandProposedBy(by.name),
                status,
              ].join(' · '),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
          if (onSeeCard != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onSeeCard,
                icon: const Icon(Icons.style_outlined),
                label: Text(t.seeTheirCard),
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
                        Icon(Icons.check_circle, color: OctavaColors.pink),
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
                    Icon(Icons.check_circle, color: OctavaColors.pink),
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

/// The band's public profile, as others see it on its card: description,
/// genres, the roles it's looking for and its clip, with Edit band.
class _BandProfileCard extends StatelessWidget {
  const _BandProfileCard({
    required this.band,
    required this.onEdit,
    required this.onRecordClip,
    required this.onRemoveClip,
    this.player,
  });

  final MyBand band;
  final VoidCallback onEdit;
  final VoidCallback onRecordClip;
  final VoidCallback onRemoveClip;
  final ClipPlayer? player;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final clip = band.clipPath;
    final empty =
        (band.description ?? '').isEmpty &&
        band.genres.isEmpty &&
        band.openRoles.isEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: printBox(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.bandProfileTitle,
                  style: displayStyle(size: 24, color: colors.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(t.bandEdit),
              ),
            ],
          ),
          if (empty)
            Text(
              t.bandProfileEmpty,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          if ((band.description ?? '').isNotEmpty) Text(band.description!),
          if (band.openRoles.isNotEmpty)
            Text(
              t.bandLookingFor(
                listJoin([for (final r in band.openRoles) instrumentLabel(r)]),
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          if (band.genres.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in band.genres)
                  Chip(
                    label: Text(genreLabel(g)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          // The band's clip: play it, record or upload a new one, remove it.
          Row(
            children: [
              if (clip != null && player != null)
                ValueListenableBuilder<String?>(
                  valueListenable: player!.playing,
                  builder: (context, playing, _) {
                    final on = playing == bandClipKey(clip);
                    return IconButton.filled(
                      tooltip: on ? t.bandClipStop : t.bandClipPlay,
                      onPressed: () => player!.toggle(bandClipKey(clip)),
                      style: IconButton.styleFrom(
                        backgroundColor: OctavaColors.pink,
                        foregroundColor: OctavaColors.ink,
                      ),
                      icon: Icon(
                        on ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      ),
                    );
                  },
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clip == null
                      ? t.bandClipNone
                      : t.bandClipLength(clipLength(band.clipSeconds ?? 0)),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              IconButton(
                tooltip: clip == null ? t.bandClipAdd : t.bandClipReplace,
                onPressed: onRecordClip,
                icon: const Icon(Icons.mic_none_rounded),
              ),
              if (clip != null)
                IconButton(
                  tooltip: t.bandClipRemove,
                  onPressed: onRemoveClip,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vote on removing a member: how many have agreed out of how many are
/// needed, and your Remove / Keep (or Cancel vote, if you started it).
class _RemovalCard extends StatelessWidget {
  const _RemovalCard({
    required this.removal,
    required this.needed,
    required this.me,
    required this.onVote,
    this.onCancel,
    this.avatars,
    this.onSeeCard,
  });

  final VoidCallback? onSeeCard;
  final BandRemoval removal;
  final int needed;
  final String me;
  final ValueChanged<bool> onVote;
  final VoidCallback? onCancel;
  final AvatarRepository? avatars;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final r = removal;
    final voted = r.votedBy.contains(me);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
      decoration: printBox(context, radius: 20, shadow: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PersonTile(person: r.target, avatars: avatars, onTap: onSeeCard),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              [
                if (r.proposedBy case final by?) t.bandProposedBy(by.name),
                t.bandRemovalCount(r.yesBy.length, needed),
              ].join(' · '),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!voted) ...[
                  FilledButton(
                    onPressed: () => onVote(true),
                    child: Text(t.bandRemovalYes),
                  ),
                  OutlinedButton(
                    onPressed: () => onVote(false),
                    child: Text(t.bandRemovalNo),
                  ),
                ] else
                  Text(
                    r.yesBy.contains(me) ? t.bandYouAgreed : t.bandYouDisagreed,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(t.bandRemovalCancel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
