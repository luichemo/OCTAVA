import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/voice_recorder.dart';
import 'package:octava/main.dart';
import 'package:octava/widgets/record_sheet.dart';

import 'profile_edit_test.dart' show FakeClipRepository;

/// A microphone that "records" a fixed-length take.
class FakeRecorder implements VoiceRecorder {
  FakeRecorder({this.allowed = true, this.seconds = 5});

  final bool allowed;
  final int seconds;
  bool started = false;
  bool cancelled = false;

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<void> start() async => started = true;

  int stops = 0;

  @override
  Future<Recording?> stop() async {
    stops++;
    return (
      bytes: Uint8List(100),
      fileName: 'Recording.wav',
      seconds: seconds,
      path: 'blob:take',
    );
  }

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Stream<double> levels() => Stream.value(0.5);

  @override
  final ValueNotifier<bool> playingBack = ValueNotifier(false);
  final played = <String>[];

  @override
  Future<void> togglePlayback(Recording take) async {
    if (playingBack.value) return stopPlayback();
    played.add(take.path);
    playingBack.value = true;
  }

  @override
  Future<void> stopPlayback() async => playingBack.value = false;

  @override
  Future<void> dispose() async {}
}

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required FakeClipRepository clips,
    required FakeRecorder recorder,
  }) async {
    await tester.pumpWidget(
      OctavaApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRecordSheet(
                context,
                clips: clips,
                recorder: () => recorder,
                pickFile: () async => ('Song.mp3', Uint8List(10)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The recording timer ticks every second, so pump instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('starts recording at once, then adds the take to the profile', (
    tester,
  ) async {
    final clips = FakeClipRepository();
    final recorder = FakeRecorder(seconds: 5);
    await openSheet(tester, clips: clips, recorder: recorder);

    expect(recorder.started, isTrue);
    expect(find.text('Recording'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    // Stopping takes a few async steps; let them finish.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Recorded 0:05'), findsOneWidget);

    await tester.tap(find.text('Add to profile'));
    await tester.pumpAndSettle();

    expect(clips.list.single.seconds, 5); // the known length, not measured
    expect(find.text('Clip added to your profile.'), findsOneWidget);
    expect(find.text('New clip'), findsNothing); // sheet closed
  });

  testWidgets('a take can be listened to before adding it', (tester) async {
    final recorder = FakeRecorder(seconds: 7);
    await openSheet(tester, clips: FakeClipRepository(), recorder: recorder);

    await tester.tap(find.text('Stop'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('Listen back'));
    await tester.pump();
    expect(recorder.played, ['blob:take']);
    expect(find.text('Stop listening'), findsOneWidget);

    await tester.tap(find.text('Stop listening'));
    await tester.pump();
    expect(find.text('Listen back'), findsOneWidget);

    // Adding stops playback first.
    await tester.tap(find.text('Listen back'));
    await tester.pump();
    await tester.tap(find.text('Add to profile'));
    await tester.pumpAndSettle();
    expect(recorder.playingBack.value, isFalse);
  });

  testWidgets('explains a refused microphone', (tester) async {
    await openSheet(
      tester,
      clips: FakeClipRepository(),
      recorder: FakeRecorder(allowed: false),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("can't use your microphone"), findsOneWidget);
    expect(find.text('New clip'), findsNothing);
  });

  testWidgets('can upload a file instead', (tester) async {
    final clips = FakeClipRepository();
    final recorder = FakeRecorder();
    await openSheet(tester, clips: clips, recorder: recorder);

    await tester.tap(find.text('Upload a file instead'));
    await tester.pumpAndSettle();

    expect(recorder.cancelled, isTrue);
    expect(clips.list.single.title, 'Song.mp3');
    expect(find.text('Clip added to your profile.'), findsOneWidget);
  });

  testWidgets('a take under a second is refused and recording restarts', (
    tester,
  ) async {
    final recorder = FakeRecorder(seconds: 0);
    await openSheet(tester, clips: FakeClipRepository(), recorder: recorder);

    await tester.tap(find.text('Stop'));
    // Stopping takes a few async steps; let them finish.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('too short'), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);

    // Close the sheet so its timer stops.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });
}
