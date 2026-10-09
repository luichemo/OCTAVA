import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'l10n/l10n.dart';
import 'screens/auth_gate.dart';
import 'theme.dart';

// `async` + `await`: work like in TypeScript. Supabase and the saved language
// must be ready before the first screen draws, so main waits for them.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await appLanguage.load();
  runApp(const OctavaApp());
}

class OctavaApp extends StatelessWidget {
  const OctavaApp({super.key, this.home = const AuthGate()});

  /// The first screen. Tests pass their own so they don't need Supabase.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when someone picks another language.
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLanguage,
      builder: (context, chosen, _) => MaterialApp(
        title: 'OCTAVA',
        debugShowCheckedModeBanner: false,
        theme: octavaTheme(Brightness.light),
        darkTheme: octavaTheme(Brightness.dark),
        locale: chosen,
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
          return child!;
        },
        home: home,
      ),
    );
  }
}
