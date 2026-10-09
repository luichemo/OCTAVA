import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Translations outside widgets (repositories, models), which have no
/// BuildContext. OctavaApp keeps [current] in step with the shown language.
class L10n {
  static AppLocalizations current = lookupAppLocalizations(const Locale('en'));
}

/// `context.t.someText` in widgets.
extension L10nContext on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);
}

/// The language picked in the app: null follows the device (Georgian if the
/// phone or browser is set to Georgian, otherwise English).
class LanguageController extends ValueNotifier<Locale?> {
  LanguageController() : super(null);

  static const _key = 'app_language';

  Future<void> load() async {
    try {
      final code = await SharedPreferencesAsync().getString(_key);
      value = code == null ? null : Locale(code);
    } catch (_) {
      // Can't read the setting: follow the device.
    }
  }

  Future<void> choose(Locale? locale) async {
    value = locale;
    try {
      final prefs = SharedPreferencesAsync();
      locale == null
          ? await prefs.remove(_key)
          : await prefs.setString(_key, locale.languageCode);
    } catch (_) {
      // Not remembered next time; the choice still applies now.
    }
  }
}

/// The app-wide language setting.
final appLanguage = LanguageController();

/// The first of the device's preferred languages that OCTAVA has (English or
/// Georgian), or English.
Locale resolveLocale(List<Locale>? deviceLocales) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'ka') return const Locale('ka');
    if (locale.languageCode == 'en') return const Locale('en');
  }
  return const Locale('en');
}
