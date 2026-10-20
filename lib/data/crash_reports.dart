import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';

/// Sends crashes and uncaught errors to Firebase Crashlytics, on Android
/// (iOS once FirebaseConfig.ios is set). Off on the web and in debug builds,
/// so development errors don't fill the dashboard. No account ids are sent.
Future<void> startCrashReports() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebaseConfig.android);
    }
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    // Errors while building or drawing widgets.
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    // Everything else that nobody caught (async code, plugins).
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    // The app works without crash reports.
    debugPrint('Crash reports unavailable: $e');
  }
}
