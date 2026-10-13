import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// A finished recording, ready to upload. [path] is where the recorder left
/// it (a blob: link on the web, a temp file on phones), for playing back.
typedef Recording = ({
  Uint8List bytes,
  String fileName,
  int seconds,
  String path,
});

/// Records from the microphone.
abstract interface class VoiceRecorder {
  /// Asks for microphone access if needed. False when refused.
  Future<bool> hasPermission();

  Future<void> start();

  /// Stops and returns the recording, or null if nothing was recorded.
  Future<Recording?> stop();

  /// Stops and throws the recording away.
  Future<void> cancel();

  /// Input level from 0 (silence) to 1 (loud), a few times a second.
  Stream<double> levels();

  /// Whether a take is being played back.
  ValueListenable<bool> get playingBack;

  /// Plays [take], or stops it if it's playing.
  Future<void> togglePlayback(Recording take);

  Future<void> stopPlayback();

  Future<void> dispose();
}

/// [VoiceRecorder] using the record package. Everything is compressed, to
/// save storage and download bandwidth: phones record M4A (AAC). The web
/// records AAC too where the browser can (Chrome, Edge, Safari), else Opus
/// in WebM (Firefox), and only falls back to large WAV if neither works.
/// The length is measured by the clock while recording, so it doesn't
/// matter that browser recordings often carry no readable length.
class DeviceVoiceRecorder implements VoiceRecorder {
  DeviceVoiceRecorder() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) stopPlayback();
    });
  }

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  DateTime? _startedAt;

  @override
  final ValueNotifier<bool> playingBack = ValueNotifier(false);

  String _extension = 'm4a';

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final (encoder, extension) = kIsWeb
        ? await _webFormat()
        : (AudioEncoder.aacLc, 'm4a');
    _extension = extension;
    final config = encoder == AudioEncoder.wav
        ? const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 22050,
            numChannels: 1,
          )
        : RecordConfig(
            encoder: encoder,
            sampleRate: 44100,
            numChannels: 1,
            // Mono AAC at 64 kbps sounds close to a 128 kbps stereo MP3:
            // about 0.5 MB a minute, against 2.6 MB for the old web WAV.
            bitRate: 64000,
          );
    // The web keeps recordings in memory; phones need a file path.
    final path = kIsWeb
        ? 'octava.$_extension'
        : '${(await getTemporaryDirectory()).path}/octava_${DateTime.now().millisecondsSinceEpoch}.$_extension';
    await _recorder.start(config, path: path);
    _startedAt = DateTime.now();
  }

  /// The most compact format this browser can record, with its extension.
  /// AAC first: it also plays in the iPhone app, which can't play WebM.
  Future<(AudioEncoder, String)> _webFormat() async {
    if (await _recorder.isEncoderSupported(AudioEncoder.aacLc)) {
      return (AudioEncoder.aacLc, 'm4a');
    }
    if (await _recorder.isEncoderSupported(AudioEncoder.opus)) {
      return (AudioEncoder.opus, 'webm');
    }
    return (AudioEncoder.wav, 'wav');
  }

  @override
  Future<Recording?> stop() async {
    final path = await _recorder.stop();
    final started = _startedAt;
    _startedAt = null;
    if (path == null || started == null) return null;
    // A file path on phones, a blob: link on the web; XFile reads both.
    final bytes = await XFile(path).readAsBytes();
    final seconds = (DateTime.now().difference(started).inMilliseconds / 1000)
        .round();
    final stamp = DateTime.now();
    final name =
        'Recording ${stamp.year}-${_two(stamp.month)}-${_two(stamp.day)} ${_two(stamp.hour)}.${_two(stamp.minute)}';
    return (
      bytes: bytes,
      fileName: '$name.$_extension',
      seconds: seconds,
      path: path,
    );
  }

  @override
  Future<void> cancel() async {
    _startedAt = null;
    await _recorder.cancel();
  }

  @override
  Stream<double> levels() => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      // dBFS: about -50 is quiet, 0 is the loudest possible.
      .map((a) => ((a.current + 50) / 50).clamp(0.0, 1.0));

  @override
  Future<void> togglePlayback(Recording take) async {
    if (playingBack.value) return stopPlayback();
    // The web's recording is a blob: link; phones have a file.
    if (kIsWeb) {
      await _player.setUrl(take.path);
    } else {
      await _player.setFilePath(take.path);
    }
    playingBack.value = true;
    // play() only completes when playback ends, so don't wait for it.
    unawaited(_player.play());
  }

  @override
  Future<void> stopPlayback() async {
    playingBack.value = false;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    playingBack.dispose();
    await _player.dispose();
    await _recorder.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
