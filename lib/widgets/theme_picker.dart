import 'package:flutter/material.dart';

import '../data/palette.dart';
import '../data/theme_setting.dart';
import '../l10n/l10n.dart';

/// A colour theme's name, translated.
String paletteName(BuildContext context, OctavaPalette palette) {
  final t = context.t;
  return switch (palette.id) {
    'sunset' => t.paletteSunset,
    'garage' => t.paletteGarage,
    'synthwave' => t.paletteSynthwave,
    'mono' => t.paletteMono,
    _ => t.paletteOctava,
  };
}

/// Device / Light / Dark, then the colour themes, for the profile screen.
/// Both apply right away.
class ThemeSection extends StatelessWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appTheme,
      builder: (context, mode, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(t.languageDevice),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(t.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(t.themeDark),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (picked) => appTheme.choose(picked.single),
          ),
          Text(t.themeInfo, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text(
            t.themeColours,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const _PalettePicker(),
        ],
      ),
    );
  }
}

/// One round swatch per colour theme: its paper with the three accent inks,
/// outlined in its ink, and the name underneath.
class _PalettePicker extends StatelessWidget {
  const _PalettePicker();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OctavaPalette>(
      valueListenable: appPalette,
      builder: (context, chosen, _) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final palette in palettes)
            _Swatch(
              palette: palette,
              selected: palette.id == chosen.id,
              onTap: () => appPalette.choose(palette),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final OctavaPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = paletteName(context, palette);
    Widget dot(Color c) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: palette.ink, width: 1.5),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 72,
          child: Column(
            spacing: 6,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // A ring in the current ink marks the chosen theme.
                  border: Border.all(
                    color: selected ? colors.outline : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.ink, width: 2),
                  ),
                  child: Center(
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      alignment: WrapAlignment.center,
                      children: [
                        dot(palette.pink),
                        dot(palette.yellow),
                        dot(palette.aqua),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
