import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/public_band_repository.dart' show publicSiteUrl;
import '../l10n/l10n.dart';

/// Where invites point: the landing page, which sends phones to their store
/// (or the web preview until the app is in the stores).
const inviteUrl = '${publicSiteUrl}get/';

/// Tests replace the phone's share sheet with this.
@visibleForTesting
Future<void> Function(String text)? debugShareOverride;

/// "Invite musicians": the phone's share sheet with a short message and the
/// landing-page link. On the web, or if sharing isn't available, the message
/// is copied instead.
Future<void> inviteMusicians(BuildContext context) async {
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  final text = t.inviteMessage(inviteUrl);
  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(t.inviteCopied)));
  }

  if (debugShareOverride != null) return debugShareOverride!(text);
  if (kIsWeb) return copy();
  // iPads anchor the share sheet to the button that opened it.
  final box = context.findRenderObject() as RenderBox?;
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: t.inviteSubject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (result.status == ShareResultStatus.unavailable) await copy();
  } catch (_) {
    await copy();
  }
}
