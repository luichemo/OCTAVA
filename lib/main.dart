import 'package:flutter/material.dart';

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
      home: const HomeScreen(),
    );
  }
}

/// Placeholder until the swipe screen is built. Shows the brand and the
/// "Your band" lineup from the prototype.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _lineup = [
    ('Guitar', 'You'),
    ('Drums', null),
    ('Bass', null),
    ('Vocals', null),
    ('Keys', null),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        // Keep a phone-width column when previewing in a wide browser window.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OCTAVA', style: displayStyle(color: colors.onSurface)),
                  const SizedBox(height: 16),
                  Text(
                    'Your band',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    spacing: 6,
                    children: [
                      for (final (role, who) in _lineup)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: who != null
                                  ? colors.surfaceContainer
                                  : null,
                              border: Border.all(
                                color: who != null
                                    ? colors.outline
                                    : colors.outlineVariant,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  role,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  who ?? 'Open',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Musicians near you will appear here.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
