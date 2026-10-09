import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

// Language names are shown in their own language, so anyone can find theirs.
const _english = 'English';
const _georgian = 'ქართული';

/// Device / English / ქართული, for the profile screen. Applies right away.
class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLanguage,
      builder: (context, chosen, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'device',
                label: Text(context.t.languageDevice),
              ),
              const ButtonSegment(value: 'en', label: Text(_english)),
              const ButtonSegment(value: 'ka', label: Text(_georgian)),
            ],
            selected: {chosen?.languageCode ?? 'device'},
            onSelectionChanged: (picked) {
              final code = picked.single;
              appLanguage.choose(code == 'device' ? null : Locale(code));
            },
          ),
          Text(
            context.t.languageInfo,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A one-tap switch to the other language, for the sign-in screen.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final georgianNow = Localizations.localeOf(context).languageCode == 'ka';
    return TextButton.icon(
      onPressed: () => appLanguage.choose(Locale(georgianNow ? 'en' : 'ka')),
      icon: const Icon(Icons.language_rounded, size: 18),
      label: Text(georgianNow ? _english : _georgian),
    );
  }
}
