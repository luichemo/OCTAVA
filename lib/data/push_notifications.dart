import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/firebase_config.dart';
import '../l10n/l10n.dart';

/// What a notification's tap should open: `type` is 'chat' (with
/// `match_id`), 'band' (with `band_id`) or 'bands' (the Bands section).
typedef PushData = Map<String, dynamic>;

/// Phone notifications for messages, matches, band activity and rehearsal
/// reminders (sent by the `push` Edge Function).
abstract interface class PushNotifications {
  /// Asks for permission, registers this device for the signed-in person,
  /// and calls [onOpen] when a notification is tapped (also one that opened
  /// the app). Does nothing where push isn't set up.
  Future<void> start({required ValueChanged<PushData> onOpen});

  /// Stops notifications to this device (before signing out).
  Future<void> stop();
}

/// Firebase Cloud Messaging on Android and iOS, once FirebaseConfig has the
/// app's options; a no-op on the web and while unconfigured.
class FirebasePush implements PushNotifications {
  FirebasePush(this._client);
  final SupabaseClient _client;

  String? _token;
  final _subs = <StreamSubscription<dynamic>>[];

  static FirebaseOptions? get _options {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => FirebaseConfig.android,
      TargetPlatform.iOS => FirebaseConfig.ios,
      _ => null,
    };
  }

  static bool get configured => _options != null;

  @override
  Future<void> start({required ValueChanged<PushData> onOpen}) async {
    final options = _options;
    if (options == null) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // The classic registration token, which FCM's HTTP v1 send (the push
      // Edge Function) takes as `message.token`. Version 17 deprecates it
      // for register()/onRegistered, which give a Firebase Installation ID;
      // keep the token until the function is moved to that.
      // ignore: deprecated_member_use
      _token = await messaging.getToken();
      await _register();
      _subs
        ..add(
          // ignore: deprecated_member_use
          messaging.onTokenRefresh.listen((t) {
            _token = t;
            _register();
          }),
        )
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(m.data)),
        );
      // Texts follow the app language: tell the server when it changes.
      appLanguage.addListener(_register);
      final initial = await messaging.getInitialMessage();
      if (initial != null) onOpen(initial.data);
    } catch (e) {
      // Notifications are a nice-to-have; the app works without them.
      debugPrint('Push notifications unavailable: $e');
    }
  }

  Future<void> _register() async {
    final token = _token;
    if (token == null || _client.auth.currentUser == null) return;
    try {
      await _client.rpc(
        'register_push_token',
        params: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          'language': L10n.current.localeName.startsWith('ka') ? 'ka' : 'en',
        },
      );
    } catch (e) {
      debugPrint('Couldn\'t register for notifications: $e');
    }
  }

  @override
  Future<void> stop() async {
    appLanguage.removeListener(_register);
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _client.rpc('unregister_push_token', params: {'token': token});
    } catch (_) {
      // Signing out anyway; the server forgets tokens Firebase rejects.
    }
  }
}
