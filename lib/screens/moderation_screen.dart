import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/avatar_repository.dart';
import '../data/clip_repository.dart';
import '../data/moderation_repository.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/musician_card.dart';

/// Open reports for moderators: who was reported and why, by whom, the
/// quoted message, their recent messages to the reporter (one-on-one
/// reports), View profile, and Dismiss / Remove message / Suspend (asks
/// first). A suspended person's later reports offer Lift suspension.
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({
    super.key,
    required this.repository,
    this.player,
    this.avatars,
  });

  final ModerationRepository repository;

  /// For the reported person's card (clip and avatar).
  final ClipPlayer? player;
  final AvatarRepository? avatars;

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  late Future<List<ModReport>> _reports = widget.repository.openReports();
  bool _busy = false;

  void _reload() => setState(() {
    _reports = widget.repository.openReports();
  });

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
    });
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      _reload();
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _suspend(ModReport r) async {
    final t = context.t;
    final name = r.reportedName ?? '?';
    final colors = Theme.of(context).colorScheme;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.modSuspendTitle(name)),
        content: Text(t.modSuspendBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
              side: BorderSide(color: colors.error, width: 2),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.modSuspend),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run(
      () => widget.repository.resolve(r.id, ModAction.suspend),
      t.modSuspendedDone(name),
    );
  }

  void _viewProfile(ModReport r) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ModProfileScreen(
        repository: widget.repository,
        personId: r.reportedId,
        name: r.reportedName ?? '?',
        player: widget.player,
        avatars: widget.avatars,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.modReports)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: FutureBuilder<List<ModReport>>(
          future: _reports,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Text(
                      snap.error is UserFacingException
                          ? (snap.error as UserFacingException).message
                          : t.errModeration,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error),
                    ),
                    TextButton(onPressed: _reload, child: Text(t.tryAgain)),
                  ],
                ),
              );
            }
            final reports = snap.data!;
            if (reports.isEmpty) {
              return Center(
                child: Text(
                  t.modEmpty,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ReportCard(
                      report: reports[i],
                      onViewProfile: () => _viewProfile(reports[i]),
                      onDismiss: () => _run(
                        () => widget.repository.resolve(
                          reports[i].id,
                          ModAction.dismiss,
                        ),
                        t.modDismissed,
                      ),
                      onRemoveMessage: () => _run(
                        () => widget.repository.resolve(
                          reports[i].id,
                          ModAction.removeMessage,
                        ),
                        t.modMessageRemoved,
                      ),
                      onSuspend: () => _suspend(reports[i]),
                      onUnsuspend: () => _run(
                        () =>
                            widget.repository.unsuspend(reports[i].reportedId),
                        t.modUnsuspended,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onViewProfile,
    required this.onDismiss,
    required this.onRemoveMessage,
    required this.onSuspend,
    required this.onUnsuspend,
  });

  final ModReport report;
  final VoidCallback onViewProfile;
  final VoidCallback onDismiss;
  final VoidCallback onRemoveMessage;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final r = report;
    final when = DateFormat.MMMd(L10n.current.localeName)
        .add_Hm()
        .format(r.createdAt);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  r.reportedName ?? '?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Tag(
                text: reportReasonLabels[r.reason] ?? r.reason,
                color: OctavaColors.pinkTint,
              ),
            ],
          ),
          Text(
            t.modReportedBy(r.reporterName ?? '?', when),
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          if ((r.details ?? '').isNotEmpty) Text(r.details!),
          if (r.reportedText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r.messageStillThere
                    ? '“${r.reportedText}”'
                    : '“${r.reportedText}”\n${t.modMessageGone}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          if (r.evidence.isNotEmpty)
            _Evidence(messages: r.evidence, reporter: r.reporterName ?? '?'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(
                text: t.modAgainstCount(r.openAgainst),
                color: OctavaColors.yellow,
              ),
              if (r.reportedSuspended)
                _Tag(text: t.modSuspended, color: OctavaColors.aqua)
              else if (r.openAgainst >= 3)
                _Tag(text: t.modHiddenFromFeed, color: OctavaColors.aqua),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton(
                onPressed: onViewProfile,
                child: Text(t.modViewProfile),
              ),
              TextButton(onPressed: onDismiss, child: Text(t.modDismiss)),
              if (r.messageStillThere)
                TextButton(
                  onPressed: onRemoveMessage,
                  child: Text(t.modRemoveMessage),
                ),
              if (r.reportedSuspended)
                TextButton(onPressed: onUnsuspend, child: Text(t.modUnsuspend))
              else
                TextButton(
                  onPressed: onSuspend,
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  child: Text(t.modSuspend),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The reported person's recent messages to the reporter, folded until
/// opened (there can be 20).
class _Evidence extends StatefulWidget {
  const _Evidence({required this.messages, required this.reporter});
  final List<ModEvidence> messages;
  final String reporter;

  @override
  State<_Evidence> createState() => _EvidenceState();
}

class _EvidenceState extends State<_Evidence> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final clock = DateFormat.MMMd(L10n.current.localeName).add_Hm();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() {
                _open = !_open;
              }),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  spacing: 6,
                  children: [
                    const Icon(Icons.forum_outlined, size: 18),
                    Expanded(
                      child: Text(
                        t.modEvidenceTitle(
                          widget.messages.length,
                          widget.reporter,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(_open ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    for (final m in widget.messages)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clock.format(m.at),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            m.isVoice
                                ? '${t.voiceMessage} · ${clipLength(m.voiceSeconds!)}'
                                : m.body ?? '',
                          ),
                        ],
                      ),
                    Text(
                      t.modEvidenceNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
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

/// The reported person's card as others see it, plus when they joined.
class ModProfileScreen extends StatefulWidget {
  const ModProfileScreen({
    super.key,
    required this.repository,
    required this.personId,
    required this.name,
    this.player,
    this.avatars,
  });

  final ModerationRepository repository;
  final String personId;
  final String name;
  final ClipPlayer? player;
  final AvatarRepository? avatars;

  @override
  State<ModProfileScreen> createState() => _ModProfileScreenState();
}

class _ModProfileScreenState extends State<ModProfileScreen> {
  late final Future<ModProfile?> _profile = widget.repository.profile(
    widget.personId,
  );

  @override
  void dispose() {
    widget.player?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: FutureBuilder<ModProfile?>(
              future: _profile,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      t.errModeration,
                      style: TextStyle(color: colors.error),
                    ),
                  );
                }
                final p = snap.data;
                if (p == null) {
                  return Center(child: Text(t.modProfileGone));
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (p.joinedAt != null)
                            _Tag(
                              text: t.modJoined(
                                DateFormat.yMMMd(
                                  L10n.current.localeName,
                                ).format(p.joinedAt!),
                              ),
                              color: OctavaColors.yellow,
                            ),
                          if (p.suspended)
                            _Tag(
                              text: t.modSuspended,
                              color: OctavaColors.aqua,
                            ),
                        ],
                      ),
                      Expanded(
                        child: MusicianCard(
                          musician: p.card,
                          tone: const [
                            OctavaColors.pink,
                            OctavaColors.yellow,
                            OctavaColors.aqua,
                          ][p.card.toneIndex],
                          fitsOpenSlot: false,
                          player: widget.player,
                          avatars: widget.avatars,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A small coloured label (fills stay the same in dark mode, so dark text).
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: OctavaColors.ink,
      ),
    ),
  );
}
