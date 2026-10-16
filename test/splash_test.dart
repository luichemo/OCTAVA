import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/main.dart';
import 'package:octava/widgets/splash.dart';

void main() {
  var taps = 0;
  late ValueNotifier<bool> ready;

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) async {
    taps = 0;
    ready = ValueNotifier(false);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: OctavaApp(
          home: SplashGate(
            ready: ready,
            child: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Behind'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Loads the logo (real image decoding needs real time in tests).
  Future<void> loadLogo(WidgetTester tester) => tester.runAsync(
    () => precacheImage(
      SplashLogo.image,
      tester.element(find.byType(SplashGate)),
    ),
  );

  testWidgets('a quick start shows no animation at all', (tester) async {
    await pump(tester);
    // The app is already there underneath, loading.
    expect(find.text('Behind'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    ready.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(SplashLogo), findsNothing);
    await tester.tap(find.text('Behind'));
    expect(taps, 1);
  });

  testWidgets('a slow start plays the logo, which leaves once ready', (
    tester,
  ) async {
    await pump(tester);
    await loadLogo(tester);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(find.byType(SplashLogo), findsOneWidget);
    expect(find.bySemanticsLabel('OCTAVA'), findsOneWidget);

    // Still loading after the animation: the settled logo stays.
    await tester.pump(SplashGate.duration);
    expect(find.byType(SplashLogo), findsOneWidget);

    ready.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(SplashLogo), findsNothing);
    await tester.tap(find.text('Behind'));
    expect(taps, 1);
  });

  testWidgets('becoming ready mid-animation hurries it to the end', (
    tester,
  ) async {
    await pump(tester);
    await loadLogo(tester);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SplashLogo), findsOneWidget);
    ready.value = true;
    // It finishes and fades out well before the rest of the animation
    // (about 1.2 s more) would have played.
    var waited = Duration.zero;
    while (find.byType(SplashLogo).evaluate().isNotEmpty &&
        waited < const Duration(seconds: 2)) {
      await tester.pump(const Duration(milliseconds: 50));
      waited += const Duration(milliseconds: 50);
    }
    expect(waited, lessThan(const Duration(milliseconds: 900)));
    expect(find.byType(SplashLogo), findsNothing);
  });

  testWidgets('with reduce motion the logo shows without moving', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);
    await loadLogo(tester);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(find.byType(SplashLogo), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    ready.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(SplashLogo), findsNothing);
  });
}
