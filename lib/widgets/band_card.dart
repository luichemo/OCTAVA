import 'dart:math';

import 'package:flutter/material.dart';

import '../data/bands_repository.dart';
import '../data/clip_repository.dart';
import '../data/profile_options.dart';
import '../l10n/l10n.dart';
import '../models/band_card.dart';
import '../models/musician.dart' show listJoin;
import '../theme.dart';

/// A band in the swipe deck: its name in poster type over an aqua block,
/// what it's looking for, its members (as instruments), genres, its story
/// and its clip. Swiping Jam asks to join.
class BandCard extends StatelessWidget {
  const BandCard({
    super.key,
    required this.band,
    this.jamStamp = 0,
    this.passStamp = 0,
    this.player,
  });

  final BandCardData band;

  /// 0–1: how visible the Jam / Pass stamps are while dragging.
  final double jamStamp;
  final double passStamp;

  /// Plays the band clip; without it the play button is disabled.
  final ClipPlayer? player;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final b = band;
    return Semantics(
      label: t.bandCardSemantics(b.name),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: printBox(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The poster: a BAND stamp and the name, huge.
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: OctavaColors.aqua),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: printBox(
                        context,
                        color: OctavaColors.yellow,
                        radius: 6,
                        shadow: 2,
                        shadowColor: OctavaColors.ink,
                        borderColor: OctavaColors.ink,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: OctavaColors.ink,
                          ),
                          Text(
                            t.bandCardStamp,
                            style: displayStyle(
                              size: 18,
                              color: OctavaColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (b.fitsYou)
                    Positioned(
                      top: 14,
                      right: 14,
                      left: 120,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: printBox(
                            context,
                            color: OctavaColors.pink,
                            radius: 6,
                            shadow: 2,
                            shadowColor: OctavaColors.ink,
                            borderColor: OctavaColors.ink,
                          ),
                          child: Text(
                            t.bandCardNeedsYou,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: OctavaColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        b.name.toUpperCase(),
                        maxLines: 2,
                        style: displayStyle(
                          size: 56,
                          color: OctavaColors.ink,
                          latin: !hasGeorgian(b.name),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 56,
                    left: 20,
                    child: _Stamp(
                      label: t.stampJam,
                      opacity: jamStamp,
                      angle: 12,
                      background: OctavaColors.yellow,
                      foreground: OctavaColors.ink,
                    ),
                  ),
                  Positioned(
                    top: 56,
                    right: 20,
                    child: _Stamp(
                      label: t.stampPass,
                      opacity: passStamp,
                      angle: -12,
                      background: colors.surface,
                      foreground: colors.error,
                    ),
                  ),
                ],
              ),
            ),
            // The details.
            Expanded(
              flex: 5,
              child: Container(
                color: colors.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                // Scrolls inside the card when the details don't fit.
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        b.openRoles.isEmpty
                            ? t.bandNoOpenRoles
                            : t.bandLookingFor(
                                listJoin([
                                  for (final r in b.openRoles)
                                    instrumentLabel(r),
                                ]),
                              ),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: b.openRoles.isEmpty
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                      // The lineup: who's in it, then the open roles.
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final i in b.memberInstruments)
                            _Slot(role: instrumentLabel(i), open: false),
                          for (final r in b.openRoles)
                            _Slot(role: instrumentLabel(r), open: true),
                        ],
                      ),
                      if (b.genres.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final g in b.genres.take(4))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: printBox(
                                  context,
                                  color: colors.surfaceContainer,
                                  radius: 999,
                                  shadow: 1.5,
                                ),
                                child: Text(
                                  genreLabel(g),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if ((b.description ?? '').isNotEmpty)
                        Text(
                          b.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.4),
                        ),
                      _ClipRow(band: b, player: player),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Play / stop the band clip, with its length.
class _ClipRow extends StatelessWidget {
  const _ClipRow({required this.band, this.player});

  final BandCardData band;
  final ClipPlayer? player;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final path = band.clipPath;
    final player = this.player;
    if (path == null) {
      return Row(
        spacing: 8,
        children: [
          Icon(Icons.music_off_rounded, color: colors.onSurfaceVariant),
          Text(
            t.bandClipNone,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      );
    }
    Widget button(bool playing) => IconButton.filled(
      tooltip: playing ? t.bandClipStop : t.bandClipPlay,
      onPressed: player == null ? null : () => player.toggle(bandClipKey(path)),
      style: IconButton.styleFrom(
        backgroundColor: OctavaColors.pink,
        foregroundColor: OctavaColors.ink,
        disabledBackgroundColor: colors.outlineVariant,
        side: const BorderSide(color: OctavaColors.ink, width: 2),
      ),
      icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
    );
    return Row(
      spacing: 10,
      children: [
        if (player == null)
          button(false)
        else
          ValueListenableBuilder<String?>(
            valueListenable: player.playing,
            builder: (context, playing, _) =>
                button(playing == bandClipKey(path)),
          ),
        Text(
          t.bandClipLength(clipLength(band.clipSeconds ?? 0)),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// One lineup slot: a member's instrument (filled aqua) or an open role
/// (pink outline, "Open").
class _Slot extends StatelessWidget {
  const _Slot({required this.role, required this.open});

  final String role;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: printBox(
        context,
        color: open ? colors.surfaceContainer : OctavaColors.aqua,
        radius: 12,
        shadow: open ? 0 : 1.5,
        borderColor: open ? OctavaColors.pink : OctavaColors.ink,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: open ? colors.onSurface : OctavaColors.ink,
            ),
          ),
          Text(
            open ? t.slotOpen : t.bandSlotFilled,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: open ? OctavaColors.pink : OctavaColors.ink,
            ),
          ),
        ],
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
    // Decorative: the deck's screen-reader actions carry the meaning.
    return ExcludeSemantics(
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.rotate(
          angle: angle * pi / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: printBox(
              context,
              color: background,
              radius: 2,
              shadowColor: OctavaColors.ink,
            ),
            child: Text(
              label.toUpperCase(),
              style: displayStyle(size: 44, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
