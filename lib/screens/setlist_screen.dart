import 'dart:async';

import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../data/song_repository.dart';
import '../l10n/l10n.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../theme.dart';
import '../widgets/songs_section.dart';
import 'song_screen.dart';

/// "5 songs · 23 min · 2 without a recording", in the app's language.
String setlistSummary(List<Song> songs) {
  final t = L10n.current;
  final length = setlistLength(songs);
  return [
    t.setlistSongCount(songs.length),
    if (length.seconds > 0) t.durationMinutes((length.seconds / 60).ceil()),
    if (songs.isNotEmpty && length.unknown > 0)
      t.setlistNoLength(length.unknown),
  ].join(' · ');
}

/// One setlist: its songs in order (hold and drag to reorder, × to take one
/// out), Add songs from the band's list, and ⋮ → Rename / Delete. Every
/// change saves straight away and updates live for the band.
class SetlistScreen extends StatefulWidget {
  const SetlistScreen({
    super.key,
    required this.repository,
    required this.setlist,
    this.player,
  });

  final SongRepository repository;
  final Setlist setlist;

  /// Plays recordings.
  final ClipPlayer? player;

  @override
  State<SetlistScreen> createState() => _SetlistScreenState();
}

class _SetlistScreenState extends State<SetlistScreen> {
  late Setlist _setlist = widget.setlist;
  List<Song>? _songs;
  String? _error;
  StreamSubscription<void>? _sub;

  /// While a change is being saved, live reloads wait (so a drag doesn't
  /// jump back for a moment).
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.repository.changes().listen((_) {
      if (!_saving) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bandId = widget.setlist.bandId;
      final songs = await widget.repository.list(bandId);
      final setlists = await widget.repository.setlists(bandId);
      if (!mounted) return;
      final mine = setlists.where((s) => s.id == _setlist.id).firstOrNull;
      // Deleted by someone else: close.
      if (mine == null) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _songs = songs;
        _setlist = mine;
        _error = null;
      });
    } on UserFacingException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    }
  }

  /// Shows [ids] at once, then saves them; on failure, reloads.
  Future<void> _saveOrder(List<String> ids) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _setlist = _setlist.copyWith(songIds: ids);
      _saving = true;
    });
    try {
      await widget.repository.setSetlistSongs(_setlist.id, ids);
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      _saving = false;
      await _load();
    }
  }

  void _reorder(List<Song> inOrder, int from, int to) {
    final ids = [for (final s in inOrder) s.id];
    ids.insert(to, ids.removeAt(from));
    _saveOrder(ids);
  }

  Future<void> _addSongs() async {
    final songs = _songs ?? const <Song>[];
    final have = _setlist.songIds.toSet();
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AddSongsSheet(
        songs: [
          for (final s in songs)
            if (!have.contains(s.id)) s,
        ],
        bandHasSongs: songs.isNotEmpty,
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    await _saveOrder([..._setlist.songIds, ...picked]);
  }

  Future<void> _rename() async {
    final t = context.t;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => NameDialog(
        title: t.setlistRename,
        label: t.setlistNameLabel,
        action: t.saveChanges,
        maxLength: 60,
        initial: _setlist.name,
      ),
    );
    if (name == null || name == _setlist.name || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.renameSetlist(_setlist.id, name);
      setState(() {
        _setlist = _setlist.copyWith(name: name);
      });
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete() async {
    final t = context.t;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.setlistDeleteTitle(_setlist.name)),
        content: Text(t.setlistDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.setlistDelete),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Live reloads wait, so the screen doesn't close itself on the way.
    _saving = true;
    try {
      await widget.repository.deleteSetlist(_setlist.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.setlistDeleted)));
    } on UserFacingException catch (e) {
      _saving = false;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openSong(Song song) async {
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
    final inOrder = songs == null
        ? const <Song>[]
        : setlistSongs(_setlist, songs);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _setlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<void>(
            tooltip: t.chatMore,
            itemBuilder: (_) => [
              PopupMenuItem(onTap: _rename, child: Text(t.setlistRename)),
              PopupMenuItem(onTap: _delete, child: Text(t.setlistDelete)),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: songs == null
              ? (_error == null
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // No floating button: alerts show at the top, and
                    // Flutter refuses floating alerts above one.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              setlistSummary(inOrder),
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addSongs,
                            icon: const Icon(Icons.playlist_add_rounded),
                            label: Text(t.setlistAddSongs),
                          ),
                        ],
                      ),
                    ),
                    if (inOrder.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: Text(
                          t.setlistDragHint,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (inOrder.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          t.setlistEmptySongs,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    else
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          buildDefaultDragHandles: false,
                          itemCount: inOrder.length,
                          onReorderItem: (from, to) =>
                              _reorder(inOrder, from, to),
                          itemBuilder: (context, i) => _SongRow(
                            key: ValueKey(inOrder[i].id),
                            index: i,
                            song: inOrder[i],
                            player: widget.player,
                            onTap: () => _openSong(inOrder[i]),
                            onRemove: () => _saveOrder([
                              for (final s in inOrder)
                                if (s.id != inOrder[i].id) s.id,
                            ]),
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

/// One numbered song in the setlist. Holding it (or its handle) drags it.
class _SongRow extends StatelessWidget {
  const _SongRow({
    super.key,
    required this.index,
    required this.song,
    required this.onTap,
    required this.onRemove,
    this.player,
  });

  final int index;
  final Song song;
  final ClipPlayer? player;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final meta = [
      if (songMeta(song).isNotEmpty) songMeta(song),
      if (song.recordingSeconds != null) clipLength(song.recordingSeconds!),
    ].join(' · ');
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.only(left: 4, right: 0),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: displayStyle(size: 22, color: colors.onSurface),
                  ),
                ),
              ],
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: meta.isEmpty
                ? null
                : Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (song.recordingPath != null && player != null)
                  SongPlayButton(path: song.recordingPath!, player: player!),
                IconButton(
                  tooltip: t.setlistRemoveSong,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkboxes for the band's songs that aren't in the setlist yet; pops the
/// picked ids in the band's song order.
class _AddSongsSheet extends StatefulWidget {
  const _AddSongsSheet({required this.songs, required this.bandHasSongs});

  final List<Song> songs;
  final bool bandHasSongs;

  @override
  State<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<_AddSongsSheet> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.setlistAddSongs,
                style: displayStyle(size: 24, color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              if (widget.songs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.bandHasSongs
                        ? t.setlistAllAdded
                        : t.setlistNoBandSongs,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              else ...[
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in widget.songs)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _picked.contains(s.id),
                          onChanged: (on) => setState(() {
                            on == true
                                ? _picked.add(s.id)
                                : _picked.remove(s.id);
                          }),
                          title: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: songMeta(s).isEmpty
                              ? null
                              : Text(songMeta(s)),
                          secondary: SongStatusPill(s.status),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _picked.isEmpty
                      ? null
                      : () => Navigator.pop(context, [
                          for (final s in widget.songs)
                            if (_picked.contains(s.id)) s.id,
                        ]),
                  child: Text(t.setlistAddSongsButton(_picked.length)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
