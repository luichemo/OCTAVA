import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../theme.dart';
import '../data/profile_options.dart';
import '../models/band.dart';

export '../models/band.dart' show youMarker;

/// The "Your band" row: your slot, then one slot per needed role, filled
/// with a member's name or "Open". The slot at index [justFilled] briefly
/// flashes pink when a match fills it. Tapping the row calls [onEdit].
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
          builder: (context, flash, _) => Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: who != null
                  ? Color.lerp(
                      colors.surfaceContainer,
                      OctavaColors.pink,
                      flash,
                    )
                  : null,
              border: Border.all(
                color: who != null ? colors.outline : colors.outlineVariant,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                          who == youMarker ? context.t.slotYou : who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
    ];
    final title = Text(
      context.t.yourBand,
      style: TextStyle(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
    final row = scrolls
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (edit == null)
          title
        else
          // The title doubles as the button, like the filter summary.
          InkWell(
            onTap: edit,
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: context.t.bandEdit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  title,
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        if (edit == null) row else GestureDetector(onTap: edit, child: row),
      ],
    );
  }
}
