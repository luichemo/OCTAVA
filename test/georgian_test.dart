import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/location_repository.dart';
import 'package:octava/l10n/l10n.dart';
import 'package:octava/main.dart';
import 'package:octava/models/deck_filters.dart';
import 'package:octava/screens/auth_screen.dart';
import 'package:octava/screens/filters_screen.dart';
import 'package:octava/screens/swipe_screen.dart';

import 'filters_test.dart' show FakeLocation;
import 'signup_flow_test.dart' show FakeAuthRepository;

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Locale? locale = const Locale('ka'),
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    appLanguage.value = locale;
    addTearDown(() => appLanguage.value = null);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  testWidgets('the swipe screen in Georgian', (tester) async {
    await pump(
      tester,
      SwipeScreen(
        location: FakeLocation(),
        filterStore: MemoryFilterStore(),
        onOpenProfile: () async {},
        onOpenMatches: () {},
        onSignOut: () {},
      ),
    );

    expect(find.text('შენი ბენდი'), findsOneWidget); // Your band
    expect(find.text('დასარტყამები'), findsWidgets); // Drums (lineup + card)
    expect(find.text('თავისუფალი'), findsNWidgets(4)); // Open
    expect(find.text('ყველგან'), findsOneWidget); // Everywhere
    expect(find.text('გაზიარება'), findsOneWidget); // Share (location)
    expect(find.text('პროფილი'), findsOneWidget); // Profile
    expect(find.text('შენს ბენდს სჭირდება: დასარტყამები'), findsOneWidget);
    expect(find.text('Your band'), findsNothing);
  });

  testWidgets('filters in Georgian', (tester) async {
    await pump(
      tester,
      const FiltersScreen(initial: DeckFilters(), hasLocation: true),
    );
    expect(find.text('ფილტრები'), findsOneWidget);
    expect(find.text('25 კმ'), findsOneWidget);
    expect(find.text('ნებისმიერ ადგილას'), findsOneWidget);
    expect(find.text('ბასი'), findsOneWidget);
  });

  testWidgets('the sign-in screen switches language with one tap', (
    tester,
  ) async {
    await pump(
      tester,
      AuthScreen(auth: FakeAuthRepository()),
      locale: const Locale('en'),
    );
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('ქართული'));
    await tester.pumpAndSettle();

    expect(find.text('შესვლა'), findsOneWidget); // Sign in
    expect(find.text('English'), findsOneWidget);
    expect(appLanguage.value, const Locale('ka'));
  });

  test('the device language decides when nothing is chosen', () {
    expect(resolveLocale(const [Locale('ka', 'GE')]), const Locale('ka'));
    expect(
      resolveLocale(const [Locale('ru'), Locale('ka')]),
      const Locale('ka'),
    );
    expect(
      resolveLocale(const [Locale('en', 'US'), Locale('ka')]),
      const Locale('en'),
    );
    expect(resolveLocale(const [Locale('de')]), const Locale('en'));
  });

  test('every Georgian text exists', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ka = lookupAppLocalizations(const Locale('ka'));
    expect(
      ka.deckWithFilters(ka.deckWithin(25), 2),
      '25 კმ-ის რადიუსში, 2 ფილტრი',
    );
    expect(en.deckWithFilters(en.deckWithin(25), 1), 'Within 25 km, 1 filter');
    expect(ka.kmAway('3'), '3 კმ-ში');
  });
}
