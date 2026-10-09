import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../data/safety_repository.dart';

/// Shows "Block" and "Report" for a person, handles the confirmation or
/// report form, and tells the person what happened.
/// Returns true when that person is now blocked.
Future<bool> showSafetyOptions(
  BuildContext context, {
  required SafetyRepository safety,
  required String userId,
  required String name,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: Text('Block $name'),
            subtitle: const Text(
              "You won't see each other and can't message. They aren't told.",
            ),
            onTap: () => Navigator.pop(context, 'block'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text('Report $name'),
            subtitle: const Text(
              'Tell us about something wrong. Reports are private.',
            ),
            onTap: () => Navigator.pop(context, 'report'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    if (choice == 'block') {
      if (!await _confirmBlock(context, name)) return false;
      await safety.block(userId);
      messenger.showSnackBar(SnackBar(content: Text('You blocked $name.')));
      return true;
    }
    if (!context.mounted) return false;
    final report = await showDialog<_Report>(
      context: context,
      builder: (_) => _ReportDialog(name: name),
    );
    if (report == null) return false;
    await safety.report(userId, report.reason, report.details);
    if (report.alsoBlock) await safety.block(userId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          report.alsoBlock
              ? 'Thanks for reporting. You also blocked $name.'
              : 'Thanks for reporting. We review every report.',
        ),
      ),
    );
    return report.alsoBlock;
  } on UserFacingException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

Future<bool> _confirmBlock(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Block $name?'),
      content: Text(
        "You won't see each other on OCTAVA anymore, and neither of you can send "
        "messages. $name won't be told.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Block $name'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _Report {
  const _Report(this.reason, this.details, this.alsoBlock);
  final String reason;
  final String details;
  final bool alsoBlock;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.name});
  final String name;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;
  bool _alsoBlock = true;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.name}'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What's wrong?"),
          const SizedBox(height: 4),
          // RadioGroup holds the selected value for the radios inside it.
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (value) => setState(() {
              _reason = value;
            }),
            child: Column(
              children: [
                for (final MapEntry(key: id, value: label)
                    in reportReasonLabels.entries)
                  RadioListTile<String>(
                    value: id,
                    title: Text(label),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              alignLabelWithHint: true,
            ),
          ),
          CheckboxListTile(
            value: _alsoBlock,
            onChanged: (v) => setState(() {
              _alsoBlock = v ?? false;
            }),
            title: Text('Also block ${widget.name}'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _reason == null
              ? null
              : () => Navigator.pop(
                  context,
                  _Report(_reason!, _details.text, _alsoBlock),
                ),
          child: const Text('Send report'),
        ),
      ],
    );
  }
}
