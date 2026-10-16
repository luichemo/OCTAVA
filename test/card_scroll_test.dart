import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/models/profile_link.dart';
import 'package:octava/theme.dart';
import 'package:octava/widgets/musician_card.dart';

void main() {
  final busy = Musician(
    name: 'Ana',
    age: 25,
    instrumentId: 'bass',
    otherInstruments: const [(id: 'guitar', skill: 'pro')],
    area: 'Vake',
    genres: const ['post-punk', 'jazz', 'math-rock', 'shoegaze', 'funk'],
    lookingFor:
        'A band that rehearses twice a week and wants to record an EP '
        'this winter, then play small venues around Tbilisi.',
    links: [
      for (var i = 0; i < 4; i++)
        ProfileLink.fromInput('youtube.com/watch?v=$i')!,
    ],
  );

  Future<void> pump(
    WidgetTester tester,
    double height, {
    Musician? musician,
    GestureDragUpdateCallback? onPan,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OctavaApp(
        home: Scaffold(
          body: Center(
            // Like the swipe screen: the deck pans the whole card.
            child: GestureDetector(
              onPanUpdate: onPan,
              child: SizedBox(
                width: 360,
                height: height,
                child: MusicianCard(
                  musician: musician ?? busy,
                  tone: OctavaColors.aqua,
                  fitsOpenSlot: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('details that don\'t fit scroll inside the card', (tester) async {
    await pump(tester, 420);
    // No overflow error, and the portrait keeps its share of the card.
    expect(tester.takeException(), isNull);
    final looking = find.textContaining('A band that rehearses');
    final card = tester.getRect(find.byType(MusicianCard));
    expect(tester.getRect(looking).top, greaterThan(card.bottom));

    await tester.drag(find.textContaining('Ana'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(looking).bottom, lessThanOrEqualTo(card.bottom));
  });

  testWidgets('a tall card shows everything without scrolling', (tester) async {
    await pump(
      tester,
      780,
      musician: const Musician(name: 'Ana', age: 25, instrumentId: 'bass'),
    );
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(MusicianCard),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scroll.position.maxScrollExtent, 0);
  });

  testWidgets('sideways drags still swipe; up and down drags scroll', (
    tester,
  ) async {
    var panned = Offset.zero;
    await pump(tester, 420, onPan: (d) => panned += d.delta);
    final details = find.textContaining('Ana');

    final g = await tester.startGesture(tester.getCenter(details));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(20, 0));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(panned.dx, greaterThan(100));

    panned = Offset.zero;
    await tester.drag(details, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(panned, Offset.zero);
  });
}
