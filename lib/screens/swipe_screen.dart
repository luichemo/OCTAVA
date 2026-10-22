import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../data/avatar_repository.dart';
import '../data/band_repository.dart';
import '../data/clip_repository.dart';
import '../data/deck.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/location_repository.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../data/swipe_hint.dart';
import '../data/theme_setting.dart';
import '../models/band.dart';
import '../models/band_card.dart';
import '../models/deck_filters.dart';
import '../models/musician.dart';
import '../theme.dart';
import '../widgets/band_card.dart';
import '../widgets/band_lineup.dart';
import '../widgets/band_roles_sheet.dart';
import '../widgets/invite.dart';
import '../widgets/musician_card.dart';
import '../widgets/octava_logo.dart';
import '../widgets/safety_sheet.dart';
import 'filters_screen.dart';

/// The main screen: your band lineup, a deck of musician cards to drag or
/// tap through, and Pass / Jam buttons.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    super.key,
    this.source = const SampleDeck(),
    this.onRecord,
    this.onOpenMatches,
    this.onOpenChat,
    this.safety,
    this.player,
    this.onOpenProfile,
    this.avatars,
    this.location,
    this.filterStore,
    this.hints,
    this.bandNeeds,
    this.live,
    this.bands,
  });

  /// Your bands: invites and votes waiting add to the Matches badge.
  final LiveBands? bands;

  /// Live matches: the unread badge on Matches, and reloading the band row
  /// when someone matches with you or unmatches.
  final LiveUpdates? live;

  /// The roles your band needs. Defaults to keeping them only while the app
  /// runs.
  final BandNeedsRepository? bandNeeds;

  /// Sharing your location, for distances. Without it there's no prompt.
  final LocationRepository? location;

  /// Remembers filters. Defaults to keeping them only while the app runs.
  final FilterStore? filterStore;

  /// Remembers the first-time swipe hint; once per device by default.
  final HintStore? hints;

  /// Shows AI avatars on cards when set.
  final AvatarRepository? avatars;

  /// Plays audio clips on cards. Without it the play buttons are disabled.
  final ClipPlayer? player;

  /// Shows a "Your profile" button when set. The lineup reloads afterwards,
  /// since your main instrument may have changed.
  final Future<void> Function()? onOpenProfile;

  /// Where people come from and swipes go.
  final DeckSource source;

  /// Shows the ➕ button (record or upload a clip) in the bottom bar when set.
  final VoidCallback? onRecord;

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
  // The lineup is rebuilt from these three whenever one changes.
  String? _myRole;
  Map<String, int>? _needs; // null until chosen: the default roles
  List<BandMember> _members = [];
  List<BandSlot> _band = [];

  /// People, with a band card mixed in every few (see mixDeck).
  List<DeckItem> _queue = [];
  int? _justFilled; // index in _band
  late final BandNeedsRepository _bandNeeds =
      widget.bandNeeds ?? MemoryBandNeeds();
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

  // The first-time hint: the top card nudges right (Jam) and left (Pass)
  // with a hand, like TikTok's first swipe-up hint. Any touch stops it.
  late final HintStore _hints = widget.hints ?? PrefsHintStore();
  bool _hintChecked = false;
  bool _hinting = false;
  bool _hintShown = false; // stays true while the hint fades out

  late int _matchSetVersion = widget.live?.matchSetVersion ?? 0;

  void _onLive() {
    final version = widget.live!.matchSetVersion;
    if (version == _matchSetVersion) return;
    _matchSetVersion = version;
    _refreshBand();
  }

  /// Reloads only the band row, keeping the cards where they are.
  Future<void> _refreshBand() async {
    try {
      final band = await widget.source.loadBand();
      if (!mounted) return;
      setState(() {
        _myRole = band.myRole;
        _members = band.members;
        _rebuildBand();
      });
    } on UserFacingException {
      // The row stays as it was; the next full load tries again.
    }
  }

  @override
  void initState() {
    super.initState();
    widget.live?.addListener(_onLive);
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
      // The requests run at the same time, like Promise.all.
      final (band, needs, deck, bandCards) = await (
        widget.source.loadBand(),
        _bandNeeds.load(),
        widget.source.loadDeck(_filters, hasLocation: _hasLocation),
        widget.source.loadBandCards(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _myRole = band.myRole;
        _members = band.members;
        _needs = needs;
        _rebuildBand();
        _queue = mixDeck(deck, bandCards);
        _loading = false;
        _loadError = null;
      });
      _maybeShowHint();
    } on ParallelWaitError catch (e) {
      final error = [
        e.errors.$1,
        e.errors.$2,
        e.errors.$3,
        e.errors.$4,
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
    widget.live?.removeListener(_onLive);
    _anim.dispose();
    super.dispose();
  }

  void _rebuildBand() {
    _band = buildLineup(myRole: _myRole, needs: _needs, members: _members);
  }

  int _openSlotFor(Musician m) =>
      _band.indexWhere((s) => s.role == m.instrumentId && s.member == null);

  bool _fitsOpenSlot(Musician m) => _openSlotFor(m) >= 0;

  Future<void> _editBand() async {
    final chosen = await showBandRolesSheet(
      context,
      needs: _needs ?? defaultBandNeeds(_myRole),
    );
    if (chosen == null || !mounted) return;
    try {
      await _bandNeeds.save(chosen);
    } on UserFacingException catch (e) {
      if (mounted) _toast(e.message);
      return;
    }
    if (!mounted) return;
    setState(() {
      _needs = chosen;
      _justFilled = null;
      _rebuildBand();
    });
    // People who fill an open role come first, so the order may change.
    _reload();
  }

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
    try {
      await _anim.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Stopped early: the hint was interrupted, or the screen closed.
    }
  }

  /// Plays the swipe hint once, the first time there's a card to swipe.
  Future<void> _maybeShowHint() async {
    if (!swipeHintEnabled || _hintChecked || _queue.isEmpty) return;
    _hintChecked = true;
    if (await _hints.seen()) return;
    // Let the card land on screen first.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || _queue.isEmpty || _busy || _drag != Offset.zero) return;
    // Remembered straight away, so closing the app mid-hint doesn't replay it.
    await _hints.markSeen();
    if (!mounted) return;
    setState(() {
      _hinting = true;
      _hintShown = true;
    });
    if (MediaQuery.of(context).disableAnimations) {
      // No movement: the caption alone, for a few seconds.
      await Future<void>.delayed(const Duration(seconds: 4));
    } else {
      final nudge = min(80.0, _deckWidth * 0.22);
      for (var round = 0; round < 2; round++) {
        for (final step in [
          (Offset(nudge, 0), 450, Curves.easeOut),
          (Offset.zero, 350, Curves.easeInOut),
          (Offset(-nudge, 0), 450, Curves.easeOut),
          (Offset.zero, 350, Curves.easeInOut),
        ]) {
          if (!_hinting || !mounted) return;
          await _animateTo(step.$1, Duration(milliseconds: step.$2), step.$3);
        }
        if (!_hinting || !mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    _stopHint();
  }

  /// Ends the hint at once; the card stays where it is for the person's drag.
  void _stopHint() {
    if (!_hinting) return;
    _anim.stop();
    if (mounted) {
      setState(() {
        _hinting = false;
      });
    }
  }

  /// A touch on the card that didn't become a drag: put the card back.
  void _onPanCancel() {
    if (_busy || _drag == Offset.zero) return;
    _animateTo(Offset.zero, const Duration(milliseconds: 200), Curves.easeOut);
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
    _stopHint();
    _busy = true;
    widget.player?.stop();
    final item = _queue.first;
    final direction = decision == Decision.jam ? 1.0 : -1.0;
    // Save while the card flies away. _attempt never throws, so a failure
    // can't go unhandled while the animation runs.
    final saving = _attempt(switch (item) {
      PersonItem(:final musician) => widget.source.swipe(musician, decision),
      BandItem(:final band) => widget.source.swipeBand(band, decision),
    });
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
      setState(() => _queue = [item, ..._queue]);
      _toast(outcome.message);
      return;
    }
    if (item case BandItem(:final band)) {
      // A Jam asked to join; there's no undo for band swipes yet.
      _toast(
        decision == Decision.jam
            ? context.t.bandAskedToJoin(band.name)
            : context.t.bandPassedOn(band.name),
      );
      return;
    }
    final musician = (item as PersonItem).musician;
    final matchId = outcome is String ? outcome : null;

    if (matchId != null) {
      await _showMatch(musician, matchId);
    } else {
      _toast(
        decision == Decision.pass
            ? context.t.passedOn(musician.name)
            : context.t.askedToJam(musician.name),
        onUndo: () => _undo(musician),
      );
    }
  }

  /// Puts a card back on top after its swipe is taken back.
  Future<void> _undo(Musician musician) async {
    try {
      await widget.source.undo(musician);
    } on UserFacingException catch (e) {
      if (mounted) _toast(e.message);
      return;
    }
    if (!mounted) return;
    setState(() {
      _queue = [
        PersonItem(musician),
        ..._queue.where(
          (q) => !(q is PersonItem && q.musician.key == musician.key),
        ),
      ];
      _drag = Offset.zero;
    });
  }

  Future<void> _showMatch(Musician m, String matchId) async {
    final open = _openSlotFor(m);
    final filledSlot = open >= 0;
    // Who has this role already, if no slot of it is open.
    final holder = _band
        .where((s) => s.role == m.instrumentId)
        .firstOrNull
        ?.member;
    if (filledSlot) {
      setState(() {
        _members = [..._members, (name: m.name, role: m.instrumentId)];
        _rebuildBand();
        _justFilled = open;
      });
    }
    final saidHi = await showDialog<bool>(
      context: context,
      builder: (context) => _MatchDialog(
        title: context.t.matchTitle(m.name),
        body: filledSlot
            ? context.t.matchSlotFilled(m.instrument)
            : holder == null
            ? context.t.matchNoSlot(m.instrument.toLowerCase())
            : holder == youMarker
            ? context.t.matchSlotYours(m.instrument.toLowerCase())
            : context.t.matchSlotTaken(holder, m.instrument.toLowerCase()),
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

  /// A short message at the bottom. With [onUndo] it has an Undo button
  /// and stays for 3 s.
  void _toast(String message, {VoidCallback? onUndo}) {
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
          duration: Duration(milliseconds: onUndo == null ? 2400 : 3000),
          // Flutter keeps a snack bar with a button up until it's tapped;
          // the Undo offer should go away by itself after 3 s.
          persist: false,
          action: onUndo == null
              ? null
              : SnackBarAction(
                  label: context.t.undo,
                  textColor: OctavaColors.pink,
                  onPressed: onUndo,
                ),
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
        _queue = _queue
            .where((q) => !(q is PersonItem && q.musician.key == m.key))
            .toList();
        _drag = Offset.zero;
      });
    }
  }

  /// The swipe's result (a match id, or null), or the error to show.
  Future<Object?> _attempt(Future<Object?> swipe) async {
    try {
      return await swipe;
    } on UserFacingException catch (e) {
      return e;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        // Space the wordmark doesn't use goes in the middle,
                        // so the filter pill stays at the right edge.
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // The wordmark gives way first on narrow screens.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const OctavaLogo(
                                height: 44,
                                spinning: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              // The summary is also the way into the filters:
                              // a yellow printed pill.
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 8,
                                children: [
                                  const _ThemeButton(),
                                  Flexible(
                                    child: _FilterPill(
                                      label: _filters.describe(
                                        hasLocation: _hasLocation,
                                      ),
                                      onTap: _loading ? null : _openFilters,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BandLineup(
                        band: _band,
                        justFilled: _justFilled,
                        onEdit: _editBand,
                      ),
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
                              // Seen everyone: the best fix for an empty
                              // feed is bringing friends in.
                              return _DeckMessage(
                                title: context.t.heardEveryoneTitle,
                                body: context.t.heardEveryoneBody,
                                main: context.t.inviteMusicians,
                                onMain: inviteMusicians,
                                action: context.t.changeFilters,
                                onAction: _openFilters,
                                extra: context.t.checkAgain,
                                onExtra: _reload,
                              );
                            }
                            return _buildDeck();
                          },
                        ),
                      ),
                      if (widget.onOpenProfile != null ||
                          widget.onOpenMatches != null ||
                          widget.onRecord != null) ...[
                        // The bar floats in the middle of the space between
                        // the card and the screen's bottom: 10 px of clear
                        // space each side (the card's shadow is 4 px, the
                        // bar's 3 px; the bottom gap is the screen padding).
                        const SizedBox(height: 14),
                        _BottomBar(
                          onProfile: widget.onOpenProfile == null
                              ? null
                              : () async {
                                  await widget.player?.stop();
                                  await widget.onOpenProfile!();
                                  if (mounted) _reload();
                                },
                          onMatches: widget.onOpenMatches,
                          live: widget.live,
                          bands: widget.bands,
                          onRecord: widget.onRecord == null
                              ? null
                              : () async {
                                  await widget.player?.stop();
                                  widget.onRecord!();
                                },
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

  /// A deck card: a musician or a band, with drag stamps on the top one.
  Widget _card(DeckItem item, {bool top = false}) => switch (item) {
    PersonItem(:final musician) => MusicianCard(
      key: ValueKey(item.key),
      musician: musician,
      tone: _toneFor(musician),
      fitsOpenSlot: _fitsOpenSlot(musician),
      jamStamp: top ? _drag.dx / 90 : 0,
      passStamp: top ? -_drag.dx / 90 : 0,
      onSafety: !top || widget.safety == null
          ? null
          : () => _openSafety(musician),
      player: top ? widget.player : null,
      avatars: widget.avatars,
    ),
    BandItem(:final band) => BandCard(
      key: ValueKey(item.key),
      band: band,
      jamStamp: top ? _drag.dx / 90 : 0,
      passStamp: top ? -_drag.dx / 90 : 0,
      player: top ? widget.player : null,
    ),
  };

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
                  child: Transform.scale(scale: 0.96, child: _card(next)),
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
              onPanDown: (_) => _stopHint(),
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
              child: Transform.translate(
                offset: _drag,
                child: Transform.rotate(
                  angle: _drag.dx / 18 * pi / 180,
                  child: _card(top, top: true),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _hinting ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              onEnd: () {
                if (!_hinting && _hintShown) {
                  setState(() {
                    _hintShown = false;
                  });
                }
              },
              // Built only while the hint shows, so it never sits
              // invisibly over the card afterwards.
              child: _hintShown ? _SwipeHint(dx: _drag.dx) : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// The first-time hint over the top card: a hand that moves with the card,
/// and a caption saying which way is Jam and which is Pass.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.dx});

  /// The card's current offset; the hand follows it.
  final double dx;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    BoxDecoration pill() => printBox(
      context,
      color: OctavaColors.yellow,
      radius: 999,
      shadow: 3,
      borderColor: OctavaColors.ink,
    );
    return Column(
      children: [
        const Spacer(flex: 5),
        ExcludeSemantics(
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Container(
              width: 64,
              height: 64,
              decoration: pill(),
              child: const Icon(
                Icons.touch_app_rounded,
                size: 34,
                color: OctavaColors.ink,
              ),
            ),
          ),
        ),
        const Spacer(flex: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pill(),
            child: Text(
              t.swipeHint(t.stampJam, t.stampPass),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OctavaColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
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
    this.main,
    this.onMain,
    this.extra,
    this.onExtra,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  /// An optional main action above [action], as a pink button. It gets the
  /// button's own context (the share sheet anchors to it on iPads).
  final String? main;
  final ValueChanged<BuildContext>? onMain;

  /// An optional quiet action under [action].
  final String? extra;
  final VoidCallback? onExtra;

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
          if (main != null && onMain != null)
            Builder(
              builder: (context) => PrintButton(
                onPressed: () => onMain!(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const Icon(Icons.group_add_outlined),
                    Flexible(
                      child: Text(main!, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton(onPressed: onAction, child: Text(action)),
          if (extra != null && onExtra != null)
            TextButton(onPressed: onExtra, child: Text(extra!)),
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

/// Bottom navigation as a floating pill, like Instagram's: Profile, a pink
/// ➕ (record a clip) and Matches, icons only. Their names are tooltips
/// (long-press) and what screen readers say.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    this.onProfile,
    this.onMatches,
    this.onRecord,
    this.live,
    this.bands,
  });

  /// For band invites, votes and unread band messages, also on Matches.
  final LiveBands? bands;

  /// For the unread count on Matches.
  final LiveUpdates? live;
  final VoidCallback? onProfile;
  final VoidCallback? onMatches;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    // As wide as the card above it, with room around it so it floats.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: printBox(context, radius: 999, shadow: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onProfile != null)
            _BarButton(
              icon: Icons.person_outline_rounded,
              label: context.t.navProfile,
              onTap: onProfile!,
            ),
          if (onRecord != null)
            // Pink on a yellow hard shadow, like the design's main key.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: hardShadow(OctavaColors.yellow, offset: 2),
              ),
              child: Tooltip(
                message: context.t.navAdd,
                child: FilledButton(
                  onPressed: onRecord,
                  style: FilledButton.styleFrom(
                    backgroundColor: OctavaColors.pink,
                    foregroundColor: OctavaColors.ink,
                    minimumSize: const Size(60, 36),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.mic_rounded, size: 24),
                ),
              ),
            ),
          if (onMatches != null)
            ListenableBuilder(
              listenable: Listenable.merge([?live, ?bands]),
              builder: (context, _) => _BarButton(
                icon: Icons.headphones_outlined,
                label: context.t.navMatches,
                onTap: onMatches!,
                badge: (live?.unreadTotal ?? 0) + (bands?.badgeCount ?? 0),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sun or moon: one tap switches between light and dark. ("Device", which
/// follows the phone, is in the profile's Theme section.)
class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: printBox(context, radius: 999, shadow: 2),
      child: IconButton(
        tooltip: dark ? t.themeToLight : t.themeToDark,
        visualDensity: VisualDensity.compact,
        onPressed: () =>
            appTheme.choose(dark ? ThemeMode.light : ThemeMode.dark),
        icon: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 20,
        ),
      ),
    );
  }
}

/// The filter summary as a yellow pill with a hard shadow.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: printBox(
              context,
              color: OctavaColors.yellow,
              radius: 999,
              shadow: 2,
              borderColor: OctavaColors.ink,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: OctavaColors.ink,
                ),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: OctavaColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;

  /// Shown as a tooltip and read by screen readers.
  final String label;
  final VoidCallback onTap;

  /// A count shown on the icon when above 0.
  final int badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 25,
      color: colors.onSurface,
      icon: Badge(
        isLabelVisible: badge > 0,
        label: Text(badge > 99 ? '99+' : '$badge'),
        backgroundColor: OctavaColors.pink,
        textColor: OctavaColors.ink,
        child: Icon(icon),
      ),
    );
  }
}
