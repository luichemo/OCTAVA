import 'dart:async';

import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../data/song_repository.dart';
import '../l10n/l10n.dart';
import '../models/song.dart';
import '../screens/song_screen.dart';
import '../theme.dart';

/// "Ready", "Learning" or "Idea", in the app's language.
String songStatusLabel(SongStatus s) => switch (s) {
  SongStatus.ready => L10n.current.songReady,
  SongStatus.learning => L10n.current.songLearning,
  SongStatus.idea => L10n.current.songIdea,
};

/// "E minor · 120 BPM", or empty.
String songMeta(Song s) => [
  if ((s.songKey ?? '').isNotEmpty) s.songKey!,
  if (s.tempo != null) L10n.current.songBpm(s.tempo!),
].join(' · ');

/// A small status pill: ready aqua, learning yellow, idea outlined.
class SongStatusPill extends StatelessWidget {
  const SongStatusPill(this.status, {super.key});
  final SongStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = switch (status) {
      SongStatus.ready => OctavaColors.aqua,
      SongStatus.learning => OctavaColors.yellow,
      SongStatus.idea => colors.surfaceContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: printBox(context, color: fill, radius: 999, shadow: 0),
      child: Text(
        songStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: status == SongStatus.idea
              ? colors.onSurface
              : OctavaColors.ink,
        ),
      ),
    );
  }
}

/// The band page's song list: ready songs first, Add song, and a page per
/// song. Updates live.
class SongsSection extends StatefulWidget {
  const SongsSection({
    super.key,
    required this.repository,
    required this.bandId,
    this.player,
  });

  final SongRepository repository;
  final String bandId;

  /// Plays recordings.
  final ClipPlayer? player;

  @override
  State<SongsSection> createState() => _SongsSectionState();
}

class _SongsSectionState extends State<SongsSection> {
  List<Song>? _songs;
  String? _error;
  bool _showAll = false;
  StreamSubscription<void>? _sub;

  /// How many songs show before "Show all".
  static const _first = 5;

  @override
  void initState() {
    super.initState();
    _sub = widget.repository.changes().listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final songs = await widget.repository.list(widget.bandId);
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _error = null;
      });
    } on UserFacingException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    }
  }

  Future<void> _add() async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => NameDialog(
        title: context.t.songAddTitle,
        label: context.t.songTitleLabel,
        action: context.t.rehearsalAdd,
      ),
    );
    if (title == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final song = await widget.repository.add(widget.bandId, title);
      await _load();
      if (mounted) await _open(song);
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _open(Song song) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SongScreen(
          repository: widget.repository,
          song: song,
          player: widget.player,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final songs = _songs;
    final shown = songs == null
        ? const <Song>[]
        : (_showAll ? songs : songs.take(_first).toList());
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: printBox(context, radius: 20),
      // A see-through Material, so the rows' tap ripples show on the card.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.songsTitle,
                    style: displayStyle(size: 24, color: colors.onSurface),
                  ),
                ),
                TextButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.rehearsalAdd),
                ),
              ],
            ),
            if (_error != null && songs == null)
              Text(_error!, style: TextStyle(color: colors.error))
            else if (songs == null)
              const Center(child: CircularProgressIndicator())
            else if (songs.isEmpty)
              Text(
                t.songsEmpty,
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else ...[
              for (final s in shown)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  onTap: () => _open(s),
                  leading: s.recordingPath == null || widget.player == null
                      ? const Icon(Icons.music_note_outlined)
                      : SongPlayButton(
                          path: s.recordingPath!,
                          player: widget.player!,
                        ),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: songMeta(s).isEmpty ? null : Text(songMeta(s)),
                  trailing: SongStatusPill(s.status),
                ),
              if (songs.length > _first)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showAll = !_showAll;
                    }),
                    child: Text(
                      _showAll
                          ? t.rehearsalsShowLess
                          : t.songsShowAll(songs.length),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Plays or stops a song's recording through the session's player.
class SongPlayButton extends StatelessWidget {
  const SongPlayButton({super.key, required this.path, required this.player});
  final String path;
  final ClipPlayer player;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: player.playing,
    builder: (context, playing, _) {
      final on = playing == songKey(path);
      return IconButton(
        tooltip: on ? context.t.voiceStop : context.t.songPlay,
        onPressed: () => player.toggle(songKey(path)),
        icon: Icon(
          on ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
        ),
      );
    },
  );
}

/// Asks for a name (a song title, a setlist name…); pops it trimmed.
class NameDialog extends StatefulWidget {
  const NameDialog({
    super.key,
    required this.title,
    required this.label,
    required this.action,
    this.maxLength = 100,
    this.hint,
    this.initial = '',
  });

  final String title;
  final String label;

  /// The confirm button's text.
  final String action;
  final int maxLength;
  final String? hint;
  final String initial;

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t.cancel),
        ),
        ValueListenableBuilder(
          valueListenable: _name,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, _name.text.trim()),
            child: Text(widget.action),
          ),
        ),
      ],
    );
  }
}
