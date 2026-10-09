import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories.dart';
import '../l10n/l10n.dart';

/// AI avatars made by the `generate-avatar` Edge Function (Cloudflare
/// Workers AI), stored in the private `avatars` bucket.
abstract interface class AvatarRepository {
  /// Your current avatar's storage path, or null.
  Future<String?> myAvatarPath();

  /// Makes a new avatar from your profile. Returns its path and how many
  /// more you can make today.
  Future<({String path, int remaining})> generate();

  /// A temporary link for showing an avatar.
  Future<String> imageUrl(String path);
}

class SupabaseAvatarRepository implements AvatarRepository {
  SupabaseAvatarRepository(this._client);
  final SupabaseClient _client;

  // Signed links are reused, so scrolling cards doesn't ask again each time.
  final _urls = <String, Future<String>>{};

  @override
  Future<String?> myAvatarPath() async {
    try {
      final row = await _client
          .from('profiles')
          .select('avatar_path')
          .eq('id', _client.auth.currentUser!.id)
          .single();
      return row['avatar_path'] as String?;
    } catch (_) {
      throw UserFacingException(L10n.current.errAvatarLoad);
    }
  }

  @override
  Future<({String path, int remaining})> generate() async {
    try {
      final response = await _client.functions.invoke('generate-avatar');
      final data = response.data as Map<String, dynamic>;
      return (
        path: data['path'] as String,
        remaining: data['remaining'] as int,
      );
    } on FunctionException catch (e) {
      // The function answers in English; pick the translated message by status.
      final details = e.details;
      final t = L10n.current;
      throw UserFacingException(switch (e.status) {
        429 when details is Map && details['remaining'] == 0 =>
          t.errAvatarDaily,
        429 => t.errAvatarBusy,
        503 => t.errAvatarNotReady,
        _ => t.errAvatarGeneric,
      });
    } catch (_) {
      throw UserFacingException(L10n.current.errAvatarOffline);
    }
  }

  @override
  Future<String> imageUrl(String path) {
    final url = _urls.putIfAbsent(
      path,
      () => _client.storage.from('avatars').createSignedUrl(path, 60 * 60),
    );
    // A failed link isn't kept, so the next attempt asks again.
    url.catchError((Object _) {
      _urls.remove(path);
      return '';
    });
    return url;
  }
}
