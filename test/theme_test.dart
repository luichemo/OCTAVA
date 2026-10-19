import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/theme_setting.dart';
import 'package:octava/main.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

import 'profile_helpers.dart';
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

    expect(
      Theme.of(tester.element(find.byType(EditProfileScreen))).brightness,
      Brightness.light,
    );

    await openSection(tester, 'Theme');
    BuildContext screen() =>
        tester.element(find.byType(SegmentedButton<ThemeMode>));
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

  testWidgets('each profile row opens its section, and shows its value', (
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

    // The settings list shows the current theme; the picker isn't here.
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    expect(find.text('Device'), findsNWidgets(2)); // language and theme

    await openSection(tester, 'Theme');
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    expect(find.text('Light'), findsOneWidget);
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
