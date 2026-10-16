import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/public_band_repository.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// The band page's "Public page" switch. When it's on: Copy link and View
/// page (the link opens in the browser, exactly as visitors see it).
class PublicPageCard extends StatelessWidget {
  const PublicPageCard({
    super.key,
    required this.bandId,
    required this.isPublic,
    required this.onChanged,
  });

  final String bandId;
  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final link = publicBandLink(bandId);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      decoration: printBox(context, radius: 20),
      // A see-through Material, so the switch's ripple shows on the card.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isPublic,
              onChanged: onChanged,
              secondary: const Icon(Icons.public_rounded),
              title: Text(
                t.publicPageTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isPublic ? t.publicPageOnHint : t.publicPageOffHint,
              ),
            ),
            if (isPublic)
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: link));
                      messenger.showSnackBar(
                        SnackBar(content: Text(t.publicPageCopied)),
                      );
                    },
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(t.publicPageCopy),
                  ),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(link),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(t.publicPageView),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
