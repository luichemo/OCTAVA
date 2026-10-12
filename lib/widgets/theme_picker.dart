import 'package:flutter/material.dart';

import '../data/theme_setting.dart';
import '../l10n/l10n.dart';

/// Device / Light / Dark, for the profile screen. Applies right away.
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
        ],
      ),
    );
  }
}
