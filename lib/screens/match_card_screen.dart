import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/clip_repository.dart';
import '../l10n/l10n.dart';
import '../models/musician.dart';
import '../theme.dart';
import '../widgets/musician_card.dart';

/// Someone's swipe card: a match's (owner, 2026-10-22), from the chat header
/// or a match's picture in Matches, or a bandmate's or candidate's
/// (2026-10-23), from the band chat or a vote. [load] fetches it (null = not
/// available). [onChat] adds an Open chat button (from Matches); from a chat
/// itself, Back goes back to it.
class MatchCardScreen extends StatefulWidget {
  const MatchCardScreen({
    super.key,
    required this.load,
    required this.name,
    this.player,
    this.avatars,
    this.onChat,
  });

  final Future<Musician?> Function() load;
  final String name;
  final ClipPlayer? player;
  final AvatarRepository? avatars;
  final VoidCallback? onChat;

  @override
  State<MatchCardScreen> createState() => _MatchCardScreenState();
}

class _MatchCardScreenState extends State<MatchCardScreen> {
  late Future<Musician?> _card = widget.load();

  @override
  void dispose() {
    // Their clip stops when the card closes.
    widget.player?.stop();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _card = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name,
          style: displayStyle(
            size: 28,
            color: colors.onSurface,
            latin: !hasGeorgian(widget.name),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Musician?>(
          future: _card,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _Message(
                text: t.errMatchCard,
                action: t.tryAgain,
                onAction: _retry,
              );
            }
            final card = snap.data;
            // Unmatched, left the band, blocked or suspended since the list loaded.
            if (card == null) return _Message(text: t.matchCardGone);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Expanded(
                    child: MusicianCard(
                      musician: card,
                      tone: [
                        OctavaColors.pink,
                        OctavaColors.yellow,
                        OctavaColors.aqua,
                      ][card.toneIndex],
                      fitsOpenSlot: false,
                      player: widget.player,
                      avatars: widget.avatars,
                    ),
                  ),
                  if (widget.onChat != null)
                    PrintButton(
                      onPressed: widget.onChat,
                      child: Text(t.openChat),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action != null)
              OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
      ),
    );
  }
}
