import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'theme.dart';

// `async` + `await`: work like in TypeScript. Supabase must be ready before
// the first screen draws, so main waits for it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const OctavaApp());
}

class OctavaApp extends StatelessWidget {
  const OctavaApp({super.key, this.home = const AuthGate()});

  /// The first screen. Tests pass their own so they don't need Supabase.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCTAVA',
      debugShowCheckedModeBanner: false,
      theme: octavaTheme(Brightness.light),
      darkTheme: octavaTheme(Brightness.dark),
      home: home,
    );
  }
}
