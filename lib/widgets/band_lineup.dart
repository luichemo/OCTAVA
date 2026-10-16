import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../theme.dart';
import '../data/profile_options.dart';
import '../models/band.dart';

export '../models/band.dart' show youMarker;

/// Your slot, then one slot per needed role, filled with a member's name or
/// "Open". The slot at index [justFilled] briefly flashes pink when a match
/// fills it. Tapping the lineup calls [onEdit].
class BandLineup extends StatelessWidget {
  const BandLineup({
    super.key,
    required this.band,
    this.justFilled,
    this.onEdit,
  });

  /// Display order; see [buildLineup].
  final List<BandSlot> band;
  final int? justFilled;

  /// Opens the role chooser. Without it the row isn't tappable.
  final VoidCallback? onEdit;

  /// Up to this many slots share the width; more scroll sideways.
  static const _fitSlots = 6;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scrolls = band.length > _fitSlots;
    final slots = [
      // `(i, (:role, member: who))` unpacks the index and the record's
      // fields, like `[i, { role, member: who }]` destructuring in JS.
      for (final (i, (:role, member: who)) in band.indexed)
        TweenAnimationBuilder<double>(
          // A new key restarts the flash each time this slot fills.
          key: ValueKey('$i-$role-$who'),
          tween: Tween(begin: i == justFilled && !reduceMotion ? 1 : 0, end: 0),
          duration: const Duration(milliseconds: 700),
          builder: (context, flash, _) {
            // You: a white slot. Members: pink, flashing yellow as they
            // arrive. Open: an empty outline.
            final you = who == youMarker;
            final member = who != null && !you;
            final fill = member
                ? Color.lerp(OctavaColors.pink, OctavaColors.yellow, flash)!
                : you
                ? colors.surfaceContainer
                : Colors.transparent;
            final text = member ? OctavaColors.ink : colors.onSurface;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: who == null
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant,
                        width: 2,
                      ),
                    )
                  : printBox(
                      context,
                      color: fill,
                      radius: 12,
                      shadow: 2,
                      borderColor: member ? OctavaColors.ink : null,
                    ),
              child: Column(
                children: [
                  // Long names (e.g. Georgian "დასარტყამები") shrink to
                  // fit the slot instead of wrapping.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        instrumentLabel(role),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: who == null ? colors.onSurfaceVariant : text,
                        ),
                      ),
                    ),
                  ),
                  // "Open" shrinks to fit (it's long in Georgian);
                  // member names end with "…" instead.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: who == null
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              context.t.slotOpen,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Text(
                            you ? context.t.slotYou : who,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: you ? OctavaColors.pink : text,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
    ];
    final row = scrolls
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Room for the slots' hard shadows.
            padding: const EdgeInsets.only(bottom: 2, right: 2),
            child: Row(
              spacing: 6,
              children: [
                for (final slot in slots) SizedBox(width: 64, child: slot),
              ],
            ),
          )
        : Row(
            spacing: 6,
            children: [for (final slot in slots) Expanded(child: slot)],
          );
    final edit = onEdit;
    return Container(
      decoration: printBox(context, radius: 20),
      padding: const EdgeInsets.all(12),
      child: edit == null ? row : GestureDetector(onTap: edit, child: row),
    );
  }
}
