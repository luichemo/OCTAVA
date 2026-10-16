import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/song.dart';
import 'clip_repository.dart';
import 'repositories.dart';

/// Song recordings can be full songs: up to 10 minutes.
const maxSongSeconds = 600;

/// How a song recording is named to the session's ClipPlayer: `song:<path>`.
String songKey(String path) => '$_songPrefix$path';
const _songPrefix = 'song:';

/// The band-songs path inside a [songKey], or null for other clips.
String? songPath(String key) =>
    key.startsWith(_songPrefix) ? key.substring(_songPrefix.length) : null;

/// The band's songs.
abstract interface class SongRepository {
  /// Ready songs first (see sortSongs).
  Future<List<Song>> list(String bandId);

  /// Adds a song with just a title; returns it.
  Future<Song> add(String bandId, String title);
  Future<Song> update(String songId, SongDraft draft);

  /// Deletes the song and its recording.
  Future<void> delete(Song song);

  /// Uploads (or replaces) the song's recording. Returns the updated song.
  Future<Song> uploadRecording(
    Song song, {
    required Uint8List bytes,
    required String fileName,
    int? knownSeconds,
  });

  Future<Song> removeRecording(Song song);

  /// A temporary link for playing a song recording.
  Future<String> recordingUrl(String path);

  /// Fires when a song in any of your bands changes.
  Stream<void> changes();
}

class SupabaseSongRepository implements SongRepository {
  SupabaseSongRepository(this._client);
  final SupabaseClient _client;

  StorageFileApi get _bucket => _client.storage.from('band-songs');
  String get _me => _client.auth.currentUser!.id;

  static const _columns =
      'id, band_id, title, song_key, tempo, notes, status, links, '
      'recording_path, recording_seconds';

  Future<T> _do<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on UserFacingException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw UserFacingException(L10n.current.errBandNotMember);
      }
      throw UserFacingException(L10n.current.errSongSave);
    } catch (_) {
      throw UserFacingException(L10n.current.errBandAction);
    }
  }

  @override
  Future<List<Song>> list(String bandId) async {
    try {
      final rows = await _client
          .from('songs')
          .select(_columns)
          .eq('band_id', bandId);
      return sortSongs([for (final r in rows) Song.fromRow(r)]);
    } catch (_) {
      throw UserFacingException(L10n.current.errSongsLoad);
    }
  }

  @override
  Future<Song> add(String bandId, String title) => _do(() async {
    final row = await _client
        .from('songs')
        .insert({'band_id': bandId, 'title': title.trim(), 'created_by': _me})
        .select(_columns)
        .single();
    return Song.fromRow(row);
  });

  @override
  Future<Song> update(String songId, SongDraft d) => _do(() async {
    final row = await _client
        .from('songs')
        .update({
          'title': d.title.trim(),
          'song_key': d.songKey.trim().isEmpty ? null : d.songKey.trim(),
          'tempo': d.tempo,
          'notes': d.notes.trim().isEmpty ? null : d.notes.trim(),
          'status': d.status.name,
          'links': d.links,
        })
        .eq('id', songId)
        .select(_columns)
        .single();
    return Song.fromRow(row);
  });

  @override
  Future<void> delete(Song song) => _do(() async {
    await _client.from('songs').delete().eq('id', song.id);
    if (song.recordingPath case final path?) {
      await _bucket.remove([path]).catchError((_) => <FileObject>[]);
    }
  });

  @override
  Future<Song> uploadRecording(
    Song song, {
    required Uint8List bytes,
    required String fileName,
    int? knownSeconds,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final mime = clipMimeTypes[ext];
    if (mime == null) throw UserFacingException(L10n.current.errClipType);
    if (bytes.length > maxClipBytes) {
      throw UserFacingException(L10n.current.errClipSize);
    }
    final path = '${song.bandId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime),
      );
    } catch (_) {
      throw UserFacingException(L10n.current.errClipUpload);
    }
    Future<void> discard() =>
        _bucket.remove([path]).catchError((_) => <FileObject>[]);
    final seconds =
        knownSeconds ?? await measureClipSeconds(await recordingUrl(path));
    if (seconds == null || seconds > maxSongSeconds) {
      await discard();
      throw UserFacingException(
        seconds == null
            ? L10n.current.errClipUnreadable
            : L10n.current.errSongTooLong(clipLength(seconds)),
      );
    }
    try {
      final updated = await _do(() async {
        final row = await _client
            .from('songs')
            .update({'recording_path': path, 'recording_seconds': seconds})
            .eq('id', song.id)
            .select(_columns)
            .single();
        return Song.fromRow(row);
      });
      if (song.recordingPath case final old?) {
        await _bucket.remove([old]).catchError((_) => <FileObject>[]);
      }
      return updated;
    } catch (_) {
      await discard();
      rethrow;
    }
  }

  @override
  Future<Song> removeRecording(Song song) => _do(() async {
    final row = await _client
        .from('songs')
        .update({'recording_path': null, 'recording_seconds': null})
        .eq('id', song.id)
        .select(_columns)
        .single();
    if (song.recordingPath case final old?) {
      await _bucket.remove([old]).catchError((_) => <FileObject>[]);
    }
    return Song.fromRow(row);
  });

  @override
  Future<String> recordingUrl(String path) async {
    try {
      return await _bucket.createSignedUrl(path, 3600);
    } catch (_) {
      throw UserFacingException(L10n.current.errClipPlay);
    }
  }

  @override
  Stream<void> changes() {
    late final RealtimeChannel channel;
    final out = StreamController<void>(
      onCancel: () => _client.removeChannel(channel),
    );
    channel = _client.channel('songs-$_me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'songs',
        callback: (_) {
          if (!out.isClosed) out.add(null);
        },
      )
      ..subscribe();
    return out.stream;
  }
}
