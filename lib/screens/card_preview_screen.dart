import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/avatar_repository.dart';
import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../models/musician.dart';
import '../theme.dart';
import '../widgets/musician_card.dart';

/// Your own card, exactly as other musicians see it when swiping, with your
/// clip and links working. Shows the saved profile.
class CardPreviewScreen extends StatefulWidget {
  const CardPreviewScreen({
    super.key,
    required this.repository,
    this.player,
    this.avatars,
  });

  final ProfileRepository repository;
  final ClipPlayer? player;
  final AvatarRepository? avatars;

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> {
  late final Future<Musician> _card = widget.repository.loadMyCard();

  @override
  void dispose() {
    widget.player?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          context.t.yourCard,
          style: displayStyle(size: 30, color: colors.onSurface),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: FutureBuilder<Musician>(
              future: _card,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final me = snapshot.data;
                if (me == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.t.cardPreviewInfo,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: MusicianCard(
                          musician: me,
                          tone: const [
                            OctavaColors.pink,
                            OctavaColors.yellow,
                            OctavaColors.aqua,
                          ][me.toneIndex],
                          fitsOpenSlot: false,
                          player: widget.player,
                          avatars: widget.avatars,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
