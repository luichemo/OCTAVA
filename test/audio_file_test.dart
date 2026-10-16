import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/audio_file.dart';
import 'package:octava/data/audio_length.dart';

Uint8List bytes(List<int> start) =>
    Uint8List.fromList([...start, ...List.filled(16, 0)]);
List<int> ascii(String s) => s.codeUnits;

void main() {
  test('audio types are read from the file\'s first bytes', () {
    expect(audioTypeOf(bytes(ascii('ID3'))), 'mp3');
    expect(audioTypeOf(bytes([0xFF, 0xFB, 0x90])), 'mp3');
    expect(audioTypeOf(bytes([0xFF, 0xF1, 0x50])), 'aac');
    expect(audioTypeOf(bytes([0, 0, 0, 0x20, ...ascii('ftypM4A ')])), 'm4a');
    expect(
      audioTypeOf(bytes([...ascii('RIFF'), 0, 0, 0, 0, ...ascii('WAVE')])),
      'wav',
    );
    expect(audioTypeOf(bytes(ascii('OggS'))), 'ogg');
    expect(audioTypeOf(bytes(ascii('fLaC'))), 'flac');
    expect(audioTypeOf(bytes([0x1A, 0x45, 0xDF, 0xA3])), 'webm');
    expect(audioTypeOf(bytes(ascii('%PDF'))), isNull);
    expect(audioTypeOf(Uint8List(0)), isNull);
  });

  test('a file without a usable extension gets one from its bytes', () {
    final mp3 = bytes(ascii('ID3'));
    expect(audioFileName('riff.mp3', mp3), 'riff.mp3');
    expect(audioFileName('Riff.MP3', mp3), 'Riff.MP3');
    expect(audioFileName('riff', mp3), 'riff.mp3');
    expect(audioFileName('riff.tmp', mp3), 'riff.mp3');
    expect(audioFileName('.mp3x', mp3), 'audio.mp3');
    // Not audio we know: left alone, so the upload explains the type.
    expect(audioFileName('notes.pdf', bytes(ascii('%PDF'))), 'notes.pdf');
  });

  test('outside the browser the length is measured after uploading', () async {
    expect(await audioBytesSeconds(bytes(ascii('ID3'))), isNull);
  });
}
