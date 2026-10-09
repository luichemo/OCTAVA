import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/avatar_repository.dart';
import '../data/chat_repository.dart';
import '../data/clip_repository.dart';
import '../data/deck.dart';
import '../data/location_repository.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../models/musician.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';
import 'matches_screen.dart';
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
          deck: SupabaseDeck(client),
          chat: SupabaseChatRepository(client),
          safety: SupabaseSafetyRepository(client),
          clips: SupabaseClipRepository(client),
          avatars: SupabaseAvatarRepository(client),
          location: DeviceLocationRepository(client),
          filterStore: PrefsFilterStore(user.id),
        );
      },
    );
  }
}

/// For a signed-in person: finish setting up the profile, or go to swiping.
class ProfileGate extends StatefulWidget {
  const ProfileGate({
    super.key,
    required this.repository,
    this.deck = const SampleDeck(),
    this.chat,
    this.safety,
    this.clips,
    this.avatars,
    this.location,
    this.filterStore,
  });

  final ProfileRepository repository;

  /// People to swipe on once the profile is ready.
  final DeckSource deck;

  /// Matches and messages. Without it the swipe screen has no Matches button.
  final ChatRepository? chat;

  /// Block and report, on cards and in chats.
  final SafetyRepository? safety;

  /// Audio clips: playing on cards and managing your own.
  final ClipRepository? clips;

  /// AI avatars: on cards and made from your profile.
  final AvatarRepository? avatars;

  /// Sharing your approximate location, for distances.
  final LocationRepository? location;

  /// Remembers swipe filters on this device.
  final FilterStore? filterStore;

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<ProfileStatus> _status = widget.repository.myStatus();

  // One player for the whole signed-in session, so only one clip plays at a time.
  late final ClipPlayer? _player = widget.clips == null
      ? null
      : JustAudioClipPlayer(widget.clips!.playbackUrl);

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _openProfile() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EditProfileScreen(
        repository: widget.repository,
        clips: widget.clips,
        player: _player,
        avatars: widget.avatars,
        location: widget.location,
      ),
    ),
  );

  // The braces matter: `setState(() => _status = ...)` would return the Future
  // from the callback, which setState rejects, and the screen wouldn't update.
  void _reload() => setState(() {
    _status = widget.repository.myStatus();
  });

  void _openMatches() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MatchesScreen(repository: widget.chat!, safety: widget.safety),
      ),
    );
  }

  void _openChat(String matchId, Musician musician) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          repository: widget.chat!,
          matchId: matchId,
          otherUserId: musician.id!,
          safety: widget.safety,
          name: musician.name,
          instrument: musician.instrument,
        ),
      ),
    );
  }

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
            source: widget.deck,
            onSignOut: widget.repository.signOut,
            onOpenMatches: widget.chat == null ? null : _openMatches,
            onOpenChat: widget.chat == null ? null : _openChat,
            safety: widget.safety,
            player: _player,
            onOpenProfile: _openProfile,
            avatars: widget.avatars,
            location: widget.location,
            filterStore: widget.filterStore,
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
              FilledButton(onPressed: onRetry, child: Text(context.t.tryAgain)),
              TextButton(onPressed: onSignOut, child: Text(context.t.signOut)),
            ],
          ),
        ),
      ),
    );
  }
}
