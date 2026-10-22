import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'signup_flow_test.dart' show FakeProfileRepository;

import 'package:octava/main.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/auth_gate.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/screens/swipe_screen.dart';
import 'package:octava/widgets/responsive.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
    await tester.pumpWidget(OctavaApp(home: ProfileGate(repository: repo)));
    await tester.pumpAndSettle();
  }

  /// Where a widget sits on screen, after the column's scaling.
  Rect onScreen(WidgetTester tester, Finder finder) =>
      Rect.fromPoints(tester.getTopLeft(finder), tester.getBottomRight(finder));

  test('the layout grows with the screen, by height, within limits', () {
    expect(columnScale(const Size(390, 844)), 1); // phones: never smaller
    expect(columnScale(const Size(1440, 900)), closeTo(900 / 760, 0.001));
    expect(columnScale(const Size(820, 1180)), closeTo(1180 / 760, 0.001));
    expect(columnScale(const Size(3840, 2160)), maxColumnScale);
    // A wide but short window keeps a margin at the sides.
    expect(
      columnScale(const Size(600, 1200)),
      closeTo(600 * 0.92 / 480, 0.001),
    );
  });

  testWidgets('a laptop shows the phone layout, centred and bigger', (
    tester,
  ) async {
    await pumpHome(tester, const Size(1440, 900));
    final scale = columnScale(const Size(1440, 900));

    // Laid out as on a phone...
    expect(tester.getSize(find.byType(SwipeScreen)).width, phoneColumnWidth);
    // ...and drawn bigger, in the middle.
    final feed = onScreen(tester, find.byType(SwipeScreen));
    expect(feed.width, closeTo(phoneColumnWidth * scale, 0.5));
    expect(feed.center.dx, closeTo(720, 0.5));
    expect(feed.height, closeTo(900, 0.5));

    // Pages open inside the column too.
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    final profile = onScreen(tester, find.byType(EditProfileScreen));
    expect(profile.width, closeTo(phoneColumnWidth * scale, 0.5));
    expect(profile.center.dx, closeTo(720, 0.5));
  });

  testWidgets('an iPad in portrait gets a big phone layout', (tester) async {
    await pumpHome(tester, const Size(820, 1180));

    final feed = onScreen(tester, find.byType(SwipeScreen));
    expect(feed.width, greaterThan(700));
    expect(feed.center.dx, closeTo(410, 0.5));
  });

  testWidgets('a phone is unchanged', (tester) async {
    await pumpHome(tester, const Size(390, 844));

    expect(onScreen(tester, find.byType(SwipeScreen)).width, 390);
  });
}
