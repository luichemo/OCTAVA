import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:url_launcher/url_launcher.dart';

import '../data/avatar_repository.dart';
import '../data/clip_repository.dart';
import '../models/musician.dart';
import '../theme.dart';
import 'avatar_section.dart';

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
    this.onSafety,
    this.player,
    this.avatars,
  });

  /// Shows the musician's AI avatar over the halftone pattern when set.
  final AvatarRepository? avatars;

  /// Plays the card's audio clip. Without it the play button is disabled.
  final ClipPlayer? player;

  /// Shows a "Block or report" button when set.
  final VoidCallback? onSafety;

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
      label: context.t.cardSemantics(m.name, m.age, m.instrument.toLowerCase()),
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
                  if (avatars != null && m.avatarPath != null)
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: AvatarImage(
                          avatars: avatars!,
                          path: m.avatarPath!,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 18,
                    left: 16,
                    child: _Stamp(
                      label: context.t.stampJam,
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
                      label: context.t.stampPass,
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
                      // Long names (Georgian especially) shrink to the card width.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
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
                        context.t.nameAge(m.name, m.age),
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
                      if (onSafety != null)
                        IconButton(
                          tooltip: context.t.blockOrReport,
                          onPressed: onSafety,
                          icon: const Icon(Icons.flag_outlined, size: 20),
                          color: colors.onSurfaceVariant,
                          visualDensity: VisualDensity.compact,
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
                        context.t.fitsSlot(m.instrument.toLowerCase()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (m.clipSeconds != null) _Clip(musician: m, player: player),
                  if (m.genres.isNotEmpty)
                    Text(
                      context.t.plays(listJoin(m.genres)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                  if (!compact && m.links.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final link in m.links)
                          ActionChip(
                            avatar: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: Text(link.label),
                            tooltip: link.url,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => launchUrl(
                              Uri.parse(link.url),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                      ],
                    ),
                  if (!compact && (m.lookingFor ?? '').isNotEmpty)
                    Text(
                      context.t.quoted(m.lookingFor!),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
/// The clip row: play button, waveform (filling in as it plays) and length.
class _Clip extends StatelessWidget {
  const _Clip({required this.musician, this.player});

  final Musician musician;
  final ClipPlayer? player;

  @override
  Widget build(BuildContext context) {
    final player = this.player;
    final path = musician.clipPath;
    if (player == null || path == null) {
      return _row(context, playing: false, progress: 0);
    }

    // Rebuilds when any clip starts or stops, then follows the position.
    return ValueListenableBuilder<String?>(
      valueListenable: player.playing,
      builder: (context, playingPath, _) {
        final playing = playingPath == path;
        if (!playing) {
          return _row(
            context,
            playing: false,
            progress: 0,
            onPressed: () => _toggle(context),
          );
        }
        return StreamBuilder<Duration>(
          stream: player.position,
          builder: (context, snapshot) {
            final played = (snapshot.data?.inMilliseconds ?? 0) / 1000;
            return _row(
              context,
              playing: true,
              progress: (played / musician.clipSeconds!).clamp(0, 1),
              onPressed: () => _toggle(context),
            );
          },
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      await player!.toggle(musician.clipPath!);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.errClipPlay)));
    }
  }

  Widget _row(
    BuildContext context, {
    required bool playing,
    required double progress,
    VoidCallback? onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;
    final seconds = musician.clipSeconds!;
    final bars = musician.waveform;
    final lit = (progress * bars.length).floor();
    return Row(
      spacing: 10,
      children: [
        IconButton.outlined(
          onPressed: onPressed,
          tooltip: onPressed == null
              ? context.t.noClip
              : (playing
                    ? context.t.stopClipOf(musician.name)
                    : context.t.playClipOf(musician.name)),
          icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: Row(
              spacing: 2,
              children: [
                for (final (i, h) in bars.indexed)
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i < lit
                              ? OctavaColors.pink
                              : colors.outlineVariant,
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
