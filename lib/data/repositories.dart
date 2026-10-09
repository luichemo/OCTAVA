import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_draft.dart';

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
