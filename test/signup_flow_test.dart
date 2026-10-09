import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/auth_gate.dart';
import 'package:octava/screens/auth_screen.dart';

/// Stands in for Supabase: remembers what was saved, like the real database.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.hasBirthDate = false, this.hasProfile = false});

  bool hasBirthDate;
  bool hasProfile;
  ProfileDraft? saved;
  int signOuts = 0;

  @override
  Future<ProfileStatus> myStatus() async => !hasBirthDate
      ? ProfileStatus.needsBirthDate
      : (hasProfile ? ProfileStatus.ready : ProfileStatus.needsProfile);

  @override
  Future<void> saveBirthDate(DateTime date) async => hasBirthDate = true;

  @override
  Future<void> createProfile(ProfileDraft draft) async {
    saved = draft;
    hasProfile = true;
  }

  @override
  Future<ProfileDraft> loadMyProfile() async => saved!;

  @override
  Future<Musician> loadMyCard() async => Musician(
    id: 'me',
    name: saved!.displayName,
    age: 30,
    instrument: 'Vocals',
    links: saved!.links,
    clipSeconds: null,
  );

  @override
  Future<void> updateProfile(ProfileDraft draft) async => saved = draft;

  @override
  Future<void> signOut() async => signOuts++;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.needsConfirmation = false, this.error});

  final bool needsConfirmation;
  final String? error;
  String? lastEmail;

  @override
  Future<bool> signUp(String email, String password) async {
    if (error != null) throw UserFacingException(error!);
    lastEmail = email;
    return needsConfirmation;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (error != null) throw UserFacingException(error!);
    lastEmail = email;
  }
}

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  group('profile setup', () {
    testWidgets('after creating a profile, the swipe screen opens', (
      tester,
    ) async {
      final repo = FakeProfileRepository(hasBirthDate: true);
      await pump(tester, ProfileGate(repository: repo));
      expect(find.text('Set up your profile'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Luka',
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Drums'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Create profile'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Create profile'));
      await tester.pumpAndSettle();

      expect(repo.saved?.displayName, 'Luka');
      expect(repo.saved?.instruments, {'drums': 'intermediate'});
      expect(find.text('Set up your profile'), findsNothing);
      expect(find.text('Your band'), findsOneWidget);
    });

    testWidgets('asks for a name and an instrument', (tester) async {
      final repo = FakeProfileRepository(hasBirthDate: true);
      await pump(tester, ProfileGate(repository: repo));

      await tester.scrollUntilVisible(
        find.text('Create profile'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Create profile'));
      await tester.pumpAndSettle();

      expect(repo.saved, isNull);
      expect(find.textContaining('Some answers are missing'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Pick at least one instrument'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pick at least one instrument'), findsOneWidget);
    });

    testWidgets('a finished profile goes straight to swiping', (tester) async {
      final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true);
      await pump(tester, ProfileGate(repository: repo));

      expect(find.text('Your band'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      expect(repo.signOuts, 1);
    });

    testWidgets('a new account is asked for a date of birth', (tester) async {
      await pump(tester, ProfileGate(repository: FakeProfileRepository()));
      expect(
        find.widgetWithText(TextFormField, 'Date of birth'),
        findsOneWidget,
      );
    });
  });

  group('welcome screen', () {
    testWidgets('opens on Sign in', (tester) async {
      await pump(tester, AuthScreen(auth: FakeAuthRepository()));
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(find.text('Create a new account'), findsOneWidget);
    });

    testWidgets('checks the email and password before sending', (tester) async {
      final auth = FakeAuthRepository();
      await pump(tester, AuthScreen(auth: auth));
      await tester.tap(find.text('Create a new account'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'short',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(auth.lastEmail, isNull);
    });

    testWidgets('explains email confirmation after sign-up', (tester) async {
      final auth = FakeAuthRepository(needsConfirmation: true);
      await pump(tester, AuthScreen(auth: auth));
      await tester.tap(find.text('Create a new account'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nika@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'longenough1',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(auth.lastEmail, 'nika@example.com');
      expect(find.textContaining('Check your email'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('shows sign-in errors', (tester) async {
      final auth = FakeAuthRepository(
        error: "That email and password don't match an account.",
      );
      await pump(tester, AuthScreen(auth: auth));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nika@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'whatever',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text("That email and password don't match an account."),
        findsOneWidget,
      );
    });
  });
}
