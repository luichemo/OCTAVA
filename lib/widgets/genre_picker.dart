import 'package:flutter/material.dart';

import '../data/profile_options.dart';
import '../l10n/l10n.dart';

/// The chosen genres as chips, plus a button that opens the full list.
class GenrePicker extends StatelessWidget {
  const GenrePicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.max,
  });

  /// Genre ids, in the order chosen.
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// Most genres that can be picked; null means no limit.
  final int? max;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GenreSheet(initial: selected, max: max),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in selected)
                InputChip(
                  label: Text(genreLabel(id)),
                  onDeleted: () => onChanged([...selected]..remove(id)),
                ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.library_music_outlined),
          label: Text(
            selected.isEmpty ? context.t.genresChoose : context.t.genresChange,
          ),
        ),
      ],
    );
  }
}

/// Searchable list of every genre with checkboxes. Pops with the new
/// selection on "Done".
class _GenreSheet extends StatefulWidget {
  const _GenreSheet({required this.initial, this.max});

  final List<String> initial;
  final int? max;

  @override
  State<_GenreSheet> createState() => _GenreSheetState();
}

class _GenreSheetState extends State<_GenreSheet> {
  late final List<String> _picked = [...widget.initial];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final full = widget.max != null && _picked.length >= widget.max!;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final MapEntry(key: id, value: label) in genreLabels.entries)
        if (q.isEmpty || label.toLowerCase().contains(q) || id.contains(q))
          (id, label),
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() {
                _query = v;
              }),
              decoration: InputDecoration(
                hintText: t.genresSearch,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (full)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                t.genresMax,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text(t.genresNoResults))
                : ListView(
                    children: [
                      for (final (id, label) in shown)
                        CheckboxListTile(
                          value: _picked.contains(id),
                          title: Text(label),
                          // At the limit, only unticking is possible.
                          enabled: _picked.contains(id) || !full,
                          onChanged: (on) => setState(() {
                            on == true ? _picked.add(id) : _picked.remove(id);
                          }),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_picked),
                  child: Text(t.genresDone),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
