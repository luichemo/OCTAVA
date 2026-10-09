import 'package:flutter/material.dart';

import '../data/band_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../models/band.dart';

/// Opens the role chooser. Returns the new needs on Save, or null.
Future<Map<String, int>?> showBandRolesSheet(
  BuildContext context, {
  required Map<String, int> needs,
}) => showModalBottomSheet<Map<String, int>>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _BandRolesSheet(initial: needs),
);

/// Every instrument with a − count + stepper; 0 means not needed.
class _BandRolesSheet extends StatefulWidget {
  const _BandRolesSheet({required this.initial});

  final Map<String, int> initial;

  @override
  State<_BandRolesSheet> createState() => _BandRolesSheetState();
}

class _BandRolesSheetState extends State<_BandRolesSheet> {
  late final Map<String, int> _counts = {...widget.initial};

  int get _total => _counts.values.fold(0, (a, b) => a + b);

  void _change(String role, int by) => setState(() {
    final next = (_counts[role] ?? 0) + by;
    if (next <= 0) {
      _counts.remove(role);
    } else {
      _counts[role] = next;
    }
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final total = _total;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              t.bandRolesTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    total == 0
                        ? t.bandRolesEmpty
                        : t.bandRolesHint(maxBandSlots),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
                Text(
                  t.bandRolesCount(total, maxBandSlots),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final MapEntry(key: id, value: label)
                    in instrumentLabels.entries)
                  _RoleRow(
                    id: id,
                    label: label,
                    count: _counts[id] ?? 0,
                    canAdd:
                        total < maxBandSlots &&
                        (_counts[id] ?? 0) < maxSlotsPerRole,
                    onChange: (by) => _change(id, by),
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
                  // Saved in the list's order, so the lineup follows it.
                  onPressed: total == 0
                      ? null
                      : () => Navigator.of(context).pop({
                          // `?` leaves out roles with no count.
                          for (final id in instrumentLabels.keys)
                            id: ?_counts[id],
                        }),
                  child: Text(t.bandRolesSave),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.id,
    required this.label,
    required this.count,
    required this.canAdd,
    required this.onChange,
  });

  final String id;
  final String label;
  final int count;
  final bool canAdd;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListTile(
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: count > 0 ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('fewer-$id'),
            tooltip: t.roleFewer,
            onPressed: count > 0 ? () => onChange(-1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            key: ValueKey('more-$id'),
            tooltip: t.roleMore,
            onPressed: canAdd ? () => onChange(1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

/// "Your band needs" in the profile: the chosen roles, and a button to
/// change them. Saves straight away, like the clips and location sections.
class BandNeedsSection extends StatefulWidget {
  const BandNeedsSection({
    super.key,
    required this.repository,
    required this.myRole,
  });

  final BandNeedsRepository repository;

  /// Your main instrument, for the default roles.
  final String? myRole;

  @override
  State<BandNeedsSection> createState() => _BandNeedsSectionState();
}

class _BandNeedsSectionState extends State<BandNeedsSection> {
  late Future<Map<String, int>?> _needs = widget.repository.load();
  bool _saving = false;

  Future<void> _change(Map<String, int> current) async {
    final chosen = await showBandRolesSheet(context, needs: current);
    if (chosen == null || !mounted) return;
    setState(() {
      _saving = true;
    });
    try {
      await widget.repository.save(chosen);
      if (!mounted) return;
      setState(() {
        _needs = Future.value(chosen);
      });
    } on UserFacingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: _needs,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Text(
            error is UserFacingException ? error.message : t.errLoadBand,
          );
        }
        final chosen = snapshot.data;
        final needs = chosen ?? defaultBandNeeds(widget.myRole);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: role, value: n) in needs.entries)
                  Chip(
                    label: Text(
                      n == 1
                          ? instrumentLabel(role)
                          : t.roleCount(instrumentLabel(role), n),
                    ),
                  ),
              ],
            ),
            if (chosen == null)
              Text(
                t.bandDefaultNote,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            OutlinedButton.icon(
              onPressed: _saving ? null : () => _change(needs),
              icon: const Icon(Icons.groups_outlined),
              label: Text(t.bandChange),
            ),
          ],
        );
      },
    );
  }
}
