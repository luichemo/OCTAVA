import 'dart:async';

import 'package:octava/widgets/octava_logo.dart';

/// Runs before every test file: the feed's spinning logo would keep the
/// screen from ever settling (pumpAndSettle), so it stands still in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  spinningLogoEnabled = false;
  await testMain();
}
