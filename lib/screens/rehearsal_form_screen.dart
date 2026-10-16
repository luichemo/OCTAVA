import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/rehearsal.dart';
import '../models/setlist.dart';
import '../theme.dart';

/// Adds or edits a rehearsal: day, start time, length, place, notes and
/// "Repeat every week" (optionally until a day), and the setlist to
/// practise. Pops a [RehearsalDraft].
class RehearsalFormScreen extends StatefulWidget {
  const RehearsalFormScreen({
    super.key,
    this.initial,
    this.setlists = const [],
  });

  /// The rehearsal being edited; null to add one.
  final Rehearsal? initial;

  /// The band's setlists to choose from. Without any there's no choice.
  final List<Setlist> setlists;

  @override
  State<RehearsalFormScreen> createState() => _RehearsalFormScreenState();
}

class _RehearsalFormScreenState extends State<RehearsalFormScreen> {
  late DateTime _day;
  late TimeOfDay _time;
  late int _minutes = widget.initial?.durationMinutes ?? 120;
  late final _place = TextEditingController(text: widget.initial?.place ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late bool _weekly = widget.initial?.weekly ?? false;
  late DateTime? _until = widget.initial?.repeatUntil;
  late String? _setlistId = widget.initial?.setlistId;

  static const _lengths = [30, 60, 90, 120, 150, 180, 240];

  @override
  void initState() {
    super.initState();
    final start =
        widget.initial?.startsAt ??
        // Default: tomorrow at 19:00.
        DateTime.now().add(const Duration(days: 1));
    _day = DateTime(start.year, start.month, start.day);
    _time = widget.initial == null
        ? const TimeOfDay(hour: 19, minute: 0)
        : TimeOfDay.fromDateTime(start);
  }

  @override
  void dispose() {
    _place.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _day = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<void> _pickUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until ?? _day.add(const Duration(days: 56)),
      firstDate: _day,
      lastDate: _day.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _until = picked;
      });
    }
  }

  void _save() {
    Navigator.pop<RehearsalDraft>(context, (
      startsAt: DateTime(
        _day.year,
        _day.month,
        _day.day,
        _time.hour,
        _time.minute,
      ),
      durationMinutes: _minutes,
      place: _place.text,
      notes: _notes.text,
      weekly: _weekly,
      repeatUntil: _weekly ? _until : null,
      setlistId: widget.setlists.any((s) => s.id == _setlistId)
          ? _setlistId
          : null,
    ));
  }

  String _length(int minutes) {
    final t = context.t;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h == 0
        ? t.durationMinutes(m)
        : m == 0
        ? t.durationHours(h)
        : t.durationHoursMinutes(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = L10n.current.localeName;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? t.rehearsalAddTitle : t.rehearsalEditTitle,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(t.rehearsalDay),
                subtitle: Text(DateFormat.yMMMEd(locale).format(_day)),
                onTap: _pickDay,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(t.rehearsalStart),
                subtitle: Text(_time.format(context)),
                onTap: _pickTime,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timelapse_outlined),
                title: Text(t.rehearsalLength),
                trailing: DropdownButton<int>(
                  value: _lengths.contains(_minutes) ? _minutes : 120,
                  onChanged: (v) => setState(() {
                    _minutes = v ?? 120;
                  }),
                  items: [
                    for (final m in _lengths)
                      DropdownMenuItem(value: m, child: Text(_length(m))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _place,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: t.rehearsalPlace,
                  hintText: t.rehearsalPlaceHint,
                ),
              ),
              TextField(
                controller: _notes,
                maxLength: 500,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: t.rehearsalNotes,
                  hintText: t.rehearsalNotesHint,
                  alignLabelWithHint: true,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _weekly,
                onChanged: (v) => setState(() {
                  _weekly = v;
                }),
                title: Text(t.rehearsalWeekly),
                subtitle: Text(
                  t.rehearsalWeeklyHint(DateFormat.EEEE(locale).format(_day)),
                ),
              ),
              if (_weekly)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: Text(t.rehearsalUntil),
                  subtitle: Text(
                    _until == null
                        ? t.rehearsalNoEnd
                        : DateFormat.yMMMd(locale).format(_until!),
                  ),
                  onTap: _pickUntil,
                  trailing: _until == null
                      ? null
                      : IconButton(
                          tooltip: t.rehearsalClearEnd,
                          onPressed: () => setState(() {
                            _until = null;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                ),
              if (widget.setlists.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(t.rehearsalSetlist),
                  trailing: DropdownButton<String?>(
                    value: widget.setlists.any((s) => s.id == _setlistId)
                        ? _setlistId
                        : null,
                    onChanged: (v) => setState(() {
                      _setlistId = v;
                    }),
                    items: [
                      DropdownMenuItem(child: Text(t.rehearsalNoSetlist)),
                      for (final s in widget.setlists)
                        DropdownMenuItem(
                          value: s.id,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              PrintButton(onPressed: _save, child: Text(t.saveChanges)),
            ],
          ),
        ),
      ),
    );
  }
}
