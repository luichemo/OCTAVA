import 'dart:async';

import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../data/song_repository.dart';
import '../l10n/l10n.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../screens/setlist_screen.dart';
import '../theme.dart';
import 'songs_section.dart';

/// The band page's setlists: each with its song count and length, Add (a
/// name, then the setlist opens). Updates live.
class SetlistsSection extends StatefulWidget {
  const SetlistsSection({
    super.key,
    required this.repository,
    required this.bandId,
    this.player,
  });

  final SongRepository repository;
  final String bandId;

  /// Plays recordings on an opened setlist.
  final ClipPlayer? player;

  @override
  State<SetlistsSection> createState() => _SetlistsSectionState();
}

class _SetlistsSectionState extends State<SetlistsSection> {
  List<Setlist>? _setlists;
  List<Song> _songs = const [];
  String? _error;
  StreamSubscription<void>? _sub;

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
      final setlists = await widget.repository.setlists(widget.bandId);
      final songs = await widget.repository.list(widget.bandId);
      if (!mounted) return;
      setState(() {
        _setlists = setlists;
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
    final t = context.t;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => NameDialog(
        title: t.setlistAddTitle,
        label: t.setlistNameLabel,
        hint: t.setlistNameHint,
        action: t.rehearsalAdd,
        maxLength: 60,
      ),
    );
    if (name == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final setlist = await widget.repository.addSetlist(widget.bandId, name);
      await _load();
      if (mounted) await _open(setlist);
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _open(Setlist setlist) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SetlistScreen(
          repository: widget.repository,
          setlist: setlist,
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
    final setlists = _setlists;
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
                    t.setlistsTitle,
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
            if (_error != null && setlists == null)
              Text(_error!, style: TextStyle(color: colors.error))
            else if (setlists == null)
              const Center(child: CircularProgressIndicator())
            else if (setlists.isEmpty)
              Text(
                t.setlistsEmpty,
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else
              for (final s in setlists)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  onTap: () => _open(s),
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(setlistSummary(setlistSongs(s, _songs))),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
          ],
        ),
      ),
    );
  }
}
