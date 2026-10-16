import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/profile_options.dart';
import '../data/public_band_repository.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/language_picker.dart';
import '../widgets/octava_logo.dart';

/// A band's public page: name, genres, description, "Looking for", the band
/// clip, members (teens as their instrument only) and ready songs. Opens
/// without an account from a link (`?band=<id>` on the web preview), and
/// from the band page for members to preview it.
class PublicBandScreen extends StatefulWidget {
  const PublicBandScreen({
    super.key,
    required this.source,
    required this.bandId,
    this.player,
    this.onJoin,
  });

  final PublicBandSource source;
  final String bandId;

  /// Plays the band clip (its key is the clip's temporary link). Without it
  /// there's no play button.
  final ClipPlayer? player;

  /// "Join OCTAVA" for visitors; null hides it (members previewing).
  final VoidCallback? onJoin;

  @override
  State<PublicBandScreen> createState() => _PublicBandScreenState();
}

class _PublicBandScreenState extends State<PublicBandScreen> {
  late Future<PublicBand?> _band = widget.source.load(widget.bandId);

  void _retry() => setState(() {
    _band = widget.source.load(widget.bandId);
  });

  @override
  void dispose() {
    widget.player?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        // Visitors land here with nothing to go back to: show the logo.
        title: widget.onJoin == null
            ? Text(t.publicPageTitle)
            : const OctavaLogo(height: 30),
        actions: [if (widget.onJoin != null) const LanguageToggle()],
      ),
      body: FutureBuilder<PublicBand?>(
        future: _band,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final children = <Widget>[];
          if (snap.hasError) {
            children.add(
              _Card(
                children: [
                  Text(
                    snap.error is UserFacingException
                        ? (snap.error as UserFacingException).message
                        : t.errPublicBandLoad,
                    style: TextStyle(color: colors.error),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _retry,
                      child: Text(t.tryAgain),
                    ),
                  ),
                ],
              ),
            );
          } else if (snap.data case final band?) {
            children.addAll(_bandCards(context, band));
          } else {
            children.add(
              _Card(
                children: [
                  Text(
                    t.publicBandNotFound,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          if (widget.onJoin case final onJoin?) {
            children.add(
              _Card(
                children: [
                  Text(t.publicBandJoinHint),
                  const SizedBox(height: 4),
                  PrintButton(onPressed: onJoin, child: Text(t.publicBandJoin)),
                ],
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _bandCards(BuildContext context, PublicBand band) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return [
      _Card(
        color: OctavaColors.aqua,
        children: [
          Text(
            band.name,
            style: displayStyle(
              size: 44,
              color: OctavaColors.ink,
              latin: !hasGeorgian(band.name),
            ),
          ),
          if (band.genres.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in band.genres)
                  Chip(
                    label: Text(genreLabel(g)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          if ((band.description ?? '').isNotEmpty)
            Text(
              band.description!,
              style: const TextStyle(color: OctavaColors.ink, height: 1.35),
            ),
          if (band.openRoles.isNotEmpty)
            Text(
              t.bandLookingFor(band.openRoles.map(instrumentLabel).join(', ')),
              style: const TextStyle(
                color: OctavaColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (band.clipUrl != null && widget.player != null)
            _ClipRow(
              url: band.clipUrl!,
              seconds: band.clipSeconds,
              player: widget.player!,
            ),
        ],
      ),
      _Card(
        children: [
          Text(
            t.bandMembers,
            style: displayStyle(size: 24, color: colors.onSurface),
          ),
          for (final m in band.members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: OctavaColors.pinkTint,
                foregroundImage: m.avatarUrl == null
                    ? null
                    : NetworkImage(m.avatarUrl!),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: OctavaColors.ink,
                ),
              ),
              title: Text(
                m.name ?? instrumentLabel(m.instrument),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: m.name == null
                  ? null
                  : Text(instrumentLabel(m.instrument)),
            ),
        ],
      ),
      if (band.songs.isNotEmpty)
        _Card(
          children: [
            Text(
              t.publicBandSongs,
              style: displayStyle(size: 24, color: colors.onSurface),
            ),
            for (final (i, title) in band.songs.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${i + 1}. $title'),
              ),
          ],
        ),
    ];
  }
}

/// A printed card with spaced-out contents.
class _Card extends StatelessWidget {
  const _Card({required this.children, this.color});

  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: printBox(context, color: color, radius: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: children,
    ),
  );
}

/// Play / stop for the band clip, with its length.
class _ClipRow extends StatelessWidget {
  const _ClipRow({required this.url, required this.player, this.seconds});

  final String url;
  final int? seconds;
  final ClipPlayer player;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: player.playing,
    builder: (context, playing, _) {
      final on = playing == url;
      return Row(
        spacing: 8,
        children: [
          IconButton.filled(
            tooltip: on ? context.t.voiceStop : context.t.bandClipPlay,
            onPressed: () => player.toggle(url),
            style: IconButton.styleFrom(
              backgroundColor: OctavaColors.pink,
              foregroundColor: OctavaColors.ink,
            ),
            icon: Icon(on ? Icons.stop_rounded : Icons.play_arrow_rounded),
          ),
          if (seconds != null)
            Text(
              clipLength(seconds!),
              style: const TextStyle(
                color: OctavaColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      );
    },
  );
}
