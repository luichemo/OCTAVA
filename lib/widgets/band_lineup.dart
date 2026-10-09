import 'package:flutter/material.dart';

import '../theme.dart';

/// The "Your band" row: one slot per role, filled with a member's name or
/// "Open". [justFilled] briefly flashes pink when a match fills a slot.
class BandLineup extends StatelessWidget {
  const BandLineup({super.key, required this.band, this.justFilled});

  /// Role → member name (null while the slot is open). Order is display order.
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
          'Your band',
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
                        Text(
                          role,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          who ?? 'Open',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
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
