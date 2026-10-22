import 'dart:async';

import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/rehearsal_repository.dart';

import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/chat.dart';
import '../theme.dart';
import 'person_avatar.dart';

/// Shows [LiveUpdates.banners] (and [LiveBands.banners]) at the top of the
/// screen, over whatever page is open, for a few seconds. Tapping one calls
/// [onOpen] with its match (or [onOpenBand] with its band); swiping it up
/// dismisses it.
class LiveBannerListener extends StatefulWidget {
  const LiveBannerListener({
    super.key,
    required this.live,
    required this.onOpen,
    required this.child,
    this.avatars,
    this.bands,
    this.onOpenBand,
    this.reminders,
  });

  /// Rehearsals about to start (opened with [onOpenBand]).
  final Stream<BandRehearsal>? reminders;

  final LiveUpdates? live;

  /// Band chat messages, opened with [onOpenBand].
  final LiveBands? bands;
  final void Function(String bandId)? onOpenBand;

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
  StreamSubscription<BandMessageBanner>? _bandSub;
  StreamSubscription<BandRehearsal>? _reminderSub;
  OverlayEntry? _entry;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sub = widget.live?.banners.listen(
      (banner) => _show(
        _BannerData.from(banner, widget.avatars),
        () => widget.onOpen(banner.match),
      ),
    );
    _reminderSub = widget.reminders?.listen(_showReminder);
    _bandSub = widget.bands?.banners.listen(
      (banner) => _show(
        _BannerData(
          key: banner,
          title: banner.band.name,
          body: L10n.current.bandMessagePreview(
            banner.sender.name,
            banner.body,
          ),
          leading: PersonAvatar(
            name: banner.sender.name,
            avatarPath: banner.sender.avatarPath,
            avatars: widget.avatars,
            radius: 20,
          ),
        ),
        () => widget.onOpenBand?.call(banner.band.id),
      ),
    );
  }

  void _showReminder(BandRehearsal r) {
    final time = DateFormat.Hm(L10n.current.localeName).format(r.date.startsAt);
    _show(
      _BannerData(
        key: r,
        title: L10n.current.rehearsalReminder(r.bandName, time),
        body: L10n.current.rehearsalReminderBody,
        leading: CircleAvatar(
          backgroundColor: OctavaColors.yellow,
          foregroundColor: OctavaColors.ink,
          child: Icon(Icons.event_rounded, size: 20),
        ),
      ),
      () => widget.onOpenBand?.call(r.bandId),
    );
  }

  void _show(_BannerData banner, VoidCallback open) {
    _hide();
    if (!mounted) return;
    // The navigator's overlay sits above every pushed page, so the banner
    // shows on the Matches list and in other chats too.
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _BannerCard(
        banner: banner,
        onTap: () {
          _hide();
          open();
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
    _bandSub?.cancel();
    _reminderSub?.cancel();
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// What a banner shows, whatever it's about.
class _BannerData {
  const _BannerData({
    required this.key,
    required this.title,
    required this.body,
    required this.leading,
  });

  /// A match banner: messages show who sent them; new matches a heart.
  factory _BannerData.from(LiveBanner banner, AvatarRepository? avatars) =>
      switch (banner) {
        MessageBanner(:final match, :final body) => _BannerData(
          key: banner,
          title: match.name,
          body: body,
          leading: PersonAvatar(
            name: match.name,
            avatarPath: match.avatarPath,
            avatars: avatars,
            radius: 20,
          ),
        ),
        NewMatchBanner(:final match) => _BannerData(
          key: banner,
          title: L10n.current.matchTitle(match.name),
          body: L10n.current.bannerNewMatch,
          leading: CircleAvatar(
            backgroundColor: OctavaColors.pink,
            foregroundColor: OctavaColors.ink,
            child: Icon(Icons.favorite_rounded, size: 20),
          ),
        ),
      };

  /// What it's about, so each banner is its own swipe-away card.
  final Object key;
  final String title;
  final String body;
  final Widget leading;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onTap,
    required this.onDismissed,
  });

  final _BannerData banner;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = banner.title;
    final body = banner.body;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Dismissible(
              key: ObjectKey(banner.key),
              direction: DismissDirection.up,
              onDismissed: (_) => onDismissed(),
              child: Material(
                color: colors.surfaceContainerHighest,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: OctavaColors.pink, width: 2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 12,
                      children: [
                        banner.leading,
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
