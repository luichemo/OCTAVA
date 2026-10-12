import 'package:flutter/material.dart';

/// OCTAVA's screen-print palette (design/stitch DESIGN.md: "Screenprint Gig
/// Poster Neo-Brutalist"): flat spot inks on paper, outlined in navy ink.
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

  // Dark mode ("backstage"): the paper becomes deep blue and the ink light.
  static const darkPaper = Color(0xFF10173A);
  static const darkCard = Color(0xFF18214D);
  static const darkInk = Color(0xFFE8EBF8);
  static const darkInkSoft = Color(0xFFA7B0DA);
  static const darkLine = Color(0xFF33407A);
  static const darkPinkTint = Color(0xFF5A2A57);

  /// Hard shadows in dark mode: darker than the paper, so cards still lift.
  static const darkShadow = Color(0xFF05081C);
}

/// Neither main font has Georgian letters; Noto Sans Georgian fills in.
const georgianFallback = ['NotoSansGeorgian'];

/// True while the app is shown in Georgian; OctavaApp sets it before
/// building the themes and screens.
bool georgianType = false;

/// How much smaller headings are in Georgian. Bebas has no Georgian letters,
/// and the Noto Sans Georgian fallback is far wider and heavier at the same
/// size, so Georgian headings would otherwise look huge. (All text is also
/// 10% smaller in Georgian; see OctavaApp.)
const georgianHeadingScale = 0.8;

/// Whether [text] has Georgian letters, for text that may be in either
/// script (people's names): `displayStyle(latin: !hasGeorgian(name))`.
bool hasGeorgian(String text) => RegExp(r'[Ⴀ-ჿ]').hasMatch(text);

/// Bebas Neue for headings, stamps and the wordmark: tall condensed capitals.
/// It's registered as weight 700 (pubspec.yaml), so the Georgian fallback is
/// bold too, and Bebas itself isn't faux-bolded. [latin]: text that's always
/// in Latin letters (the wordmark), which keeps its size in Georgian.
TextStyle displayStyle({double size = 32, Color? color, bool latin = false}) {
  final georgian = georgianType && !latin;
  return TextStyle(
    fontFamily: 'BebasNeue',
    fontFamilyFallback: georgianFallback,
    fontSize: georgian ? size * georgianHeadingScale : size,
    fontWeight: georgian ? FontWeight.w600 : FontWeight.w700,
    height: georgian ? 1.2 : 1.0,
    letterSpacing: georgian ? 0 : size * 0.04,
    color: color,
  );
}

/// The colour of hard offset shadows: ink on paper, near-black in the dark.
Color shadowInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? OctavaColors.darkShadow
    : OctavaColors.ink;

/// A hard, unblurred offset shadow, like a misregistered second print pass.
List<BoxShadow> hardShadow(Color color, {double offset = 4}) => [
  BoxShadow(color: color, offset: Offset(offset, offset)),
];

/// A printed surface: 2px ink outline, rounded corners and a hard shadow.
/// [shadow] 0 leaves the shadow off.
BoxDecoration printBox(
  BuildContext context, {
  Color? color,
  double radius = 16,
  double shadow = 4,
  Color? shadowColor,
  Color? borderColor,
}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: color ?? scheme.surfaceContainer,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? scheme.outline, width: 2),
    boxShadow: shadow == 0
        ? null
        : hardShadow(shadowColor ?? shadowInk(context), offset: shadow),
  );
}

ThemeData octavaTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? OctavaColors.darkInk : OctavaColors.ink;
  final paper = dark ? OctavaColors.darkPaper : OctavaColors.paper;
  final card = dark ? OctavaColors.darkCard : OctavaColors.card;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: OctavaColors.pink,
    onPrimary: OctavaColors.ink, // Ink on pink stays dark in both modes.
    secondary: ink,
    onSecondary: paper,
    surface: paper,
    onSurface: ink,
    surfaceContainer: card,
    surfaceContainerHighest: card,
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
    fontFamily: 'Inter',
    fontFamilyFallback: georgianFallback,
  );
  final inkSide = BorderSide(color: ink, width: 2);
  // Pill buttons with bold poster capitals.
  final buttonText = displayStyle(size: 22);
  const labelText = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: georgianFallback,
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );
  OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: 2),
  );
  return base.copyWith(
    scaffoldBackgroundColor: paper,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: displayStyle(size: 30, color: ink),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      // Extra height so Georgian ascenders and descenders aren't clipped.
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700),
      border: inputBorder(ink),
      enabledBorder: inputBorder(ink),
      focusedBorder: inputBorder(OctavaColors.pink),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: card,
      selectedColor: OctavaColors.aqua,
      checkmarkColor: OctavaColors.ink,
      side: inkSide,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      labelStyle: labelText.copyWith(color: ink),
      // Selected chips are aqua in both modes, so their text stays dark.
      secondaryLabelStyle: labelText.copyWith(color: OctavaColors.ink),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: inkSide,
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? OctavaColors.pink
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(OctavaColors.ink),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(ink)),
    sliderTheme: SliderThemeData(
      activeTrackColor: OctavaColors.pink,
      inactiveTrackColor: scheme.outlineVariant,
      thumbColor: ink,
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: OctavaColors.pink,
      textColor: OctavaColors.ink,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: inkSide,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: inkSide,
      ),
      titleTextStyle: displayStyle(size: 30, color: ink),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: ink,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: inkSide,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: inkSide,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: OctavaColors.pink,
        foregroundColor: OctavaColors.ink,
        disabledBackgroundColor: scheme.outlineVariant,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: StadiumBorder(
          side: BorderSide(color: OctavaColors.ink, width: 2),
        ),
        textStyle: buttonText,
        iconSize: 22,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: card,
        foregroundColor: ink,
        side: inkSide,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const StadiumBorder(),
        textStyle: buttonText.copyWith(fontSize: 20),
        iconSize: 22,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ink, textStyle: labelText),
    ),
  );
}

/// A filled pill button sitting on a hard shadow, that presses down into it
/// when tapped, like a mechanical key. Use it for a screen's main action.
class PrintButton extends StatefulWidget {
  const PrintButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = OctavaColors.pink,
    this.shadowColor = OctavaColors.yellow,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color shadowColor;

  @override
  State<PrintButton> createState() => _PrintButtonState();
}

class _PrintButtonState extends State<PrintButton> {
  bool _down = false;

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final lift = _down || !enabled ? 1.0 : 4.0;
    // The button moves by as much as the shadow shrinks, so it looks pressed.
    return Listener(
      onPointerDown: enabled ? (_) => _setDown(true) : null,
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(4 - lift, 4 - lift, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: hardShadow(widget.shadowColor, offset: lift),
        ),
        child: FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(backgroundColor: widget.color),
          child: widget.child,
        ),
      ),
    );
  }
}
