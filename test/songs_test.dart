import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/song_repository.dart';
import 'package:octava/main.dart';
import 'package:octava/models/song.dart';
import 'package:octava/widgets/songs_section.dart';

import 'profile_edit_test.dart' show FakeClipPlayer;

/// Songs in memory.
class FakeSongRepository implements SongRepository {
  FakeSongRepository([List<Song>? songs]) : songs = [...?songs];

  final List<Song> songs;
  final _changes = StreamController<void>.broadcast();

  Song _with(
    Song s, {
    String? title,
    String? songKey,
    int? tempo,
    String? notes,
    SongStatus? status,
    List<String>? links,
    String? recordingPath,
    int? recordingSeconds,
    bool clearRecording = false,
  }) => Song(
    id: s.id,
    bandId: s.bandId,
    title: title ?? s.title,
    songKey: songKey ?? s.songKey,
    tempo: tempo ?? s.tempo,
    notes: notes ?? s.notes,
    status: status ?? s.status,
    links: links ?? s.links,
    recordingPath: clearRecording ? null : recordingPath ?? s.recordingPath,
    recordingSeconds: clearRecording
        ? null
        : recordingSeconds ?? s.recordingSeconds,
  );

  Song _put(Song s) {
    songs[songs.indexWhere((x) => x.id == s.id)] = s;
    _changes.add(null);
    return s;
  }

  @override
  Future<List<Song>> list(String bandId) async => sortSongs([
    for (final s in songs)
      if (s.bandId == bandId) s,
  ]);

  @override
  Future<Song> add(String bandId, String title) async {
    final s = Song(id: 's${songs.length + 1}', bandId: bandId, title: title);
    songs.add(s);
    _changes.add(null);
    return s;
  }

  @override
  Future<Song> update(String songId, SongDraft d) async => _put(
    _with(
      songs.firstWhere((s) => s.id == songId),
      title: d.title.trim(),
      songKey: d.songKey.trim(),
      tempo: d.tempo,
      notes: d.notes.trim(),
      status: d.status,
      links: d.links,
    ),
  );

  @override
  Future<void> delete(Song song) async {
    songs.removeWhere((s) => s.id == song.id);
    _changes.add(null);
  }

  @override
  Future<Song> uploadRecording(
    Song song, {
    required Uint8List bytes,
    required String fileName,
    int? knownSeconds,
  }) async => _put(
    _with(
      song,
      recordingPath: '${song.bandId}/$fileName',
      recordingSeconds: knownSeconds ?? 180,
    ),
  );

  @override
  Future<Song> removeRecording(Song song) async =>
      _put(_with(song, clearRecording: true));

  @override
  Future<String> recordingUrl(String path) async =>
      'https://example.invalid/$path';

  @override
  Stream<void> changes() => _changes.stream;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeSongRepository repo, {
    FakeClipPlayer? player,
  }) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OctavaApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SongsSection(repository: repo, bandId: 'b1', player: player),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('ready songs come first, then learning, then ideas', () {
    final sorted = sortSongs(const [
      Song(id: '1', bandId: 'b', title: 'b idea'),
      Song(id: '2', bandId: 'b', title: 'Zed', status: SongStatus.ready),
      Song(id: '3', bandId: 'b', title: 'Alpha', status: SongStatus.ready),
      Song(id: '4', bandId: 'b', title: 'mid', status: SongStatus.learning),
    ]);
    expect(
      [for (final s in sorted) s.title],
      ['Alpha', 'Zed', 'mid', 'b idea'],
    );
  });

  testWidgets('add a song, fill it in, and see it in the list', (tester) async {
    final repo = FakeSongRepository();
    await pump(tester, repo);
    expect(find.textContaining('No songs yet'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Night Drive');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    // The song page opens.
    expect(find.text('Song'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Key'), 'E minor');
    await tester.enterText(
      find.widgetWithText(TextField, 'Tempo (BPM)'),
      '120',
    );
    await tester.tap(find.text('Learning'));
    await tester.pump();
    final link = find.widgetWithText(
      TextField,
      'YouTube, Spotify, chords or lyrics link',
    );
    await tester.ensureVisible(link);
    await tester.enterText(link, 'youtu.be/abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final song = repo.songs.single;
    expect(song.songKey, 'E minor');
    expect(song.tempo, 120);
    expect(song.status, SongStatus.learning);
    expect(song.links, ['https://youtu.be/abc']);
    // Back on the band page: the list shows it.
    expect(find.text('Night Drive'), findsOneWidget);
    expect(find.text('E minor · 120 BPM'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
  });

  testWidgets('a song with a recording plays from the list', (tester) async {
    final repo = FakeSongRepository(const [
      Song(
        id: 's1',
        bandId: 'b1',
        title: 'Demo',
        recordingPath: 'b1/take.m4a',
        recordingSeconds: 200,
      ),
    ]);
    final player = FakeClipPlayer();
    await pump(tester, repo, player: player);
    await tester.tap(find.byTooltip('Play the recording'));
    await tester.pump();
    expect(player.toggled, ['song:b1/take.m4a']);
  });

  testWidgets('remove a recording, then delete the song', (tester) async {
    final repo = FakeSongRepository(const [
      Song(
        id: 's1',
        bandId: 'b1',
        title: 'Demo',
        recordingPath: 'b1/take.m4a',
        recordingSeconds: 200,
      ),
    ]);
    await pump(tester, repo);
    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    expect(find.text('3:20'), findsOneWidget);

    final remove = find.byTooltip('Remove the recording');
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text('No recording yet'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete song'));
    await tester.pumpAndSettle();
    expect(find.text('Delete “Demo”?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete song'));
    await tester.pumpAndSettle();
    expect(repo.songs, isEmpty);
    expect(find.textContaining('No songs yet'), findsOneWidget);
  });
}
