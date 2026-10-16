import 'dart:async';

import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../data/voice_recorder.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// The message box under a chat: type and send, or (with [onSendVoice])
/// tap the mic to record a voice message, then cancel or send it.
/// Recordings stop by themselves at 2:00.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSendText,
    this.onSendVoice,
    this.recorder,
  });

  /// Sends the text; a [UserFacingException] is shown and the text kept.
  final Future<void> Function(String text) onSendText;

  /// Sends a recording. Without it there's no mic button.
  final Future<void> Function(Recording take)? onSendVoice;

  /// Makes the recorder; defaults to the device's microphone.
  final VoiceRecorder Function()? recorder;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _input = TextEditingController();
  bool _sending = false;
  VoiceRecorder? _recorder;
  Timer? _timer;
  int _seconds = 0;

  bool get _recording => _recorder != null;

  @override
  void initState() {
    super.initState();
    // Swap between the mic and send buttons as text comes and goes.
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.cancel();
    _recorder?.dispose();
    _input.dispose();
    super.dispose();
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
    });
    try {
      await widget.onSendText(text);
      _input.clear();
    } on UserFacingException catch (e) {
      if (mounted) _say(e.message);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _startRecording() async {
    final t = context.t;
    final recorder = (widget.recorder ?? DeviceVoiceRecorder.new)();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        if (mounted) _say(t.errMicDenied);
        return;
      }
      await recorder.start();
    } catch (_) {
      await recorder.dispose();
      if (mounted) _say(t.errRecord);
      return;
    }
    if (!mounted) {
      await recorder.cancel();
      await recorder.dispose();
      return;
    }
    setState(() {
      _recorder = recorder;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
      });
      if (_seconds >= maxClipSeconds) _sendVoice();
    });
  }

  Future<void> _cancelRecording() async {
    final recorder = _recorder;
    if (recorder == null) return;
    _timer?.cancel();
    setState(() {
      _recorder = null;
    });
    await recorder.cancel();
    await recorder.dispose();
  }

  Future<void> _sendVoice() async {
    final recorder = _recorder;
    if (recorder == null || _sending) return;
    final t = context.t;
    _timer?.cancel();
    setState(() {
      _sending = true;
    });
    try {
      final take = await recorder.stop();
      if (take == null || take.seconds < 1) {
        if (mounted) _say(t.errRecordShort);
        return;
      }
      await widget.onSendVoice!(take);
    } on UserFacingException catch (e) {
      if (mounted) _say(e.message);
    } catch (_) {
      if (mounted) _say(t.errRecord);
    } finally {
      await recorder.dispose();
      if (mounted) {
        setState(() {
          _recorder = null;
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final sendStyle = IconButton.styleFrom(
      backgroundColor: OctavaColors.pink,
      foregroundColor: OctavaColors.ink,
      minimumSize: const Size(48, 48),
    );
    if (_recording) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 12),
        child: Row(
          spacing: 6,
          children: [
            IconButton(
              tooltip: t.voiceCancel,
              onPressed: _sending ? null : _cancelRecording,
              icon: const Icon(Icons.close_rounded),
            ),
            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
            Expanded(
              child: Text(
                t.voiceRecording(clipLength(_seconds)),
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton.filled(
              tooltip: t.voiceSend,
              onPressed: _sending ? null : _sendVoice,
              style: sendStyle,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      );
    }
    final canRecord = widget.onSendVoice != null && _input.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
      child: Row(
        spacing: 6,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: t.messageHint,
                counterText: '',
              ),
            ),
          ),
          if (canRecord)
            IconButton.filled(
              tooltip: t.voiceRecord,
              onPressed: _startRecording,
              style: sendStyle,
              icon: const Icon(Icons.mic_rounded),
            )
          else
            IconButton.filled(
              tooltip: t.send,
              onPressed: _sending ? null : _sendText,
              style: sendStyle,
              icon: const Icon(Icons.send_rounded),
            ),
        ],
      ),
    );
  }
}
