import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Whole seconds (rounded up) of the audio in [bytes], decoded by the
/// browser, or null if it can't decode them.
///
/// Measuring an uploaded file through an audio element doesn't work in
/// iPhone Safari, which won't load media without a fresh tap, so files are
/// measured here, before uploading.
Future<int?> audioBytesSeconds(Uint8List bytes) async {
  web.AudioContext? context;
  try {
    context = web.AudioContext();
    // decodeAudioData takes over (detaches) the buffer, so give it a copy.
    final copy = Uint8List.fromList(bytes);
    final audio = await context.decodeAudioData(copy.buffer.toJS).toDart;
    return audio.duration.ceil().clamp(1, 1 << 30);
  } catch (_) {
    return null;
  } finally {
    context?.close();
  }
}
