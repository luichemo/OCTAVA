import 'package:firebase_core/firebase_core.dart';

/// Firebase settings for push notifications, from the Firebase console
/// (Project settings → Your apps). These identify the app and are public by
/// design, like the Supabase publishable key; never put the service account
/// (that's a server secret, set only in Supabase) in here.
///
/// While a platform's options are null, push notifications are off there
/// and the app works exactly as before. The web preview has none: it keeps
/// the in-app banners.
abstract final class FirebaseConfig {
  /// Android app `com.octava.app` (from google-services.json: api key,
  /// mobilesdk_app_id, project_number, project_id, storage bucket).
  static const FirebaseOptions? android = null;

  /// iOS app `com.octava.app` (from GoogleService-Info.plist). Also needs an
  /// APNs key in Firebase and the Push Notifications capability in Xcode.
  static const FirebaseOptions? ios = null;
}
