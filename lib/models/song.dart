/// Where a song stands for the band (the database's `song_status`).
enum SongStatus { idea, learning, ready }

/// One of the band's songs.
class Song {
  const Song({
    required this.id,
    required this.bandId,
    required this.title,
    this.songKey,
    this.tempo,
    this.notes,
    this.status = SongStatus.idea,
    this.links = const [],
    this.recordingPath,
    this.recordingSeconds,
  });

  factory Song.fromRow(Map<String, dynamic> row) => Song(
    id: row['id'] as String,
    bandId: row['band_id'] as String,
    title: row['title'] as String,
    songKey: row['song_key'] as String?,
    tempo: row['tempo'] as int?,
    notes: row['notes'] as String?,
    status: SongStatus.values.byName(row['status'] as String? ?? 'idea'),
    links: (row['links'] as List? ?? const []).cast<String>(),
    recordingPath: row['recording_path'] as String?,
    recordingSeconds: row['recording_seconds'] as int?,
  );

  final String id;
  final String bandId;
  final String title;

  /// e.g. "E minor".
  final String? songKey;

  /// Beats per minute.
  final int? tempo;
  final String? notes;
  final SongStatus status;

  /// Full URLs (YouTube, Spotify, chords, lyrics…), at most 5.
  final List<String> links;

  /// A demo or rehearsal take in the private `band-songs` bucket.
  final String? recordingPath;
  final int? recordingSeconds;
}

/// What the song form edits.
typedef SongDraft = ({
  String title,
  String songKey,
  int? tempo,
  String notes,
  SongStatus status,
  List<String> links,
});

/// Ready songs first, then learning, then ideas; by title within each.
List<Song> sortSongs(List<Song> songs) => [...songs]
  ..sort((a, b) {
    final byStatus = b.status.index.compareTo(a.status.index);
    return byStatus != 0
        ? byStatus
        : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
