import 'package:flutter/material.dart';

/// A text field that turns entries into removable chips (max 10).
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<String> values;
  final VoidCallback onChanged;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    _controller.clear();
    if (value.isEmpty || widget.values.length >= 10) return;
    if (widget.values.any((v) => v.toLowerCase() == value.toLowerCase())) {
      return;
    }
    widget.values.add(value);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.values.length >= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          enabled: !full,
          onSubmitted: (_) => _add(),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: full ? 'You can add up to 10' : widget.hint,
            suffixIcon: IconButton(
              tooltip: 'Add',
              onPressed: full ? null : _add,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in widget.values)
                InputChip(
                  label: Text(v),
                  onDeleted: () {
                    widget.values.remove(v);
                    widget.onChanged();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
