import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../data/avatar_repository.dart';
import '../data/clip_repository.dart';
import '../data/deck.dart';
import '../data/location_repository.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../models/deck_filters.dart';
import '../models/musician.dart';
import '../theme.dart';
import '../widgets/band_lineup.dart';
import '../widgets/musician_card.dart';
import '../widgets/safety_sheet.dart';
import 'filters_screen.dart';

/// The main screen: your band lineup, a deck of musician cards to drag or
/// tap through, and Pass / Jam buttons.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    super.key,
    this.source = const SampleDeck(),
    this.onSignOut,
    this.onOpenMatches,
    this.onOpenChat,
    this.safety,
    this.player,
    this.onOpenProfile,
    this.avatars,
    this.location,
    this.filterStore,
  });

  /// Sharing your location, for distances. Without it there's no prompt.
  final LocationRepository? location;

  /// Remembers filters. Defaults to keeping them only while the app runs.
  final FilterStore? filterStore;

  /// Shows AI avatars on cards when set.
  final AvatarRepository? avatars;

  /// Plays audio clips on cards. Without it the play buttons are disabled.
  final ClipPlayer? player;

  /// Shows a "Your profile" button when set. The lineup reloads afterwards,
  /// since your main instrument may have changed.
  final Future<void> Function()? onOpenProfile;

  /// Where people come from and swipes go.
  final DeckSource source;

  /// Shows a Sign out button when set.
  final VoidCallback? onSignOut;

  /// Block and report from a card. Without it cards have no flag button.
  final SafetyRepository? safety;

  /// Shows a Matches button when set.
  final VoidCallback? onOpenMatches;

  /// Opens the chat for a new match ("Say hi"). Without it, "Say hi" only
  /// shows a confirmation.
  final void Function(String matchId, Musician musician)? onOpenChat;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  // Role -> member. A Map keeps insertion order, which is the display order.
  Map<String, String?> _band = {};
  List<Musician> _queue = [];
  String? _justFilled;
  bool _loading = true;
  String? _loadError;

  late final FilterStore _store = widget.filterStore ?? MemoryFilterStore();
  DeckFilters _filters = const DeckFilters();
  bool _hasLocation = false;
  bool _filtersLoaded = false;
  bool _sharingLocation = false;

  // How far the top card has been dragged. Drives position, tilt and stamps.
  Offset _drag = Offset.zero;
  double _deckWidth = 360;
  bool _busy = false;

  late final AnimationController _anim = AnimationController(vsync: this);
  Animation<Offset>? _animOffset;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      final a = _animOffset;
      if (a != null) setState(() => _drag = a.value);
    });
    _load();
  }

  Future<void> _load() async {
    if (!_filtersLoaded) {
      _filters = await _store.load();
      _filtersLoaded = true;
    }
    _hasLocation = await widget.location?.hasLocation() ?? false;
    try {
      // Both requests run at the same time, like Promise.all.
      final (band, deck) = await (
        widget.source.loadLineup(),
        widget.source.loadDeck(_filters, hasLocation: _hasLocation),
      ).wait;
      if (!mounted) return;
      setState(() {
        _band = band;
        _queue = deck;
        _loading = false;
        _loadError = null;
      });
    } on ParallelWaitError catch (e) {
      final error = [
        e.errors.$1,
        e.errors.$2,
      ].whereType<UserFacingException>().firstOrNull;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error?.message ?? context.t.errLoadMusiciansShort;
      });
    }
  }

  void _reload() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  Future<void> _openFilters() async {
    await widget.player?.stop();
    if (!mounted) return;
    final chosen = await Navigator.of(context).push<DeckFilters>(
      MaterialPageRoute(
        builder: (_) =>
            FiltersScreen(initial: _filters, hasLocation: _hasLocation),
      ),
    );
    if (chosen == null || !mounted) return;
    _filters = chosen;
    await _store.save(chosen);
    _reload();
  }

  Future<void> _shareLocation() async {
    final location = widget.location;
    if (location == null) return;
    setState(() {
      _sharingLocation = true;
    });
    try {
      await location.shareCurrentLocation();
      if (mounted) _reload();
    } on UserFacingException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) {
        setState(() {
          _sharingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool _fitsOpenSlot(Musician m) =>
      _band.containsKey(m.instrumentId) && _band[m.instrumentId] == null;

  Color _toneFor(Musician m) => const [
    OctavaColors.pink,
    OctavaColors.yellow,
    OctavaColors.aqua,
  ][m.toneIndex];

  Future<void> _animateTo(Offset target, Duration duration, Curve curve) async {
    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _drag = target);
      return;
    }
    _anim.duration = duration;
    _animOffset = Tween(
      begin: _drag,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: curve));
    await _anim.forward(from: 0);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_busy || _queue.isEmpty) return;
    setState(() => _drag += Offset(details.delta.dx, details.delta.dy * 0.2));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_busy || _queue.isEmpty) return;
    final threshold = min(110.0, _deckWidth * 0.28);
    if (_drag.dx.abs() > threshold) {
      _decide(_drag.dx > 0 ? Decision.jam : Decision.pass);
    } else {
      _animateTo(
        Offset.zero,
        const Duration(milliseconds: 250),
        Curves.easeOut,
      );
    }
  }

  Future<void> _decide(Decision decision) async {
    if (_busy || _queue.isEmpty) return;
    _busy = true;
    widget.player?.stop();
    final musician = _queue.first;
    final direction = decision == Decision.jam ? 1.0 : -1.0;
    // Save while the card flies away. _attempt never throws, so a failure
    // can't go unhandled while the animation runs.
    final saving = _attempt(widget.source.swipe(musician, decision));
    await _animateTo(
      Offset(direction * _deckWidth * 1.4, 30),
      const Duration(milliseconds: 350),
      Curves.easeIn,
    );
    if (!mounted) return;
    setState(() {
      _queue = _queue.sublist(1);
      _drag = Offset.zero;
      _justFilled = null;
    });
    _busy = false;

    final outcome = await saving;
    if (!mounted) return;
    if (outcome is UserFacingException) {
      // Not saved: put the card back so the person can try again.
      setState(() => _queue = [musician, ..._queue]);
      _toast(outcome.message);
      return;
    }
    final matchId = outcome is String ? outcome : null;

    if (decision == Decision.pass) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.t.passedOn(musician.name),
        TextDirection.ltr,
      );
    } else if (matchId != null) {
      await _showMatch(musician, matchId);
    } else {
      _toast(context.t.askedToJam(musician.name));
    }
  }

  Future<void> _showMatch(Musician m, String matchId) async {
    final filledSlot = _fitsOpenSlot(m);
    final holder = _band[m.instrumentId];
    if (filledSlot) {
      setState(() {
        _band[m.instrumentId!] = m.name;
        _justFilled = m.instrumentId;
      });
    }
    final saidHi = await showDialog<bool>(
      context: context,
      builder: (context) => _MatchDialog(
        title: context.t.matchTitle(m.name),
        body: filledSlot
            ? context.t.matchSlotFilled(m.instrument)
            : holder == youMarker
            ? context.t.matchSlotYours(m.instrument.toLowerCase())
            : context.t.matchSlotTaken(
                holder ?? '',
                m.instrument.toLowerCase(),
              ),
      ),
    );
    if (saidHi != true || !mounted) return;
    final openChat = widget.onOpenChat;
    if (openChat != null) {
      openChat(matchId, m);
    } else {
      _toast(context.t.saidHi(m.name));
    }
  }

  void _toast(String message) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.surface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          backgroundColor: colors.onSurface,
          behavior: SnackBarBehavior.floating,
          shape: const StadiumBorder(),
          duration: const Duration(milliseconds: 2400),
        ),
      );
  }

  Future<void> _openSafety(Musician m) async {
    final safety = widget.safety;
    if (safety == null || m.id == null || _busy) return;
    final blocked = await showSafetyOptions(
      context,
      safety: safety,
      userId: m.id!,
      name: m.name,
    );
    if (blocked && mounted) {
      setState(() {
        _queue = _queue.where((q) => q.key != m.key).toList();
        _drag = Offset.zero;
      });
    }
  }

  /// The swipe's result (a match id, or null), or the error to show.
  Future<Object?> _attempt(Future<String?> swipe) async {
    try {
      return await swipe;
    } on UserFacingException catch (e) {
      return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canSwipe = !_loading && _loadError == null && _queue.isNotEmpty;

    // Arrow keys mirror the buttons (useful in the browser preview).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (canSwipe) _decide(Decision.jam);
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (canSwipe) _decide(Decision.pass);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            // Keep a phone-width column when previewing in a wide browser window.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'OCTAVA',
                            style: displayStyle(color: colors.onSurface)
                                .copyWith(letterSpacing: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              // The summary is also the way into the filters.
                              child: TextButton.icon(
                                onPressed: _loading ? null : _openFilters,
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: Text(
                                  _filters.describe(hasLocation: _hasLocation),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.onSurfaceVariant,
                                  textStyle: const TextStyle(fontSize: 14),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      BandLineup(band: _band, justFilled: _justFilled),
                      if (widget.location != null &&
                          !_loading &&
                          !_hasLocation) ...[
                        const SizedBox(height: 10),
                        _LocationPrompt(
                          busy: _sharingLocation,
                          onShare: _shareLocation,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _deckWidth = constraints.maxWidth;
                            if (_loading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (_loadError != null) {
                              return _DeckMessage(
                                title: context.t.loadErrorTitle,
                                body: _loadError!,
                                action: context.t.tryAgain,
                                onAction: _reload,
                              );
                            }
                            if (_queue.isEmpty && _filters.activeCount > 0) {
                              return _DeckMessage(
                                title: context.t.noMatchTitle,
                                body: context.t.noMatchBody,
                                action: context.t.changeFilters,
                                onAction: _openFilters,
                              );
                            }
                            if (_queue.isEmpty) {
                              return _DeckMessage(
                                title: context.t.heardEveryoneTitle,
                                body: context.t.heardEveryoneBody,
                                action: context.t.checkAgain,
                                onAction: _reload,
                              );
                            }
                            return _buildDeck();
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        canSwipe
                            ? (kIsWeb
                                  ? context.t.swipeHintWeb
                                  : context.t.swipeHint)
                            : ' ',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (widget.onOpenProfile != null ||
                          widget.onOpenMatches != null ||
                          widget.onSignOut != null) ...[
                        const SizedBox(height: 8),
                        _BottomBar(
                          onProfile: widget.onOpenProfile == null
                              ? null
                              : () async {
                                  await widget.player?.stop();
                                  await widget.onOpenProfile!();
                                  if (mounted) _reload();
                                },
                          onMatches: widget.onOpenMatches,
                          onSignOut: widget.onSignOut,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeck() {
    final top = _queue.first;
    final next = _queue.length > 1 ? _queue[1] : null;
    return Stack(
      children: [
        if (next != null)
          Positioned.fill(
            // The next card waits underneath, slightly smaller and lower.
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: const Offset(0, 10),
                  child: Transform.scale(
                    scale: 0.96,
                    child: MusicianCard(
                      key: ValueKey(next.key),
                      musician: next,
                      tone: _toneFor(next),
                      fitsOpenSlot: _fitsOpenSlot(next),
                      avatars: widget.avatars,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          // Swiping is the only control, so give screen readers named actions.
          child: Semantics(
            customSemanticsActions: {
              CustomSemanticsAction(label: context.t.actionJam): () =>
                  _decide(Decision.jam),
              CustomSemanticsAction(label: context.t.actionPass): () =>
                  _decide(Decision.pass),
            },
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: _drag,
                child: Transform.rotate(
                  angle: _drag.dx / 18 * pi / 180,
                  child: MusicianCard(
                    key: ValueKey(top.key),
                    musician: top,
                    tone: _toneFor(top),
                    fitsOpenSlot: _fitsOpenSlot(top),
                    jamStamp: _drag.dx / 90,
                    passStamp: -_drag.dx / 90,
                    onSafety: widget.safety == null
                        ? null
                        : () => _openSafety(top),
                    player: widget.player,
                    avatars: widget.avatars,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchDialog extends StatelessWidget {
  const _MatchDialog({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: displayStyle(size: 46, color: colors.onSurface),
              ),
              const SizedBox(height: 10),
              Text(body),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.t.sayHi),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.t.keepSwiping),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fills the deck area when there are no cards: nobody left, or an error.
class _DeckMessage extends StatelessWidget {
  const _DeckMessage({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(title, style: displayStyle(size: 48, color: colors.onSurface)),
          Text(body, style: TextStyle(color: colors.onSurfaceVariant)),
          OutlinedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

/// Invites you to share your location so cards can show distances.
class _LocationPrompt extends StatelessWidget {
  const _LocationPrompt({required this.busy, required this.onShare});

  final bool busy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t.locationPrompt,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: busy ? null : onShare,
            child: Text(
              busy ? context.t.findingYou : context.t.shareLocationShort,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation: Profile, Matches and Sign out, with labels.
class _BottomBar extends StatelessWidget {
  const _BottomBar({this.onProfile, this.onMatches, this.onSignOut});

  final VoidCallback? onProfile;
  final VoidCallback? onMatches;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outlineVariant, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (onProfile != null)
            _BarButton(
              icon: Icons.person_outline_rounded,
              label: context.t.navProfile,
              onTap: onProfile!,
            ),
          if (onMatches != null)
            _BarButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: context.t.navMatches,
              onTap: onMatches!,
            ),
          if (onSignOut != null)
            _BarButton(
              icon: Icons.logout_rounded,
              label: context.t.signOut,
              onTap: onSignOut!,
            ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.onSurface),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
