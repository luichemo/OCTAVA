import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:url_launcher/url_launcher.dart';

import '../data/avatar_repository.dart';
import '../data/clip_repository.dart';
import '../data/profile_options.dart';
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
    // The instrument fills the card's width in Latin letters; Georgian
    // words are much wider, so they start smaller still.
    final headingSize = (compact ? 60.0 : 76.0) * (georgianType ? 0.6 : 1);
    final m = musician;
    // The heading keeps its natural size; the location pill beside it gets
    // what's left (at least [_whereMin], or the heading shrinks to make
    // room). Measured here because the pill sits in the same row.
    double headingWidth(double available) {
      if (m.whereShort.isEmpty) return available;
      final painter = TextPainter(
        text: TextSpan(
          text: m.instrument,
          style: displayStyle(size: headingSize).copyWith(height: 0.85),
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final natural = painter.width + headingSize / 12; // + the dark outline
      painter.dispose();
      return min(natural, available - _whereMin - 10).clamp(0, available);
    }

    return Semantics(
      label: context.t.cardSemantics(m.name, m.age, m.instrument.toLowerCase()),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: printBox(context, radius: 24),
        // The details scroll inside the card when they don't fit, so the
        // portrait always keeps at least 40% of the card.
        child: LayoutBuilder(
          builder: (context, box) => Column(
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
                    if (fitsOpenSlot)
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 64,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Transform.rotate(
                            angle: -2 * pi / 180,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: printBox(
                                context,
                                color: OctavaColors.pink,
                                radius: 999,
                                shadow: 2,
                                borderColor: OctavaColors.ink,
                                shadowColor: OctavaColors.ink,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: OctavaColors.ink,
                                  ),
                                  Flexible(
                                    child: Text(
                                      context.t.fitsSlot(
                                        m.instrument.toLowerCase(),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: OctavaColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                      // The heading, and where they are beside it.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: headingWidth(box.maxWidth - 36),
                            child: ExcludeSemantics(
                              // Long names (Georgian especially) shrink to fit.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomLeft,
                                // In dark mode a dark outline is painted under the
                                // light letters, so they stand out on the portrait.
                                child: Stack(
                                  children: [
                                    if (dark)
                                      Text(
                                        m.instrument,
                                        maxLines: 1,
                                        style: displayStyle(size: headingSize)
                                            .copyWith(
                                              height: 0.85,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = headingSize / 12
                                                ..strokeJoin = StrokeJoin.round
                                                ..color =
                                                    OctavaColors.darkShadow,
                                            ),
                                      ),
                                    Text(
                                      m.instrument,
                                      maxLines: 1,
                                      style: displayStyle(size: headingSize)
                                          .copyWith(
                                            height: 0.85,
                                            foreground: Paint()
                                              ..color = colors.onSurface
                                              ..blendMode = dark
                                                  ? BlendMode.srcOver
                                                  : BlendMode.multiply,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (m.whereShort.isNotEmpty)
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 10,
                                  bottom: headingSize * 0.06,
                                ),
                                child: _Where(
                                  text: m.whereShort,
                                  label: m.whereText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: box.maxHeight.isFinite
                      ? box.maxHeight * 0.6
                      : double.infinity,
                ),
                // The space under the instrument heading stays put; only the
                // details below it scroll.
                child: Padding(
                  padding: EdgeInsets.only(top: headingSize * 0.34 + 8),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.t.nameAge(m.name, m.age),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: displayStyle(
                                  size: 30,
                                  color: colors.onSurface,
                                  latin: !hasGeorgian(m.name),
                                ),
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
                        if (m.clipSeconds != null)
                          _Clip(musician: m, player: player),
                        if (m.otherInstruments.isNotEmpty)
                          _AlsoPlays(instruments: m.otherInstruments),
                        if (m.genres.isNotEmpty)
                          // Genre pills in the three spot inks, in turn.
                          Semantics(
                            label: context.t.plays(
                              listJoin([
                                for (final g in m.genres) genreLabel(g),
                              ]),
                            ),
                            child: ExcludeSemantics(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final (i, g) in m.genres.indexed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: printBox(
                                        context,
                                        color: [
                                          OctavaColors.yellow,
                                          OctavaColors.aqua,
                                          OctavaColors.pinkTint,
                                        ][i % 3],
                                        radius: 999,
                                        shadow: 2,
                                        borderColor: OctavaColors.ink,
                                      ),
                                      child: Text(
                                        genreLabel(g),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: OctavaColors.ink,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (m.links.isNotEmpty)
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
                        if ((m.lookingFor ?? '').isNotEmpty)
                          Text(
                            context.t.quoted(m.lookingFor!),
                            style: TextStyle(
                              fontSize: 15,
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
        ),
      ),
    );
  }
}

/// Where they are ("Vera, 1.2 km away"), as a small outlined pill beside
/// the instrument heading; long places end with "…".
/// Skill levels as 1–4 dots.
const _skillDots = {'beginner': 1, 'intermediate': 2, 'advanced': 3, 'pro': 4};

/// The other instruments, as small outlined pills: the name and 1–4 dots
/// for the level (Beginner → Pro). Screen readers hear the whole line,
/// "Also: Guitar · Pro, Keys · Advanced".
class _AlsoPlays extends StatelessWidget {
  const _AlsoPlays({required this.instruments});

  final List<({String id, String skill})> instruments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: context.t.cardAlsoPlays(
        [
          for (final i in instruments)
            '${instrumentLabel(i.id)} · ${skillLabels[i.skill] ?? i.skill}',
        ].join(', '),
      ),
      excludeSemantics: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final i in instruments)
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.outlineVariant, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    instrumentLabel(i.id),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2.5,
                    children: [
                      for (var d = 1; d <= 4; d++)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: d <= (_skillDots[i.skill] ?? 0)
                                ? OctavaColors.pink
                                : null,
                            border: Border.all(
                              color: d <= (_skillDots[i.skill] ?? 0)
                                  ? OctavaColors.pink
                                  : colors.outlineVariant,
                              width: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The least room the location pill gets beside the heading.
const _whereMin = 118.0;

class _Where extends StatelessWidget {
  const _Where({required this.text, required this.label});
  final String text;

  /// What screen readers hear: "Vake, 1.2 km away".
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: printBox(context, radius: 999, shadow: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              Icons.near_me_outlined,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
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
class _Clip extends StatefulWidget {
  const _Clip({required this.musician, this.player});

  final Musician musician;
  final ClipPlayer? player;

  @override
  State<_Clip> createState() => _ClipState();
}

class _ClipState extends State<_Clip> {
  /// Where a finger is dragging on the waveform (0–1), or null.
  double? _scrub;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final path = widget.musician.clipPath;
    if (player == null || path == null) {
      return _row(context, playing: false, progress: 0, canSeek: false);
    }

    // Rebuilds when any clip starts or stops, then follows the position.
    return ValueListenableBuilder<String?>(
      valueListenable: player.playing,
      builder: (context, playingPath, _) {
        final playing = playingPath == path;
        if (!playing) {
          return _row(context, playing: false, progress: _scrub ?? 0);
        }
        return StreamBuilder<Duration>(
          stream: player.position,
          builder: (context, snapshot) {
            final played = (snapshot.data?.inMilliseconds ?? 0) / 1000;
            final seconds = widget.musician.clipSeconds!;
            return _row(
              context,
              playing: true,
              progress: _scrub ?? (played / seconds).clamp(0, 1),
            );
          },
        );
      },
    );
  }

  Future<void> _toggle() =>
      _guard(() => widget.player!.toggle(widget.musician.clipPath!));

  /// Jumps to [fraction] (0–1) of the clip, starting it if needed.
  Future<void> _seekTo(double fraction) {
    final ms = (fraction * widget.musician.clipSeconds! * 1000).round();
    return _guard(
      () => widget.player!.seek(
        widget.musician.clipPath!,
        Duration(milliseconds: ms),
      ),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.errClipPlay)));
    }
  }

  Widget _row(
    BuildContext context, {
    required bool playing,
    required double progress,
    bool canSeek = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    final t = context.t;
    final m = widget.musician;
    final seconds = m.clipSeconds!;
    final bars = m.waveform;
    final lit = (progress * bars.length).floor();
    // While playing or dragging, the time shows where you are; else the
    // clip's length.
    final shown = playing || _scrub != null
        ? (progress * seconds).floor()
        : seconds;
    final strip = SizedBox(
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
                    color: i < lit ? OctavaColors.pink : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    Widget waveform = strip;
    if (canSeek) {
      // Tap or drag on the waveform to jump there. A sideways drag here
      // moves through the song instead of swiping the card (it claims the
      // gesture before the card's pan does).
      waveform = LayoutBuilder(
        builder: (context, box) {
          double at(Offset p) => (p.dx / box.maxWidth).clamp(0.0, 1.0);
          void drag(Offset p) => setState(() {
            _scrub = at(p);
          });
          return Semantics(
            slider: true,
            label: t.clipPosition,
            value: '${(progress * 100).round()}%',
            increasedValue: '${((progress + 0.1).clamp(0, 1) * 100).round()}%',
            decreasedValue: '${((progress - 0.1).clamp(0, 1) * 100).round()}%',
            onIncrease: () => _seekTo((progress + 0.1).clamp(0, 1)),
            onDecrease: () => _seekTo((progress - 0.1).clamp(0, 1)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _seekTo(at(d.localPosition)),
              onHorizontalDragStart: (d) => drag(d.localPosition),
              onHorizontalDragUpdate: (d) => drag(d.localPosition),
              onHorizontalDragEnd: (_) {
                final to = _scrub;
                if (to != null) _seekTo(to);
                setState(() {
                  _scrub = null;
                });
              },
              onHorizontalDragCancel: () => setState(() {
                _scrub = null;
              }),
              child: strip,
            ),
          );
        },
      );
    }
    // A small "audio stem" player on its own printed strip.
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: printBox(
        context,
        color: colors.surface,
        radius: 18,
        shadow: 2,
      ),
      child: Row(
        spacing: 10,
        children: [
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: OctavaColors.pink,
              foregroundColor: OctavaColors.ink,
              disabledBackgroundColor: colors.outlineVariant,
              side: BorderSide(color: OctavaColors.ink, width: 2),
            ),
            onPressed: canSeek ? _toggle : null,
            tooltip: !canSeek
                ? t.noClip
                : (playing ? t.stopClipOf(m.name) : t.playClipOf(m.name)),
            icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
          ),
          Expanded(child: waveform),
          Text(
            '${shown ~/ 60}:${(shown % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
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
