import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One colour theme: the inks and paper of a screen print, in light and dark.
/// The accent names come from the first theme (OCTAVA's pink, yellow and
/// aqua) and stay as roles in the others: [pink] is the main accent (stamps,
/// the mic, "Jam"), [yellow] the highlight (hard shadows, the swipe hint),
/// [aqua] the third ink (selected chips, "In the band"). Text on any accent
/// uses [ink], so ink must stay dark in every theme.
class OctavaPalette {
  const OctavaPalette({
    required this.id,
    required this.ink,
    required this.inkSoft,
    required this.paper,
    required this.card,
    required this.line,
    required this.pink,
    required this.pinkTint,
    required this.yellow,
    required this.aqua,
    required this.darkPaper,
    required this.darkCard,
    required this.darkInk,
    required this.darkInkSoft,
    required this.darkLine,
    required this.darkPinkTint,
    required this.darkShadow,
  });

  /// Saved on the device and used for the theme's translated name.
  final String id;

  final Color ink;
  final Color inkSoft;
  final Color paper;
  final Color card;
  final Color line;
  final Color pink;
  final Color pinkTint;
  final Color yellow;
  final Color aqua;

  // Dark mode: the paper becomes a deep version of the ink, the ink light.
  final Color darkPaper;
  final Color darkCard;
  final Color darkInk;
  final Color darkInkSoft;
  final Color darkLine;
  final Color darkPinkTint;

  /// Hard shadows in dark mode: darker than the paper, so cards still lift.
  final Color darkShadow;
}

/// The original screen-print palette (design/stitch DESIGN.md: "Screenprint
/// Gig Poster Neo-Brutalist"): flat spot inks on paper, outlined in navy.
const octavaPalette = OctavaPalette(
  id: 'octava',
  ink: Color(0xFF22328C),
  inkSoft: Color(0xFF56619E),
  paper: Color(0xFFEEF0EC),
  card: Color(0xFFFAFBF8),
  line: Color(0xFFC5CBE0),
  pink: Color(0xFFFF4FA3),
  pinkTint: Color(0xFFFFC9E2),
  yellow: Color(0xFFFFE14D),
  aqua: Color(0xFF74D3EA),
  darkPaper: Color(0xFF10173A),
  darkCard: Color(0xFF18214D),
  darkInk: Color(0xFFE8EBF8),
  darkInkSoft: Color(0xFFA7B0DA),
  darkLine: Color(0xFF33407A),
  darkPinkTint: Color(0xFF5A2A57),
  darkShadow: Color(0xFF05081C),
);

/// Warm, like a summer festival poster: plum, coral, orange-gold, sand.
const sunsetPalette = OctavaPalette(
  id: 'sunset',
  ink: Color(0xFF3B1F4A),
  inkSoft: Color(0xFF6E5480),
  paper: Color(0xFFFBF3EA),
  card: Color(0xFFFFFAF4),
  line: Color(0xFFE3D3CF),
  pink: Color(0xFFFF6B5B),
  pinkTint: Color(0xFFFFD3CC),
  yellow: Color(0xFFFFB238),
  aqua: Color(0xFFF7D774),
  darkPaper: Color(0xFF1E0F27),
  darkCard: Color(0xFF2C1838),
  darkInk: Color(0xFFF6E9F0),
  darkInkSoft: Color(0xFFC7A9C9),
  darkLine: Color(0xFF4E3460),
  darkPinkTint: Color(0xFF5E2A33),
  darkShadow: Color(0xFF0E0612),
);

/// Raw, like a rehearsal room: forest green, orange, lime, sky. Orange is
/// the main accent because lime is too pale to read as text on the paper.
const garagePalette = OctavaPalette(
  id: 'garage',
  ink: Color(0xFF1E3A2B),
  inkSoft: Color(0xFF527062),
  paper: Color(0xFFF1F2E9),
  card: Color(0xFFFAFBF5),
  line: Color(0xFFC9D3C6),
  pink: Color(0xFFFF8A3D),
  pinkTint: Color(0xFFFFD9BF),
  yellow: Color(0xFFB8E04A),
  aqua: Color(0xFF7CC4E8),
  darkPaper: Color(0xFF0F1F17),
  darkCard: Color(0xFF173024),
  darkInk: Color(0xFFE6F0E8),
  darkInkSoft: Color(0xFFA6C2B0),
  darkLine: Color(0xFF2F4D3D),
  darkPinkTint: Color(0xFF55331C),
  darkShadow: Color(0xFF050D09),
);

/// Neon and electronic: violet, magenta, cyan, lilac.
const synthwavePalette = OctavaPalette(
  id: 'synthwave',
  ink: Color(0xFF2A1B5C),
  inkSoft: Color(0xFF615394),
  paper: Color(0xFFF3F0FA),
  card: Color(0xFFFBFAFE),
  line: Color(0xFFD2CBE8),
  pink: Color(0xFFFF3EC8),
  pinkTint: Color(0xFFFFCBEF),
  yellow: Color(0xFF3EE6FF),
  aqua: Color(0xFFB48CFF),
  darkPaper: Color(0xFF140C33),
  darkCard: Color(0xFF1F1547),
  darkInk: Color(0xFFEDE8FF),
  darkInkSoft: Color(0xFFB2A6E0),
  darkLine: Color(0xFF3B2D75),
  darkPinkTint: Color(0xFF5A1F55),
  darkShadow: Color(0xFF07041A),
);

/// Minimal, like a punk zine: black, greys and one red.
const monoPalette = OctavaPalette(
  id: 'mono',
  ink: Color(0xFF151515),
  inkSoft: Color(0xFF5C5C5C),
  paper: Color(0xFFF2F1EE),
  card: Color(0xFFFBFAF8),
  line: Color(0xFFCFCDC8),
  pink: Color(0xFFE63B2E),
  pinkTint: Color(0xFFF8CFCB),
  yellow: Color(0xFFBDBDBD),
  aqua: Color(0xFF8C8C8C),
  darkPaper: Color(0xFF111111),
  darkCard: Color(0xFF1C1C1C),
  darkInk: Color(0xFFEDEDED),
  darkInkSoft: Color(0xFFA8A8A8),
  darkLine: Color(0xFF3A3A3A),
  darkPinkTint: Color(0xFF4A1F1C),
  darkShadow: Color(0xFF000000),
);

/// Every theme, in the order the picker shows them.
const palettes = [
  octavaPalette,
  sunsetPalette,
  garagePalette,
  synthwavePalette,
  monoPalette,
];

/// The chosen colour theme, remembered on this device. Works like the
/// light/dark setting (`appTheme`); OctavaApp rebuilds when it changes.
class PaletteController extends ValueNotifier<OctavaPalette> {
  PaletteController() : super(octavaPalette);

  static const _key = 'app_palette';

  Future<void> load() async {
    try {
      final saved = await SharedPreferencesAsync().getString(_key);
      value = palettes.firstWhere(
        (p) => p.id == saved,
        orElse: () => octavaPalette,
      );
    } catch (_) {
      // Can't read the setting: keep the default.
    }
  }

  Future<void> choose(OctavaPalette palette) async {
    value = palette;
    try {
      final prefs = SharedPreferencesAsync();
      palette == octavaPalette
          ? await prefs.remove(_key)
          : await prefs.setString(_key, palette.id);
    } catch (_) {
      // Not remembered next time; the choice still applies now.
    }
  }
}

/// The app-wide colour theme.
final appPalette = PaletteController();
