import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories.dart';

/// One of your own audio clips.
class MyClip {
  const MyClip({
    required this.id,
    required this.path,
    required this.seconds,
    this.title,
  });

  final String id;

  /// Path in the `clips` storage bucket.
  final String path;
  final String? title;
  final int seconds;
}

/// File types the `clips` bucket accepts, by extension.
const clipMimeTypes = <String, String>{
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'aac': 'audio/aac',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'oga': 'audio/ogg',
  'webm': 'audio/webm',
  'flac': 'audio/flac',
};

const maxClips = 5;
// 2:00, matches the audio_clips check in the database.
const maxClipSeconds = 120;
const maxClipBytes = 10 * 1024 * 1024;

/// Uploading, listing, deleting and playing audio clips.
abstract interface class ClipRepository {
  Future<List<MyClip>> myClips();

  /// Uploads a file and adds it to your profile. Checks the type, size and
  /// length first and explains any problem with a [UserFacingException].
  Future<MyClip> upload({required Uint8List bytes, required String fileName});

  Future<void> delete(MyClip clip);

  /// A temporary link for playing a clip.
  Future<String> playbackUrl(String path);
}

class SupabaseClipRepository implements ClipRepository {
  SupabaseClipRepository(this._client);
  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;
  StorageFileApi get _bucket => _client.storage.from('clips');

  @override
  Future<List<MyClip>> myClips() async {
    try {
      final rows = await _client
          .from('audio_clips')
          .select('id, storage_path, title, duration_seconds')
          .eq('profile_id', _uid)
          .order('created_at');
      return [
        for (final r in rows)
          MyClip(
            id: r['id'] as String,
            path: r['storage_path'] as String,
            title: r['title'] as String?,
            seconds: r['duration_seconds'] as int,
          ),
      ];
    } catch (_) {
      throw const UserFacingException(
        "Couldn't load your clips. Check your connection and try again.",
      );
    }
  }

  @override
  Future<MyClip> upload({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final mime = clipMimeTypes[ext];
    if (mime == null) {
      throw const UserFacingException(
        'Use an MP3, M4A, AAC, WAV, OGG, WEBM or FLAC file.',
      );
    }
    if (bytes.length > maxClipBytes) {
      throw const UserFacingException(
        'That file is over 10 MB. Try a shorter or more compressed clip.',
      );
    }
    if ((await myClips()).length >= maxClips) {
      throw const UserFacingException(
        'You can have up to 5 clips. Delete one to add another.',
      );
    }

    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime),
      );
    } catch (_) {
      throw const UserFacingException(
        "Couldn't upload your clip. Check your connection and try again.",
      );
    }

    // Measure the uploaded file; remove it again if it can't be used.
    final seconds = await _measure(path);
    if (seconds == null || seconds > maxClipSeconds) {
      await _bucket.remove([path]).catchError((_) => <FileObject>[]);
      throw UserFacingException(
        seconds == null
            ? "Couldn't play that file. Try exporting it as MP3 or M4A."
            : 'Clips can be up to 2 minutes. This one is ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}.',
      );
    }

    final title = _titleFrom(fileName);
    try {
      final row = await _client
          .from('audio_clips')
          .insert({
            'profile_id': _uid,
            'storage_path': path,
            'title': title,
            'duration_seconds': seconds,
          })
          .select('id')
          .single();
      return MyClip(
        id: row['id'] as String,
        path: path,
        title: title,
        seconds: seconds,
      );
    } catch (e) {
      await _bucket.remove([path]).catchError((_) => <FileObject>[]);
      if (e is PostgrestException &&
          e.code == '23514' &&
          !e.message.startsWith('new row')) {
        throw UserFacingException(e.message); // e.g. the 5-clip limit
      }
      throw const UserFacingException("Couldn't save your clip. Try again.");
    }
  }

  @override
  Future<void> delete(MyClip clip) async {
    try {
      await _client.from('audio_clips').delete().eq('id', clip.id);
      await _bucket.remove([clip.path]);
    } catch (_) {
      throw const UserFacingException(
        "Couldn't delete the clip. Check your connection and try again.",
      );
    }
  }

  @override
  Future<String> playbackUrl(String path) async {
    try {
      return await _bucket.createSignedUrl(path, 60 * 60);
    } catch (_) {
      throw const UserFacingException(
        "Couldn't play the clip. Check your connection and try again.",
      );
    }
  }

  /// Length in whole seconds (at least 1), or null if it can't be read.
  Future<int?> _measure(String path) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setUrl(await playbackUrl(path));
      if (duration == null) return null;
      return (duration.inMilliseconds / 1000).ceil().clamp(1, 1 << 30);
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }

  /// "My Song (demo).mp3" → "My Song (demo)", at most 60 characters.
  static String _titleFrom(String fileName) {
    final base = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final clean = base.replaceAll(RegExp(r'[_\s]+'), ' ').trim();
    return clean.length > 60 ? clean.substring(0, 60) : clean;
  }
}

/// Plays one clip at a time, for the whole app.
abstract interface class ClipPlayer {
  /// Storage path of the clip that's playing, or null.
  ValueListenable<String?> get playing;

  Stream<Duration> get position;

  /// Plays [path], or stops it if it's already playing.
  Future<void> toggle(String path);

  Future<void> stop();

  Future<void> dispose();
}

/// [ClipPlayer] using just_audio (web, Android and iOS).
class JustAudioClipPlayer implements ClipPlayer {
  JustAudioClipPlayer(this._urlFor) {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) stop();
    });
  }

  final Future<String> Function(String path) _urlFor;
  final AudioPlayer _player = AudioPlayer();

  @override
  final ValueNotifier<String?> playing = ValueNotifier(null);

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Future<void> toggle(String path) async {
    if (playing.value == path) return stop();
    await _player.stop();
    playing.value = path;
    try {
      await _player.setUrl(await _urlFor(path));
      // play() only completes when playback ends, so don't wait for it.
      if (playing.value == path) unawaited(_player.play());
    } catch (_) {
      if (playing.value == path) playing.value = null;
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    playing.value = null;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    playing.dispose();
    await _player.dispose();
  }
}
