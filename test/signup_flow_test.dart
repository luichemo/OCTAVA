import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:octava/data/push_notifications.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/auth_gate.dart';
import 'package:octava/screens/auth_screen.dart';
import 'package:octava/screens/forgot_password_screen.dart';
import 'package:octava/screens/password_reset_screen.dart';

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
    instrumentId: 'vocals',
    links: saved!.links,
    clipSeconds: null,
  );

  @override
  Future<void> updateProfile(ProfileDraft draft) async => saved = draft;

  @override
  Future<void> signOut() async => signOuts++;

  int deletes = 0;

  /// When set, deleting fails with this message.
  String? deleteError;

  @override
  Future<void> deleteAccount() async {
    if (deleteError != null) throw UserFacingException(deleteError!);
    deletes++;
  }
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

  String? resetEmail;
  String? openedToken;
  String? newPassword;

  /// Reset links that work; any other code is expired.
  final goodTokens = <String>{'good'};

  @override
  Future<void> sendPasswordReset(String email) async {
    if (error != null) throw UserFacingException(error!);
    resetEmail = email;
  }

  @override
  Future<void> openResetLink(String tokenHash) async {
    openedToken = tokenHash;
    if (!goodTokens.contains(tokenHash)) {
      throw const UserFacingException('expired');
    }
  }

  @override
  Future<void> setNewPassword(String password) async {
    newPassword = password;
  }
}

/// Counts start/stop calls, like the app's notification setup.
class FakePush implements PushNotifications {
  int starts = 0;
  int stops = 0;
  ValueChanged<PushData>? onOpen;

  @override
  Future<void> start({required ValueChanged<PushData> onOpen}) async {
    starts++;
    this.onOpen = onOpen;
  }

  @override
  Future<void> stop() async => stops++;
}

