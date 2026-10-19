import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../theme.dart';
import '../data/profile_options.dart';
import '../models/band.dart';

export '../models/band.dart' show youMarker;

/// The feed's band row as one thin strip (owner's pick, 2026-10-19): one
/// segment per slot with the role's name in it (pink
/// when taken, yours outlined in ink; outlined and muted when open), "2/5"
/// and a chevron. Four segments share the width; more scroll sideways.
/// Screen readers hear each slot ("Drums: Nika" / "Bass: Open"). The slot at
/// index [justFilled] flashes yellow when a match fills it. Tapping the strip
/// calls [onEdit].
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

  /// Opens the role chooser. Without it the strip isn't tappable.
  final VoidCallback? onEdit;

  /// How many segments fit across; the rest scroll.
  static const _visible = 4;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.t;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final filled = band.where((s) => s.member != null).length;
    const small = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

    Widget segment(int i, String role, String? who, double width) => Semantics(
      // Its own node, or the slots merge into one label.
      container: true,
      label:
          '${instrumentLabel(role)}: '
          '${who == null ? t.slotOpen : (who == youMarker ? t.slotYou : who)}',
      child: TweenAnimationBuilder<double>(
        // A new key restarts the flash each time it fills.
        key: ValueKey('$i-$role-$who'),
        tween: Tween(begin: i == justFilled && !reduceMotion ? 1 : 0, end: 0),
        duration: const Duration(milliseconds: 700),
        builder: (context, flash, _) => Container(
          width: width,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: who == null
                ? null
                : Color.lerp(OctavaColors.pink, OctavaColors.yellow, flash),
            borderRadius: BorderRadius.circular(7),
            border: who == null
                ? Border.all(color: colors.outlineVariant, width: 1.2)
                : who == youMarker
                ? Border.all(color: OctavaColors.ink, width: 1.2)
                : null,
          ),
          child: ExcludeSemantics(
            // Long names (Georgian especially) shrink to fit their segment.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                instrumentLabel(role),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: who == null
                      ? colors.onSurfaceVariant
                      : OctavaColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final strip = SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // Four across (fewer slots share the width); more scroll.
                final across = band.length.clamp(1, _visible);
                final width = (box.maxWidth - _gap * (across - 1)) / across;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: _gap,
                    children: [
                      // `(i, (:role, member: who))` unpacks the index and the
                      // record's fields, like `[i, { role, member: who }]`.
                      for (final (i, (:role, member: who)) in band.indexed)
                        segment(i, role, who, width),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          ExcludeSemantics(
            child: Text(
              '$filled/${band.length}',
              style: small.copyWith(color: colors.onSurface),
            ),
          ),
          if (onEdit != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
        ],
      ),
    );
    final edit = onEdit;
    if (edit == null) return strip;
    return GestureDetector(
      onTap: edit,
      behavior: HitTestBehavior.opaque,
      child: strip,
    );
  }
}
