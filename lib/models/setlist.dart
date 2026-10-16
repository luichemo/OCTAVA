import 'song.dart';

/// A named, ordered list of the band's songs (for a gig or a rehearsal).
class Setlist {
  const Setlist({
    required this.id,
    required this.bandId,
    required this.name,
    this.songIds = const [],
  });

  final String id;
  final String bandId;
  final String name;

  /// The songs in playing order.
  final List<String> songIds;

  Setlist copyWith({String? name, List<String>? songIds}) => Setlist(
    id: id,
    bandId: bandId,
    name: name ?? this.name,
    songIds: songIds ?? this.songIds,
  );
}

/// The setlist's songs in order, skipping any that were deleted.
List<Song> setlistSongs(Setlist setlist, List<Song> songs) {
  final byId = {for (final s in songs) s.id: s};
  return [for (final id in setlist.songIds) ?byId[id]];
}

/// The length of [songs] from their recordings, and how many have none.
({int seconds, int unknown}) setlistLength(List<Song> songs) => (
  seconds: songs.fold(0, (sum, s) => sum + (s.recordingSeconds ?? 0)),
  unknown: songs.where((s) => s.recordingSeconds == null).length,
);
