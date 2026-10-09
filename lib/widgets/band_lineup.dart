import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../theme.dart';
import '../data/profile_options.dart';

/// Marks your own slot in a lineup map (shown as "You").
const youMarker = '@you';

/// The "Your band" row: one slot per role, filled with a member's name or
/// "Open". [justFilled] briefly flashes pink when a match fills a slot.
class BandLineup extends StatelessWidget {
  const BandLineup({super.key, required this.band, this.justFilled});

  /// Instrument id → member name ([youMarker] for you, null while open).
  /// Order is display order.
  final Map<String, String?> band;
  final String? justFilled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.yourBand,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          spacing: 6,
          children: [
            for (final MapEntry(key: role, value: who) in band.entries)
              Expanded(
                child: TweenAnimationBuilder<double>(
                  // A new key restarts the flash each time this slot fills.
                  key: ValueKey('$role-$who'),
                  tween: Tween(
                    begin: role == justFilled && !reduceMotion ? 1 : 0,
                    end: 0,
                  ),
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
                        color: who != null
                            ? colors.outline
                            : colors.outlineVariant,
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
              ),
          ],
        ),
      ],
    );
  }
}
