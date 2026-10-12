import 'dart:async';

import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/live_updates.dart';
import '../l10n/l10n.dart';
import '../models/chat.dart';
import '../theme.dart';
import 'person_avatar.dart';

/// Shows [LiveUpdates.banners] at the top of the screen, over whatever page
/// is open, for a few seconds. Tapping one calls [onOpen] with its match;
/// swiping it up dismisses it.
class LiveBannerListener extends StatefulWidget {
  const LiveBannerListener({
    super.key,
    required this.live,
    required this.onOpen,
    required this.child,
    this.avatars,
  });

  final LiveUpdates? live;

  /// Shows the sender's avatar on message banners.
  final AvatarRepository? avatars;
  final void Function(MatchSummary match) onOpen;
  final Widget child;

  /// How long a banner stays up.
  static const showFor = Duration(seconds: 4);

  @override
  State<LiveBannerListener> createState() => _LiveBannerListenerState();
}

class _LiveBannerListenerState extends State<LiveBannerListener> {
  StreamSubscription<LiveBanner>? _sub;
  OverlayEntry? _entry;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sub = widget.live?.banners.listen(_show);
  }

  void _show(LiveBanner banner) {
    _hide();
    if (!mounted) return;
    // The navigator's overlay sits above every pushed page, so the banner
    // shows on the Matches list and in other chats too.
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _BannerCard(
        banner: banner,
        avatars: widget.avatars,
        onTap: () {
          _hide();
          widget.onOpen(banner.match);
        },
        onDismissed: _hide,
      ),
    );
    overlay.insert(entry);
    _entry = entry;
    _timer = Timer(LiveBannerListener.showFor, _hide);
  }

  void _hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onTap,
    required this.onDismissed,
    this.avatars,
  });

  final LiveBanner banner;
  final AvatarRepository? avatars;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final (title, body) = switch (banner) {
      MessageBanner(:final match, :final body) => (match.name, body),
      NewMatchBanner(:final match) => (
        t.matchTitle(match.name),
        t.bannerNewMatch,
      ),
    };
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Dismissible(
              key: ObjectKey(banner),
              direction: DismissDirection.up,
              onDismissed: (_) => onDismissed(),
              child: Material(
                color: colors.surfaceContainerHighest,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: OctavaColors.pink, width: 2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 12,
                      children: [
                        // Messages show who sent them; matches a heart.
                        if (banner is MessageBanner)
                          PersonAvatar(
                            name: banner.match.name,
                            avatarPath: banner.match.avatarPath,
                            avatars: avatars,
                            radius: 20,
                          )
                        else
                          const CircleAvatar(
                            backgroundColor: OctavaColors.pink,
                            foregroundColor: OctavaColors.ink,
                            child: Icon(Icons.favorite_rounded, size: 20),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
