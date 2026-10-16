import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/rehearsal_repository.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../models/band_group.dart';
import '../models/rehearsal.dart';
import '../screens/rehearsal_form_screen.dart';
import '../theme.dart';

/// "Fri, Oct 23 · 19:00–21:00", in the app's language.
String rehearsalWhen(RehearsalDate d) {
  final locale = L10n.current.localeName;
  return '${DateFormat.MMMEd(locale).format(d.startsAt)} · '
      '${DateFormat.Hm(locale).format(d.startsAt)}–'
      '${DateFormat.Hm(locale).format(d.endsAt)}';
}

/// The band page's calendar: upcoming rehearsals with Going / Can't, Add
/// rehearsal, and a sheet per date (who's coming, edit, call off, delete).
/// Updates live.
class RehearsalsSection extends StatefulWidget {
  const RehearsalsSection({
    super.key,
    required this.repository,
    required this.band,
  });

  final RehearsalRepository repository;
  final MyBand band;

  @override
  State<RehearsalsSection> createState() => _RehearsalsSectionState();
}

class _RehearsalsSectionState extends State<RehearsalsSection> {
  List<RehearsalDate>? _dates;
  String? _error;
  bool _showAll = false;
  StreamSubscription<void>? _sub;

  /// The card shows this far ahead; "Show all" shows the rest.
  static const _preview = Duration(days: 7);

  String get _me => widget.repository.myId;

  @override
  void initState() {
    super.initState();
    _sub = widget.repository.changes().listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dates = await widget.repository.upcoming(widget.band.id);
      if (!mounted) return;
      setState(() {
        _dates = dates;
        _error = null;
      });
    } on UserFacingException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    }
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _load();
      if (done != null) {
        messenger.showSnackBar(SnackBar(content: Text(done)));
      }
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openForm({Rehearsal? editing}) async {
    final draft = await Navigator.of(context).push<RehearsalDraft>(
      MaterialPageRoute(builder: (_) => RehearsalFormScreen(initial: editing)),
    );
    if (draft == null || !mounted) return;
    final t = context.t;
    await _run(
      () => editing == null
          ? widget.repository.add(widget.band.id, draft)
          : widget.repository.update(editing.id, draft),
      done: editing == null ? t.rehearsalAdded : t.rehearsalSaved,
    );
  }

  Future<void> _openDate(RehearsalDate d) async {
    final t = context.t;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DateSheet(date: d, band: widget.band),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _openForm(editing: d.rehearsal);
      case 'cancel':
        await _run(
          () => widget.repository.setCancelled(d, cancelled: true),
          done: t.rehearsalCalledOff,
        );
      case 'restore':
        await _run(() => widget.repository.setCancelled(d, cancelled: false));
      case 'delete':
        final sure = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.rehearsalDeleteTitle),
            content: Text(
              d.rehearsal.weekly
                  ? t.rehearsalDeleteWeeklyBody
                  : t.rehearsalDeleteBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.rehearsalDelete),
              ),
            ],
          ),
        );
        if (sure == true) {
          await _run(
            () => widget.repository.delete(d.rehearsal.id),
            done: t.rehearsalDeleted,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final dates = _dates;
    final weekEnd = DateTime.now().add(_preview);
    final thisWeek = [
      for (final d in dates ?? const <RehearsalDate>[])
        if (d.startsAt.isBefore(weekEnd)) d,
    ];
    final shown = _showAll ? dates ?? const <RehearsalDate>[] : thisWeek;
    final more = (dates?.length ?? 0) > thisWeek.length;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: printBox(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.rehearsalsTitle,
                  style: displayStyle(size: 24, color: colors.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.rehearsalAdd),
              ),
            ],
          ),
          if (_error != null && dates == null)
            Text(_error!, style: TextStyle(color: colors.error))
          else if (dates == null)
            const Center(child: CircularProgressIndicator())
          else if (dates.isEmpty)
            Text(
              t.rehearsalsEmpty,
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else ...[
            if (shown.isEmpty)
              Text(
                t.rehearsalsNoneThisWeek,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            for (final d in shown)
              _DateTile(
                date: d,
                me: _me,
                onTap: () => _openDate(d),
                onAnswer: (going) =>
                    _run(() => widget.repository.answer(d, going: going)),
              ),
            if (more)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    _showAll = !_showAll;
                  }),
                  child: Text(
                    _showAll ? t.rehearsalsShowLess : t.rehearsalsShowAll,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One date: when and where, the counts, and your Going / Can't.
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.me,
    required this.onTap,
    required this.onAnswer,
  });

  final RehearsalDate date;
  final String me;
  final VoidCallback onTap;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final d = date;
    final mine = d.answers[me];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: d.cancelled ? null : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              spacing: 6,
              children: [
                if (d.rehearsal.weekly)
                  Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                Expanded(
                  child: Text(
                    rehearsalWhen(d),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: d.cancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if ((d.rehearsal.place ?? '').isNotEmpty)
              Text(
                d.rehearsal.place!,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            if (d.cancelled)
              Text(
                t.rehearsalCancelledLabel,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.rehearsalCounts(d.going, d.cant),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ChoiceChip(
                    label: Text(t.rehearsalGoing),
                    selected: mine == true,
                    onSelected: (_) => onAnswer(true),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(t.rehearsalCant),
                    selected: mine == false,
                    onSelected: (_) => onAnswer(false),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A date's details: who's going, who can't, who hasn't answered, and
/// Edit / Call off this date / Delete. Pops the chosen action.
class _DateSheet extends StatelessWidget {
  const _DateSheet({required this.date, required this.band});

  final RehearsalDate date;
  final MyBand band;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final d = date;
    List<String> names(bool? going) => [
      for (final m in band.members)
        if (d.answers[m.id] == going) m.name,
    ];
    Widget group(String label, List<String> people) => people.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$label: ${people.join(', ')}',
              style: TextStyle(color: colors.onSurface),
            ),
          );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              rehearsalWhen(d),
              style: displayStyle(size: 24, color: colors.onSurface),
            ),
            if ((d.rehearsal.place ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(d.rehearsal.place!),
              ),
            if ((d.rehearsal.notes ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  d.rehearsal.notes!,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            if (!d.cancelled) ...[
              group(t.rehearsalGoing, names(true)),
              group(t.rehearsalCant, names(false)),
              group(t.rehearsalNoAnswer, names(null)),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: Text(t.rehearsalEdit),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (d.rehearsal.weekly)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  d.cancelled ? Icons.event_available : Icons.event_busy,
                ),
                title: Text(
                  d.cancelled ? t.rehearsalRestore : t.rehearsalCallOff,
                ),
                onTap: () =>
                    Navigator.pop(context, d.cancelled ? 'restore' : 'cancel'),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(t.rehearsalDelete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
  }
}
