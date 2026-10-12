import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/theme_setting.dart';
import 'package:octava/main.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

import 'signup_flow_test.dart' show FakeProfileRepository;

void main() {
  testWidgets('choosing Dark in the profile switches the whole app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => appTheme.value = ThemeMode.system);

    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
    await tester.pumpWidget(
      OctavaApp(home: EditProfileScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    BuildContext screen() => tester.element(find.byType(EditProfileScreen));
    expect(Theme.of(screen()).brightness, Brightness.light);

    final dark = find.widgetWithText(SegmentedButton<ThemeMode>, 'Dark');
    await tester.scrollUntilVisible(
      dark,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(appTheme.value, ThemeMode.dark);
    expect(Theme.of(screen()).brightness, Brightness.dark);

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<ThemeMode>),
        matching: find.text('Device'),
      ),
    );
    await tester.pumpAndSettle();
    expect(appTheme.value, ThemeMode.system);
    expect(Theme.of(screen()).brightness, Brightness.light);
  });

  testWidgets('the sun/moon button in the feed switches light and dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => appTheme.value = ThemeMode.system);
    await tester.pumpWidget(const OctavaApp(home: SwipeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(appTheme.value, ThemeMode.dark);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(appTheme.value, ThemeMode.light);
  });
}
