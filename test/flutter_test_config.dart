import 'dart:async';

import 'package:octava/data/swipe_hint.dart';
import 'package:octava/widgets/octava_logo.dart';

/// Runs before every test file: the feed's spinning logo would keep the
/// screen from ever settling (pumpAndSettle), so it stands still in tests.
/// The first-time swipe hint is off too, so it doesn't move cards under
/// other tests' drags.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  spinningLogoEnabled = false;
  swipeHintEnabled = false;
  await testMain();
}
