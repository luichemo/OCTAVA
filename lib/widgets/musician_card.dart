import 'dart:math';

import 'package:flutter/material.dart';

import '../models/musician.dart';
import '../theme.dart';

/// One swipe card: a halftone "portrait", the instrument in big poster type
/// overlapping it, and the musician's details below.
class MusicianCard extends StatelessWidget {
  const MusicianCard({
    super.key,
    required this.musician,
    required this.tone,
    required this.fitsOpenSlot,
    this.jamStamp = 0,
    this.passStamp = 0,
  });

  final Musician musician;

  /// Portrait colour: pink, yellow or aqua.
  final Color tone;
  final bool fitsOpenSlot;

  /// Opacity (0–1) of the "Jam" and "Pass" stamps while dragging.
  final double jamStamp;
  final double passStamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).height < 700;
    final headingSize = compact ? 60.0 : 76.0;
    final m = musician;

    return Semantics(
      label: '${m.name}, ${m.age}, ${m.instrument.toLowerCase()}',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          border: Border.all(color: colors.outline, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: HalftonePainter(
                        tone: tone,
                        dot: OctavaColors.ink,
                        spotlight: m.spotlight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 16,
                    child: _Stamp(
                      label: 'Jam',
                      opacity: jamStamp,
                      angle: -12,
                      background: OctavaColors.pink,
                      foreground: OctavaColors.ink,
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 16,
                    child: _Stamp(
                      label: 'Pass',
                      opacity: passStamp,
                      angle: 12,
                      background: colors.surfaceContainer,
                      foreground: colors.onSurface,
                    ),
                  ),
                  // The instrument overlaps the bottom edge of the portrait,
                  // overprinted (multiplied) like riso ink in light mode.
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: -headingSize * 0.34,
                    child: ExcludeSemantics(
                      child: Text(
                        m.instrument,
                        maxLines: 1,
                        style: displayStyle(size: headingSize).copyWith(
                          height: 0.85,
                          foreground: Paint()
                            ..color = colors.onSurface
                            ..blendMode = dark
                                ? BlendMode.srcOver
                                : BlendMode.multiply,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, headingSize * 0.34 + 8, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${m.name}, ${m.age}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.whereText,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (fitsOpenSlot)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Fits your open ${m.instrument.toLowerCase()} slot',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (m.clipSeconds != null) _Clip(musician: m),
                  if (m.genres.isNotEmpty)
                    Text(
                      'Plays ${listJoin(m.genres)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  if (!compact && (m.lookingFor ?? '').isNotEmpty)
                    Text(
                      '“${m.lookingFor}”',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.opacity,
    required this.angle,
    required this.background,
    required this.foreground,
  });

  final String label;
  final double opacity;
  final double angle;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    // Decorative: the Pass / Jam buttons carry the meaning for screen readers.
    return ExcludeSemantics(
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.rotate(
          angle: angle * pi / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: foreground, width: 4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: displayStyle(
                size: 44,
                color: foreground,
              ).copyWith(height: 1.1),
            ),
          ),
        ),
      ),
    );
  }
}

/// The audio clip row. Playback arrives with real profiles and uploaded
/// clips, so the button is disabled for now.
class _Clip extends StatelessWidget {
  const _Clip({required this.musician});

  final Musician musician;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seconds = musician.clipSeconds!;
    return Row(
      spacing: 10,
      children: [
        IconButton.outlined(
          onPressed: null,
          tooltip: 'Audio clips arrive with real profiles',
          icon: const Icon(Icons.play_arrow_rounded),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: Row(
              spacing: 2,
              children: [
                for (final h in musician.waveform)
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Riso-style halftone: a flat colour with ink dots that grow away from a
/// clear "spotlight".
class HalftonePainter extends CustomPainter {
  HalftonePainter({
    required this.tone,
    required this.dot,
    required this.spotlight,
  });

  final Color tone;
  final Color dot;

  /// Spotlight centre as fractions of the size (0–1).
  final Offset spotlight;

  static const _step = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tone);
    final paint = Paint()..color = dot;
    final centre = Offset(
      spotlight.dx * size.width,
      spotlight.dy * size.height,
    );
    final reach = size.longestSide * 0.8;
    for (var y = _step / 2; y < size.height; y += _step) {
      for (var x = _step / 2; x < size.width; x += _step) {
        final t = (((Offset(x, y) - centre).distance / reach) - 0.12) / 0.76;
        final radius = _step * 0.32 * t.clamp(0.0, 1.0);
        if (radius > 0.3) canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HalftonePainter old) =>
      old.tone != tone || old.dot != dot || old.spotlight != spotlight;
}
