import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark, or following the device (`ThemeMode.system`), remembered on
/// this device. Works like the language setting (`appLanguage`).
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  static const _key = 'app_theme';

  Future<void> load() async {
    try {
      final saved = await SharedPreferencesAsync().getString(_key);
      // `values.byName` turns 'dark' back into ThemeMode.dark.
      value = saved == null ? ThemeMode.system : ThemeMode.values.byName(saved);
    } catch (_) {
      // Can't read the setting (or it's unknown): follow the device.
    }
  }

  Future<void> choose(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = SharedPreferencesAsync();
      mode == ThemeMode.system
          ? await prefs.remove(_key)
          : await prefs.setString(_key, mode.name);
    } catch (_) {
      // Not remembered next time; the choice still applies now.
    }
  }
}

/// The app-wide theme setting.
final appTheme = ThemeController();
