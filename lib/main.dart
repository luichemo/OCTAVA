import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/theme_setting.dart';
import 'l10n/l10n.dart';
import 'screens/auth_gate.dart';
import 'theme.dart';

// `async` + `await`: work like in TypeScript. Supabase and the saved language
// and theme must be ready before the first screen draws, so main waits.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await appLanguage.load();
  await appTheme.load();
  runApp(const OctavaApp());
}

class OctavaApp extends StatelessWidget {
  const OctavaApp({super.key, this.home = const AuthGate()});

  /// The first screen. Tests pass their own so they don't need Supabase.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when someone picks another language or theme.
    return ListenableBuilder(
      listenable: Listenable.merge([appLanguage, appTheme]),
      builder: (context, _) {
        // Set before the themes are built, since they use heading styles.
        georgianType =
            (appLanguage.value ??
                    resolveLocale(
                      WidgetsBinding.instance.platformDispatcher.locales,
                    ))
                .languageCode ==
            'ka';
        return MaterialApp(
          title: 'OCTAVA',
          debugShowCheckedModeBanner: false,
          theme: octavaTheme(Brightness.light),
          darkTheme: octavaTheme(Brightness.dark),
          themeMode: appTheme.value,
          locale: appLanguage.value,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeListResolutionCallback: (deviceLocales, _) =>
              resolveLocale(deviceLocales),
          // Keeps translations for code without a BuildContext in step.
          builder: (context, child) {
            L10n.current = AppLocalizations.of(context);
            final media = MediaQuery.of(context);
            // Alerts (snack bars) show at the top, where banners appear, and
            // swipe away upwards. Flutter only anchors them at the bottom,
            // so the bottom margin pushes them up to just below the status
            // bar (keeping clear of the keyboard).
            final top =
                ((media.size.height -
                            media.viewInsets.bottom -
                            media.padding.top -
                            96)
                        .clamp(16.0, double.infinity))
                    .toDouble();
            final themed = Theme(
              data: Theme.of(context).copyWith(
                snackBarTheme: Theme.of(context).snackBarTheme.copyWith(
                  behavior: SnackBarBehavior.floating,
                  insetPadding: EdgeInsets.fromLTRB(16, 0, 16, top),
                  dismissDirection: DismissDirection.up,
                ),
              ),
              child: child!,
            );
            if (!georgianType) return themed;
            // Georgian letters read larger than Latin ones at the same size,
            // so all text is 10% smaller (on top of the person's own setting).
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  media.textScaler.scale(16) / 16 * 0.9,
                ),
              ),
              child: themed,
            );
          },
          home: home,
        );
      },
    );
  }
}
