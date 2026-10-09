import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';

/// Your audio clips: play, delete, and upload new ones. Changes are saved
/// right away, separately from the rest of the profile form.
class ClipsSection extends StatefulWidget {
  const ClipsSection({
    super.key,
    required this.clips,
    required this.player,
    this.pickFile,
  });

  final ClipRepository clips;
  final ClipPlayer player;

  /// Chooses a file: returns its name and bytes, or null if cancelled.
  /// Defaults to the system file picker; tests pass their own.
  final Future<(String, Uint8List)?> Function()? pickFile;

  @override
  State<ClipsSection> createState() => _ClipsSectionState();
}

class _ClipsSectionState extends State<ClipsSection> {
  List<MyClip>? _list;
  String? _loadError;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.clips.myClips();
      if (mounted) {
        setState(() {
          _list = list;
          _loadError = null;
        });
      }
    } on UserFacingException catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.message;
        });
      }
    }
  }

  static Future<(String, Uint8List)?> _systemPicker() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) return null;
    return (file.name, await file.readAsBytes());
  }

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    final t = context.t;
    final (String, Uint8List)? picked;
    try {
      picked = await (widget.pickFile ?? _systemPicker)();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.errOpenFiles)));
      return;
    }
    if (picked == null) return;
    setState(() {
      _uploading = true;
    });
    try {
      final clip = await widget.clips.upload(
        fileName: picked.$1,
        bytes: picked.$2,
      );
      if (mounted) {
        setState(() {
          _list = [...?_list, clip];
        });
      }
      messenger.showSnackBar(SnackBar(content: Text(t.clipAdded)));
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _delete(MyClip clip) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.deleteClipTitle),
        content: Text(
          context.t.deleteClipBody(clip.title ?? context.t.clipFallback),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (widget.player.playing.value == clip.path) await widget.player.stop();
    try {
      await widget.clips.delete(clip);
      if (mounted) {
        setState(() {
          _list = _list?.where((c) => c.id != clip.id).toList();
        });
      }
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _play(MyClip clip) async {
    try {
      await widget.player.toggle(clip.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.t.errClipPlay)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_loadError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(_loadError!, style: TextStyle(color: colors.error)),
          ),
          TextButton(onPressed: _load, child: Text(context.t.tryAgain)),
        ],
      );
    }
    final list = _list;
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t.clipsInfo,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String?>(
          valueListenable: widget.player.playing,
          builder: (context, playingPath, _) => Column(
            children: [
              for (final clip in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton.outlined(
                    tooltip: playingPath == clip.path
                        ? context.t.stop
                        : context.t.play,
                    onPressed: () => _play(clip),
                    icon: Icon(
                      playingPath == clip.path
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  title: Text(
                    clip.title ?? context.t.clipFallback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${clip.seconds ~/ 60}:${(clip.seconds % 60).toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    tooltip: context.t.deleteClip,
                    onPressed: () => _delete(clip),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _uploading || list.length >= maxClips ? null : _add,
          icon: _uploading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_rounded),
          label: Text(
            _uploading
                ? context.t.uploading
                : (list.length >= maxClips
                      ? context.t.clipsFull
                      : context.t.addClip),
          ),
        ),
      ],
    );
  }
}
