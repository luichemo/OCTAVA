import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../data/song_repository.dart';
import '../l10n/l10n.dart';
import '../models/profile_link.dart';
import '../models/song.dart';
import '../theme.dart';
import '../widgets/record_sheet.dart';
import '../widgets/songs_section.dart';

/// One song: title, key, tempo, status, notes and links (saved together),
/// and its recording (record or upload, play, remove: saved at once).
/// ⋮ → Delete song.
class SongScreen extends StatefulWidget {
  const SongScreen({
    super.key,
    required this.repository,
    required this.song,
    this.player,
  });

  final SongRepository repository;
  final Song song;
  final ClipPlayer? player;

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  late Song _song = widget.song;
  late final _title = TextEditingController(text: _song.title);
  late final _key = TextEditingController(text: _song.songKey ?? '');
  late final _tempo = TextEditingController(
    text: _song.tempo?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: _song.notes ?? '');
  late SongStatus _status = _song.status;
  late final List<String> _links = List.of(_song.links);
  final _linkInput = TextEditingController();
  String? _linkError;
  bool _saving = false;

  static const _maxLinks = 5;

  @override
  void dispose() {
    for (final c in [_title, _key, _tempo, _notes, _linkInput]) {
      c.dispose();
    }
    super.dispose();
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _addLink() {
    final link = ProfileLink.fromInput(_linkInput.text);
    setState(() {
      if (link == null) {
        _linkError = context.t.linkCheckError;
      } else {
        _links.add(link.url);
        _linkInput.clear();
        _linkError = null;
      }
    });
  }

  Future<void> _save() async {
    final t = context.t;
    if (_title.text.trim().isEmpty) {
      _say(t.songTitleError);
      return;
    }
    if (_linkInput.text.trim().isNotEmpty) _addLink();
    final tempo = int.tryParse(_tempo.text.trim());
    if (_tempo.text.trim().isNotEmpty &&
        (tempo == null || tempo < 20 || tempo > 320)) {
      _say(t.songTempoError);
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      _song = await widget.repository.update(_song.id, (
        title: _title.text,
        songKey: _key.text,
        tempo: tempo,
        notes: _notes.text,
        status: _status,
        links: _links,
      ));
      if (mounted) {
        _say(t.songSaved);
        Navigator.pop(context);
      }
    } on UserFacingException catch (e) {
      if (mounted) _say(e.message);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _record() async {
    final t = context.t;
    await widget.player?.stop();
    if (!mounted) return;
    await showRecordSheet(
      context,
      maxSeconds: maxSongSeconds,
      saveLabel: t.songUseRecording,
      savedMessage: t.songRecordingSaved,
      save: ({required bytes, required fileName, int? knownSeconds}) async {
        final updated = await widget.repository.uploadRecording(
          _song,
          bytes: bytes,
          fileName: fileName,
          knownSeconds: knownSeconds,
        );
        if (mounted) {
          setState(() {
            _song = updated;
          });
        }
      },
    );
  }

  Future<void> _removeRecording() async {
    await widget.player?.stop();
    try {
      final updated = await widget.repository.removeRecording(_song);
      if (mounted) {
        setState(() {
          _song = updated;
        });
      }
    } on UserFacingException catch (e) {
      if (mounted) _say(e.message);
    }
  }

  Future<void> _delete() async {
    final t = context.t;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.songDeleteTitle(_song.title)),
        content: Text(t.songDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.songDelete),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await widget.player?.stop();
      await widget.repository.delete(_song);
      navigator.pop();
    } on UserFacingException catch (e) {
      if (mounted) _say(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final path = _song.recordingPath;
    final player = widget.player;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.songPageTitle),
        actions: [
          PopupMenuButton<void>(
            tooltip: t.chatMore,
            itemBuilder: (_) => [
              PopupMenuItem(onTap: _delete, child: Text(t.songDelete)),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              TextField(
                controller: _title,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: t.songTitleLabel),
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _key,
                      maxLength: 20,
                      decoration: InputDecoration(
                        labelText: t.songKeyLabel,
                        hintText: t.songKeyHint,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _tempo,
                      maxLength: 3,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.songTempoLabel,
                        hintText: '120',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SegmentedButton<SongStatus>(
                showSelectedIcon: false,
                segments: [
                  for (final s in SongStatus.values)
                    ButtonSegment(value: s, label: Text(songStatusLabel(s))),
                ],
                selected: {_status},
                onSelectionChanged: (v) => setState(() {
                  _status = v.single;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                maxLength: 1000,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: t.songNotesLabel,
                  hintText: t.songNotesHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.songLinksLabel,
                style: displayStyle(size: 22, color: colors.onSurface),
              ),
              for (final (i, url) in _links.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link_rounded),
                  title: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ),
                  trailing: IconButton(
                    tooltip: t.songRemoveLink,
                    onPressed: () => setState(() {
                      _links.removeAt(i);
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ),
              if (_links.length < _maxLinks)
                TextField(
                  controller: _linkInput,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addLink(),
                  decoration: InputDecoration(
                    hintText: t.songLinkHint,
                    errorText: _linkError,
                    suffixIcon: IconButton(
                      tooltip: t.songAddLink,
                      onPressed: _addLink,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                t.songRecordingLabel,
                style: displayStyle(size: 22, color: colors.onSurface),
              ),
              Row(
                children: [
                  if (path != null && player != null)
                    ValueListenableBuilder<String?>(
                      valueListenable: player.playing,
                      builder: (context, playing, _) {
                        final on = playing == songKey(path);
                        return IconButton.filled(
                          tooltip: on ? t.voiceStop : t.songPlay,
                          onPressed: () => player.toggle(songKey(path)),
                          style: IconButton.styleFrom(
                            backgroundColor: OctavaColors.pink,
                            foregroundColor: OctavaColors.ink,
                          ),
                          icon: Icon(
                            on ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path == null
                          ? t.songNoRecording
                          : clipLength(_song.recordingSeconds ?? 0),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  IconButton(
                    tooltip: path == null
                        ? t.songAddRecording
                        : t.songReplaceRecording,
                    onPressed: _record,
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                  if (path != null)
                    IconButton(
                      tooltip: t.songRemoveRecording,
                      onPressed: _removeRecording,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              PrintButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Text(t.saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
