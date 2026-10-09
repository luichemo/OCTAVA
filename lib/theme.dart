import 'package:flutter/material.dart';

/// OCTAVA's riso-print palette, carried over from prototype/index.html.
class OctavaColors {
  static const ink = Color(0xFF22328C);
  static const inkSoft = Color(0xFF56619E);
  static const paper = Color(0xFFEEF0EC);
  static const card = Color(0xFFFAFBF8);
  static const line = Color(0xFFC5CBE0);
  static const pink = Color(0xFFFF4FA3);
  static const pinkTint = Color(0xFFFFC9E2);
  static const yellow = Color(0xFFFFE14D);
  static const aqua = Color(0xFF74D3EA);

  // Dark mode: the paper becomes deep blue and the ink becomes light.
  static const darkPaper = Color(0xFF10173A);
  static const darkCard = Color(0xFF18214D);
  static const darkInk = Color(0xFFE8EBF8);
  static const darkInkSoft = Color(0xFFA7B0DA);
  static const darkLine = Color(0xFF33407A);
  static const darkPinkTint = Color(0xFF5A2A57);
}

/// Big Shoulders Display for headings and the wordmark.
TextStyle displayStyle({double size = 32, Color? color}) => TextStyle(
  fontFamily: 'BigShouldersDisplay',
  fontSize: size,
  fontWeight: FontWeight.w900,
  height: 0.95,
  color: color,
);

ThemeData octavaTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? OctavaColors.darkInk : OctavaColors.ink;
  final paper = dark ? OctavaColors.darkPaper : OctavaColors.paper;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: OctavaColors.pink,
    onPrimary: OctavaColors.ink, // Ink on pink stays dark in both modes.
    secondary: ink,
    onSecondary: paper,
    surface: paper,
    onSurface: ink,
    surfaceContainer: dark ? OctavaColors.darkCard : OctavaColors.card,
    onSurfaceVariant: dark ? OctavaColors.darkInkSoft : OctavaColors.inkSoft,
    outline: ink,
    outlineVariant: dark ? OctavaColors.darkLine : OctavaColors.line,
    tertiaryContainer: dark ? OctavaColors.darkPinkTint : OctavaColors.pinkTint,
    error: const Color(0xFFC62828),
    onError: Colors.white,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'InstrumentSans',
  );
  return base.copyWith(
    scaffoldBackgroundColor: paper,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
  );
}
