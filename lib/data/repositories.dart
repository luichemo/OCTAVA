import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/musician.dart';
import '../models/profile_draft.dart';
import 'profile_options.dart';

/// Where the signed-in user is in setting up their account.
enum ProfileStatus { needsBirthDate, needsProfile, ready }

/// A problem to show the person, already worded for them.
class UserFacingException implements Exception {
  const UserFacingException(this.message);
  final String message;
  @override
  String toString() => message;
}

const _offline = "Couldn't reach OCTAVA. Check your connection and try again.";

// `abstract interface class` = a TypeScript interface: screens depend on these,
// so tests can pass in fakes instead of talking to Supabase.

abstract interface class AuthRepository {
  /// Returns true when the account needs email confirmation before signing in.
  Future<bool> signUp(String email, String password);
  Future<void> signIn(String email, String password);
}

abstract interface class ProfileRepository {
  Future<ProfileStatus> myStatus();
  Future<void> saveBirthDate(DateTime date);
  Future<void> createProfile(ProfileDraft draft);

  /// Your current profile, for editing.
  Future<ProfileDraft> loadMyProfile();

  /// Your own swipe card, as others see it (saved profile, first clip).
  Future<Musician> loadMyCard();

  /// Saves an edited profile, including instruments and links.
  Future<void> updateProfile(ProfileDraft draft);

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<bool> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      // Supabase hides whether an email is taken: a "fake" user comes back
      // with no identities. Tell the person to sign in instead.
      if (response.user?.identities?.isEmpty ?? false) {
        throw const UserFacingException(
          'There is already an account with this email. Sign in instead.',
        );
      }
      return response.session == null;
    } on AuthException catch (e) {
      throw UserFacingException(_authMessage(e));
    } on UserFacingException {
      rethrow;
    } catch (_) {
      throw const UserFacingException(_offline);
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw UserFacingException(_authMessage(e));
    } catch (_) {
      throw const UserFacingException(_offline);
    }
  }

  static String _authMessage(AuthException e) => switch (e.code) {
    'invalid_credentials' => "That email and password don't match an account.",
    'email_not_confirmed' =>
      'Confirm your email first: open the link we sent you, then sign in.',
    'user_already_exists' || 'email_exists' =>
      'There is already an account with this email. Sign in instead.',
    'weak_password' => 'Choose a stronger password: at least 8 characters, mixing letters and numbers.',
    'email_address_invalid' => 'Enter a valid email address.',
    'over_email_send_rate_limit' || 'over_request_rate_limit' =>
      'Too many attempts. Wait a minute and try again.',
    _ => e.message,
  };
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<ProfileStatus> myStatus() async {
    try {
      final private = await _client
          .from('profile_private')
          .select('id')
          .eq('id', _uid)
          .maybeSingle();
      if (private == null) return ProfileStatus.needsBirthDate;
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('id', _uid)
          .maybeSingle();
      return profile == null ? ProfileStatus.needsProfile : ProfileStatus.ready;
    } catch (_) {
      throw const UserFacingException(_offline);
    }
  }

  @override
  Future<void> saveBirthDate(DateTime date) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _write(
      () => _client.from('profile_private').insert({
        'id': _uid,
        'birth_date': day,
      }),
    );
  }

  @override
  Future<void> createProfile(ProfileDraft draft) async {
    await _write(
      () => _client.from('profiles').insert(draft.toProfileRow(_uid)),
    );
    final rows = draft.toInstrumentRows(_uid);
    if (rows.isNotEmpty) {
      await _write(() => _client.from('profile_instruments').insert(rows));
    }
  }

  @override
  Future<ProfileDraft> loadMyProfile() async {
    try {
      final profile = await _client
          .from('profiles')
          .select(
            'display_name, area, looking_for, genres, goals, rehearsal_frequency, '
            'has_own_gear, has_car, has_rehearsal_space, has_home_studio',
          )
          .eq('id', _uid)
          .single();
      final instruments = await _client
          .from('profile_instruments')
          .select('instrument_id, skill, is_primary')
          .eq('profile_id', _uid);
      final links = await _client
          .from('profile_links')
          .select('kind, url')
          .eq('profile_id', _uid);
      return ProfileDraft.fromRows(
        profile: profile,
        instruments: instruments,
        links: links,
      );
    } catch (_) {
      throw const UserFacingException(_offline);
    }
  }

  @override
  Future<Musician> loadMyCard() async {
    final draft = await loadMyProfile();
    try {
      final private = await _client
          .from('profile_private')
          .select('birth_date')
          .eq('id', _uid)
          .single();
      final born = DateTime.parse(private['birth_date'] as String);
      final now = DateTime.now();
      final hadBirthday =
          now.month > born.month ||
          (now.month == born.month && now.day >= born.day);
      final avatar = await _client
          .from('profiles')
          .select('avatar_path')
          .eq('id', _uid)
          .single();
      final clip = await _client
          .from('audio_clips')
          .select('storage_path, duration_seconds')
          .eq('profile_id', _uid)
          .order('created_at')
          .limit(1)
          .maybeSingle();
      return Musician(
        id: _uid,
        name: draft.displayName,
        age: now.year - born.year - (hadBirthday ? 0 : 1),
        instrument:
            instrumentLabels[draft.instruments.keys.firstOrNull] ?? 'Musician',
        area: draft.area.isEmpty ? null : draft.area,
        genres: draft.genres,
        lookingFor: draft.lookingFor.isEmpty ? null : draft.lookingFor,
        links: draft.links,
        clipSeconds: clip?['duration_seconds'] as int?,
        clipPath: clip?['storage_path'] as String?,
        avatarPath: avatar['avatar_path'] as String?,
      );
    } catch (_) {
      throw const UserFacingException(_offline);
    }
  }

  @override
  Future<void> updateProfile(ProfileDraft draft) async {
    // The id can't change (and clients aren't allowed to update it).
    final row = draft.toProfileRow(_uid)..remove('id');
    await _write(() => _client.from('profiles').update(row).eq('id', _uid));
    // Instruments and links are replaced as a whole.
    await _write(
      () => _client.from('profile_instruments').delete().eq('profile_id', _uid),
    );
    final instruments = draft.toInstrumentRows(_uid);
    if (instruments.isNotEmpty) {
      await _write(
        () => _client.from('profile_instruments').insert(instruments),
      );
    }
    await _write(
      () => _client.from('profile_links').delete().eq('profile_id', _uid),
    );
    final links = draft.toLinkRows(_uid);
    if (links.isNotEmpty) {
      await _write(() => _client.from('profile_links').insert(links));
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  /// Runs a database write, turning errors into messages for the person.
  /// Messages raised by our own database rules (like the 16+ check) are
  /// already worded for people, so they pass through.
  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on PostgrestException catch (e) {
      final ownRule =
          (e.code == 'P0001' || e.code == '23514') &&
          !e.message.startsWith('new row');
      if (ownRule) throw UserFacingException(e.message);
      throw const UserFacingException(
        "Couldn't save your profile. Try again in a moment.",
      );
    } catch (_) {
      throw const UserFacingException(_offline);
    }
  }
}
