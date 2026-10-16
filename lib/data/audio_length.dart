// The length of an audio file from its bytes, before it's uploaded. Only
// the browser can do this (Web Audio's decodeAudioData); on phones it
// returns null and the app measures the uploaded file with just_audio.
export 'audio_length_stub.dart'
    if (dart.library.js_interop) 'audio_length_web.dart';