void main() {
  test('the email sending limit gets its own message', () {
    expect(
      SupabaseAuthRepository.authMessage(
        const AuthException('', code: 'over_email_send_rate_limit'),
      ),
      'Sign-ups are busy right now. Please try again in an hour.',
    );
  });

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
      await tester.ensureVisible(find.text('Create profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create profile'));
      await tester.pumpAndSettle();

      expect(repo.saved?.displayName, 'Luka');
      expect(repo.saved?.instruments, {'drums': 'intermediate'});
      expect(find.text('Set up your profile'), findsNothing);
      expect(find.text('YOUR BAND'), findsNothing); // no band label
    });

    testWidgets('sign-up asks where you heard about OCTAVA, optionally', (
      tester,
    ) async {
      final repo = FakeProfileRepository(hasBirthDate: true);
      await pump(tester, ProfileGate(repository: repo));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Luka',
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Drums'));
      await tester.pump();
      final friend = find.widgetWithText(ChoiceChip, 'A friend');
      await tester.scrollUntilVisible(
        friend,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(friend);
      await tester.pumpAndSettle();
      expect(
        find.text('Where did you hear about OCTAVA? (optional)'),
        findsOneWidget,
      );
      await tester.tap(friend);
      await tester.pump();
      await tester.ensureVisible(find.text('Create profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create profile'));
      await tester.pumpAndSettle();
      expect(repo.saved?.heardFrom, 'friend');
      expect(repo.saved?.toProfileRow('me')['heard_from'], 'friend');
    });

    test('the profile row only carries heard_from when it was answered', () {
      const draft = ProfileDraft(
        displayName: 'Luka',
        instruments: {'drums': 'pro'},
      );
      expect(draft.toProfileRow('me').containsKey('heard_from'), isFalse);
    });

    testWidgets('asks for a name and an instrument', (tester) async {
      final repo = FakeProfileRepository(hasBirthDate: true);
      await pump(tester, ProfileGate(repository: repo));

      await tester.scrollUntilVisible(
        find.text('Create profile'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Create profile'));
      await tester.pumpAndSettle();
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

      expect(find.text('YOUR BAND'), findsNothing); // no band label
      // Sign out is on the profile screen.
      repo.saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'vocals': 'pro'},
      );
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(repo.signOuts, 1);
    });

    testWidgets('notifications start with the app and stop on sign-out', (
      tester,
    ) async {
      final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
        ..saved = const ProfileDraft(
          displayName: 'Luka',
          instruments: {'vocals': 'pro'},
        );
      final push = FakePush();
      await pump(tester, ProfileGate(repository: repo, push: push));
      expect(push.starts, 1);
      expect(push.onOpen, isNotNull);

      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(push.stops, 1);
      expect(repo.signOuts, 1);
      expect(push.starts, 1); // not started twice
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
      expect(find.text('Create account'), findsOneWidget); // the tab
    });

    testWidgets('shows the 16+ notice only when creating an account', (
      tester,
    ) async {
      await pump(tester, AuthScreen(auth: FakeAuthRepository()));
      expect(find.text('16+ musicians only'), findsNothing);

      await tester.tap(find.text('Create account')); // the tab
      await tester.pumpAndSettle();
      expect(find.text('16+ musicians only'), findsOneWidget);
      // With links to the terms and the privacy policy.
      expect(find.text('Terms of use'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);

      await tester.tap(find.text('Sign in')); // the tab
      await tester.pumpAndSettle();
      expect(find.text('16+ musicians only'), findsNothing);
    });

    testWidgets('checks the email and password before sending', (tester) async {
      final auth = FakeAuthRepository();
      await pump(tester, AuthScreen(auth: auth));
      await tester.tap(find.text('Create account')); // the tab
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
      await tester.tap(find.text('Create account')); // the tab
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

  group('password reset', () {
    testWidgets('Forgot password opens its own page and sends the link', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await pump(tester, AuthScreen(auth: auth));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nika@example.com',
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot your password?'), findsOneWidget);
      // The email typed on sign-in comes along.
      expect(find.text('nika@example.com'), findsOneWidget);

      // A bad address is caught before anything is sent.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nika',
      );
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(auth.resetEmail, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nika@example.com',
      );
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(auth.resetEmail, 'nika@example.com');
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.textContaining('a link to choose a new password'),
        findsOneWidget,
      );

      // Send again waits a minute, then sends to the same address.
      expect(find.text('Send again in 60 s'), findsOneWidget);
      auth.resetEmail = null;
      await tester.tap(find.text('Send again in 60 s'));
      await tester.pump();
      expect(auth.resetEmail, isNull);
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Send again'), findsOneWidget);
      await tester.tap(find.text('Send again'));
      await tester.pumpAndSettle();
      expect(auth.resetEmail, 'nika@example.com');

      // Back to sign in.
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsOneWidget);

      // Not offered while creating an account.
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsNothing);
    });

    testWidgets('Forgot password shows errors from sending', (tester) async {
      final auth = FakeAuthRepository(error: 'Please wait a minute.');
      await pump(tester, ForgotPasswordScreen(auth: auth, email: 'a@b.co'));
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(find.text('Please wait a minute.'), findsOneWidget);
      expect(find.text('Check your email'), findsNothing);
    });

    testWidgets('a good link lets you set a new password', (tester) async {
      final auth = FakeAuthRepository();
      var done = false;
      await pump(
        tester,
        PasswordResetScreen(
          auth: auth,
          tokenHash: 'good',
          onDone: () => done = true,
        ),
      );
      expect(auth.openedToken, 'good');
      expect(find.text('Choose a new password'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        'longenough1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Repeat the password'),
        'different1',
      );
      await tester.tap(find.text('Save password'));
      await tester.pumpAndSettle();
      expect(find.text("The passwords don't match."), findsOneWidget);
      expect(auth.newPassword, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Repeat the password'),
        'longenough1',
      );
      await tester.tap(find.text('Save password'));
      await tester.pumpAndSettle();
      expect(auth.newPassword, 'longenough1');
      expect(find.text('Password changed.'), findsOneWidget);
      expect(done, isTrue);
    });

    testWidgets('sign-in can open with an expired-link message', (
      tester,
    ) async {
      await pump(
        tester,
        AuthScreen(auth: FakeAuthRepository(), initialError: 'Link expired'),
      );
      expect(find.text('Link expired'), findsOneWidget);
    });

    testWidgets('an expired link says so and goes back', (tester) async {
      var done = false;
      await pump(
        tester,
        PasswordResetScreen(
          auth: FakeAuthRepository(),
          tokenHash: 'used',
          onDone: () => done = true,
        ),
      );
      expect(
        find.textContaining('expired or was already used'),
        findsOneWidget,
      );
      await tester.tap(find.text('Back to sign in'));
      expect(done, isTrue);
    });
  });
}
