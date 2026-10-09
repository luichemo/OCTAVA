import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'swipe_screen.dart';

/// Picks the first screen: sign in → set up profile → swipe.
/// Rebuilds whenever Supabase signs someone in or out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, _) {
        final user = client.auth.currentUser;
        if (user == null) {
          return AuthScreen(auth: SupabaseAuthRepository(client));
        }
        // A new key per user resets ProfileGate's state when the account changes.
        return ProfileGate(
          key: ValueKey(user.id),
          repository: SupabaseProfileRepository(client),
        );
      },
    );
  }
}

/// For a signed-in person: finish setting up the profile, or go to swiping.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<ProfileStatus> _status = widget.repository.myStatus();

  // The braces matter: `setState(() => _status = ...)` would return the Future
  // from the callback, which setState rejects, and the screen wouldn't update.
  void _reload() => setState(() {
    _status = widget.repository.myStatus();
  });

  @override
  Widget build(BuildContext context) {
    // FutureBuilder: shows a different widget while the Future is pending,
    // failed, or done, like rendering on a promise's state in React.
    return FutureBuilder<ProfileStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Problem(
            message: snapshot.error.toString(),
            onRetry: _reload,
            onSignOut: widget.repository.signOut,
          );
        }
        return switch (snapshot.data) {
          null => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          ProfileStatus.ready => SwipeScreen(
            onSignOut: widget.repository.signOut,
          ),
          final status => OnboardingScreen(
            repository: widget.repository,
            needsBirthDate: status == ProfileStatus.needsBirthDate,
            onDone: _reload,
          ),
        };
      },
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(message, textAlign: TextAlign.center),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(onPressed: onSignOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
