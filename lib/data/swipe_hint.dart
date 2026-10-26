import 'package:shared_preferences/shared_preferences.dart';

/// Whether the first-time hints (the swipe hint and the band row's tap hint)
/// can play. Switched off for all tests (test/flutter_test_config.dart), like
/// the spinning logo; the hints' own tests switch it back on.
bool swipeHintEnabled = true;

/// Remembers that a first-time hint has been shown, so it plays only once.
abstract class HintStore {
  Future<bool> seen();
  Future<void> markSeen();
}

/// Once per account on each device, saved with shared_preferences, so a
/// new account (even one made again after deleting) sees it once too.
class PrefsHintStore implements HintStore {
  PrefsHintStore(this._userId, {this.name = 'swipe_hint'});
  final String _userId;

  /// Which hint: `swipe_hint` (the feed's swipe hint) or `lineup_hint` (the
  /// band row's tap hint).
  final String name;

  String get _key => '${name}_seen_$_userId';

  @override
  Future<bool> seen() async {
    try {
      return await SharedPreferencesAsync().getBool(_key) ?? false;
    } catch (_) {
      // Can't read it: don't risk replaying the hint every time.
      return true;
    }
  }

  @override
  Future<void> markSeen() async {
    try {
      await SharedPreferencesAsync().setBool(_key, true);
    } catch (_) {
      // Not remembered; at worst the hint plays once more.
    }
  }
}

/// For tests.
class MemoryHintStore implements HintStore {
  MemoryHintStore({this.wasSeen = false});
  bool wasSeen;

  @override
  Future<bool> seen() async => wasSeen;

  @override
  Future<void> markSeen() async => wasSeen = true;
}
