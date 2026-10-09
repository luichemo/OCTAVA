import 'package:flutter/material.dart';

import 'screens/swipe_screen.dart';
import 'theme.dart';

void main() {
  runApp(const OctavaApp());
}

class OctavaApp extends StatelessWidget {
  const OctavaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCTAVA',
      debugShowCheckedModeBanner: false,
      theme: octavaTheme(Brightness.light),
      darkTheme: octavaTheme(Brightness.dark),
      home: const SwipeScreen(),
    );
  }
}
