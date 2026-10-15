import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/avatar_repository.dart';
import '../data/band_repository.dart';
import '../data/bands_repository.dart';
import '../data/chat_repository.dart';
import '../data/clip_repository.dart';
import '../data/deck.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/location_repository.dart';
import '../data/repositories.dart';
import '../widgets/record_sheet.dart';
import '../data/safety_repository.dart';
import '../models/chat.dart';
import '../models/musician.dart';
import '../widgets/live_banner.dart';
import 'auth_screen.dart';
import 'band_chat_screen.dart';
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
          bandNeeds: SupabaseBandNeeds(client),
          bands: SupabaseBandsRepository(client),
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
    this.bandNeeds,
    this.bands,
  });

  final ProfileRepository repository;

  /// Bands you're in and invites. Shown in Matches (needs [chat] too).
  final BandsRepository? bands;

  /// The roles your band needs (the "Your band" row).
  final BandNeedsRepository? bandNeeds;

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
  // Band clips (bandClipKey) come from the band-clips bucket.
  late final ClipPlayer? _player = widget.clips == null
      ? null
      : JustAudioClipPlayer((key) {
          final bandPath = bandClipPath(key);
          return bandPath != null && widget.bands != null
              ? widget.bands!.clipUrl(bandPath)
              : widget.clips!.playbackUrl(key);
        });

  // Live matches for the whole session: badges, banners, the Matches list.
  late final LiveUpdates? _live = widget.chat == null
      ? null
      : (LiveUpdates(widget.chat!)..start());

  // Bands and invites for the whole session: the Bands section and badge.
  late final LiveBands? _bands = widget.bands == null || widget.chat == null
      ? null
      : (LiveBands(widget.bands!)..start());

  @override
  void dispose() {
    _player?.dispose();
    _live?.dispose();
    _bands?.dispose();
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
        bandNeeds: widget.bandNeeds,
        onSignOut: widget.repository.signOut,
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
        builder: (_) => MatchesScreen(
          repository: widget.chat!,
          live: _live,
          safety: widget.safety,
          avatars: widget.avatars,
          bands: _bands,
          player: _player,
        ),
      ),
    );
  }

  void _openChat(String matchId, Musician musician) => _pushChat(
    matchId: matchId,
    otherUserId: musician.id!,
    name: musician.name,
    instrument: musician.instrument,
  );

  /// From a band message banner.
  void _openBandChat(String bandId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BandChatScreen(
          bands: _bands!,
          bandId: bandId,
          matches: _live,
          avatars: widget.avatars,
          safety: widget.safety,
          player: _player,
        ),
      ),
    );
  }

  /// From a banner.
  void _openChatFor(MatchSummary match) => _pushChat(
    matchId: match.matchId,
    otherUserId: match.otherUserId,
    name: match.name,
    instrument: match.instrument,
  );

  void _pushChat({
    required String matchId,
    required String otherUserId,
    required String name,
    required String instrument,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          repository: widget.chat!,
          live: _live,
          matchId: matchId,
          otherUserId: otherUserId,
          safety: widget.safety,
          name: name,
          instrument: instrument,
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
          ProfileStatus.ready => LiveBannerListener(
            live: _live,
            avatars: widget.avatars,
            onOpen: _openChatFor,
            bands: _bands,
            onOpenBand: _openBandChat,
            child: SwipeScreen(
              source: widget.deck,
              onRecord: widget.clips == null
                  ? null
                  : () => showRecordSheet(context, clips: widget.clips!),
              onOpenMatches: widget.chat == null ? null : _openMatches,
              onOpenChat: widget.chat == null ? null : _openChat,
              safety: widget.safety,
              player: _player,
              onOpenProfile: _openProfile,
              avatars: widget.avatars,
              location: widget.location,
              filterStore: widget.filterStore,
              bandNeeds: widget.bandNeeds,
              live: _live,
              bands: _bands,
            ),
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
