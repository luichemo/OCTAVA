import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'clip_repository.dart';

/// Opens the system file picker for an audio file and returns its name and
/// bytes, or null if nothing was picked.
///
/// The picker asks for the exact extensions we accept (`.mp3`, `.m4a`, …)
/// rather than "any audio": iPhone Safari greys out files in the Files app
/// for `audio/*`, but offers them for a list of extensions. The name is then
/// passed through [audioFileName], so a file that arrives without a usable
/// extension still uploads with the right type.
Future<(String, Uint8List)?> pickAudioFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: clipMimeTypes.keys.toList(),
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return (audioFileName(file.name, bytes), bytes);
}

/// [name] with an extension from [clipMimeTypes]: unchanged if it already
/// has one, otherwise the type read from the file's first bytes
/// ([audioTypeOf]) is added. Unknown files keep their name, so the upload
/// says the type isn't supported.
String audioFileName(String name, Uint8List bytes) {
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  if (clipMimeTypes.containsKey(ext)) return name;
  final sniffed = audioTypeOf(bytes);
  if (sniffed == null) return name;
  final base = dot < 0 ? name : name.substring(0, dot);
  return '${base.isEmpty ? 'audio' : base}.$sniffed';
}

/// The audio type of [bytes] from their signature, as an extension in
/// [clipMimeTypes], or null when it's not one we accept.
String? audioTypeOf(Uint8List bytes) {
  bool startsWith(List<int> sig, [int at = 0]) {
    if (bytes.length < at + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (bytes[at + i] != sig[i]) return false;
    }
    return true;
  }

  if (startsWith(_ascii('ID3'))) return 'mp3';
  if (startsWith(_ascii('ftyp'), 4)) return 'm4a';
  if (startsWith(_ascii('RIFF')) && startsWith(_ascii('WAVE'), 8)) return 'wav';
  if (startsWith(_ascii('OggS'))) return 'ogg';
  if (startsWith(_ascii('fLaC'))) return 'flac';
  if (startsWith(const [0x1A, 0x45, 0xDF, 0xA3])) return 'webm';
  if (bytes.length >= 2 && bytes[0] == 0xFF) {
    // ADTS AAC: 1111 1111 1111 x00x; MPEG audio (MP3): 1111 1111 111x xxxx.
    if (bytes[1] & 0xF6 == 0xF0) return 'aac';
    if (bytes[1] & 0xE0 == 0xE0) return 'mp3';
  }
  return null;
}

List<int> _ascii(String s) => s.codeUnits;
