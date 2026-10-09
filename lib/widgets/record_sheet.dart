import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../data/voice_recorder.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// Opens the recorder: it starts recording right away, then the person adds
/// the take to their profile, records again, or uploads a file instead.
Future<void> showRecordSheet(
  BuildContext context, {
  required ClipRepository clips,
  VoiceRecorder Function()? recorder,
  Future<(String, Uint8List)?> Function()? pickFile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RecordSheet(
      clips: clips,
      recorder: (recorder ?? DeviceVoiceRecorder.new)(),
      pickFile: pickFile,
    ),
  );
}

enum _Stage { starting, recording, recorded, saving }

class RecordSheet extends StatefulWidget {
  const RecordSheet({
    super.key,
    required this.clips,
    required this.recorder,
    this.pickFile,
  });

  final ClipRepository clips;
  final VoiceRecorder recorder;

  /// Chooses a file for "Upload a file instead"; defaults to the system picker.
  final Future<(String, Uint8List)?> Function()? pickFile;

  @override
  State<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<RecordSheet> {
  _Stage _stage = _Stage.starting;
  int _seconds = 0;
  double _level = 0;
  Recording? _take;
  Timer? _timer;
  StreamSubscription<double>? _levels;

  @override
  void initState() {
    super.initState();
    // Start right after the first frame: _start needs translations, which
    // aren't available yet during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _levels?.cancel();
    // Closing the sheet mid-recording throws the take away.
    if (_stage == _Stage.recording) widget.recorder.cancel();
    widget.recorder.dispose();
    super.dispose();
  }

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _start() async {
    final t = context.t;
    await widget.recorder.stopPlayback();
    if (!mounted) return;
    setState(() {
      _stage = _Stage.starting;
      _seconds = 0;
      _take = null;
    });
    try {
      if (!await widget.recorder.hasPermission()) {
        if (!mounted) return;
        Navigator.of(context).pop();
        _say(t.errMicDenied);
        return;
      }
      await widget.recorder.start();
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _say(t.errRecord);
      return;
    }
    if (!mounted) return;
    setState(() {
      _stage = _Stage.recording;
    });
    _levels = widget.recorder.levels().listen((v) {
      if (mounted) {
        setState(() {
          _level = v;
        });
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
      });
      if (_seconds >= maxClipSeconds) _stop(); // the clip limit
    });
  }

  Future<void> _stop() async {
    final t = context.t;
    _timer?.cancel();
    // No need to wait for the level meter to close.
    unawaited(_levels?.cancel());
    final take = await widget.recorder.stop().catchError((Object _) => null);
    if (!mounted) return;
    if (take == null) {
      _say(t.errRecord);
      return _start();
    }
    if (take.seconds < 1) {
      _say(t.errRecordShort);
      return _start();
    }
    setState(() {
      _take = take;
      _stage = _Stage.recorded;
      _level = 0;
    });
  }

  Future<void> _listen() async {
    try {
      await widget.recorder.togglePlayback(_take!);
    } catch (_) {
      if (mounted) _say(context.t.errClipPlay);
    }
  }

  Future<void> _save() async {
    final take = _take!;
    final t = context.t;
    final navigator = Navigator.of(context);
    await widget.recorder.stopPlayback();
    if (!mounted) return;
    setState(() {
      _stage = _Stage.saving;
    });
    try {
      await widget.clips.upload(
        bytes: take.bytes,
        fileName: take.fileName,
        knownSeconds: take.seconds,
      );
      navigator.pop();
      _say(t.clipAdded);
    } on UserFacingException catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.recorded;
      });
      _say(e.message);
    }
  }

  Future<void> _uploadFile() async {
    final t = context.t;
    final navigator = Navigator.of(context);
    _timer?.cancel();
    if (_stage == _Stage.recording) await widget.recorder.cancel();
    final (String, Uint8List)? picked;
    try {
      picked = await (widget.pickFile ?? _systemPicker)();
    } catch (_) {
      _say(t.errOpenFiles);
      return;
    }
    if (picked == null) {
      // Back to recording if they changed their mind.
      if (mounted) _start();
      return;
    }
    if (mounted) {
      setState(() {
        _stage = _Stage.saving;
      });
    }
    try {
      await widget.clips.upload(fileName: picked.$1, bytes: picked.$2);
      navigator.pop();
      _say(t.clipAdded);
    } on UserFacingException catch (e) {
      _say(e.message);
      if (mounted) _start();
    }
  }

  static Future<(String, Uint8List)?> _systemPicker() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) return null;
    return (file.name, await file.readAsBytes());
  }

  static String _clock(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.t;
    final recording = _stage == _Stage.recording;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(
              t.recordTitle,
              style: displayStyle(size: 36, color: colors.onSurface),
            ),
            Row(
              spacing: 12,
              children: [
                Icon(
                  Icons.fiber_manual_record_rounded,
                  color: recording ? OctavaColors.pink : colors.outlineVariant,
                ),
                Expanded(
                  child: Text(
                    switch (_stage) {
                      _Stage.starting => t.recordStarting,
                      _Stage.recording => t.recordRecording,
                      _ => t.recordDone(_clock(_take?.seconds ?? _seconds)),
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_clock(_seconds)} / ${_clock(maxClipSeconds)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            // Input level, so it's clear the microphone hears something.
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: recording ? _level : 0,
                minHeight: 10,
                color: OctavaColors.pink,
                backgroundColor: colors.outlineVariant,
              ),
            ),
            Text(
              t.recordLimit,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (_stage == _Stage.recorded || _stage == _Stage.saving) ...[
              ValueListenableBuilder<bool>(
                valueListenable: widget.recorder.playingBack,
                builder: (context, playing, _) => OutlinedButton.icon(
                  onPressed: _stage == _Stage.saving ? null : _listen,
                  icon: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(playing ? t.recordStopListening : t.recordListen),
                ),
              ),
              FilledButton.icon(
                onPressed: _stage == _Stage.saving ? null : _save,
                icon: _stage == _Stage.saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(t.recordSave),
              ),
              OutlinedButton.icon(
                onPressed: _stage == _Stage.saving ? null : _start,
                icon: const Icon(Icons.mic_rounded),
                label: Text(t.recordAgain),
              ),
            ] else
              FilledButton.icon(
                onPressed: recording ? _stop : null,
                icon: const Icon(Icons.stop_rounded),
                label: Text(t.recordStop),
              ),
            TextButton.icon(
              onPressed: _stage == _Stage.saving ? null : _uploadFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(t.recordUploadFile),
            ),
          ],
        ),
      ),
    );
  }
}
