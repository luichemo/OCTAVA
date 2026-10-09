import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../data/deck.dart';
import '../data/repositories.dart';
import '../models/musician.dart';
import '../theme.dart';
import '../widgets/band_lineup.dart';
import '../widgets/musician_card.dart';

/// The main screen: your band lineup, a deck of musician cards to drag or
/// tap through, and Pass / Jam buttons.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    super.key,
    this.source = const SampleDeck(),
    this.onSignOut,
    this.onOpenMatches,
    this.onOpenChat,
  });

  /// Where people come from and swipes go.
  final DeckSource source;

  /// Shows a Sign out button when set.
  final VoidCallback? onSignOut;

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
    try {
      // Both requests run at the same time, like Promise.all.
      final (band, deck) = await (
        widget.source.loadLineup(),
        widget.source.loadDeck(),
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
        _loadError = error?.message ?? "Couldn't load musicians. Try again.";
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

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool _fitsOpenSlot(Musician m) =>
      _band.containsKey(m.instrument) && _band[m.instrument] == null;

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
        'Passed on ${musician.name}.',
        TextDirection.ltr,
      );
    } else if (matchId != null) {
      await _showMatch(musician, matchId);
    } else {
      _toast('You asked ${musician.name} to jam');
    }
  }

  Future<void> _showMatch(Musician m, String matchId) async {
    final filledSlot = _fitsOpenSlot(m);
    final holder = _band[m.instrument];
    if (filledSlot) {
      setState(() {
        _band[m.instrument] = m.name;
        _justFilled = m.instrument;
      });
    }
    final saidHi = await showDialog<bool>(
      context: context,
      builder: (context) => _MatchDialog(
        title: '${m.name} wants to jam too',
        body: filledSlot
            ? '${m.instrument} is now filled in your band. Say hi and plan a first rehearsal.'
            : '$holder already plays ${m.instrument.toLowerCase()} in your band, but you can still say hi.',
      ),
    );
    if (saidHi != true || !mounted) return;
    final openChat = widget.onOpenChat;
    if (openChat != null) {
      openChat(matchId, m);
    } else {
      _toast('You said hi to ${m.name}');
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
                            child: Text(
                              widget.source.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.onOpenMatches != null)
                            IconButton(
                              tooltip: 'Matches',
                              onPressed: widget.onOpenMatches,
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                              color: colors.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                            ),
                          if (widget.onSignOut != null)
                            IconButton(
                              tooltip: 'Sign out',
                              onPressed: widget.onSignOut,
                              icon: const Icon(Icons.logout_rounded),
                              color: colors.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      BandLineup(band: _band, justFilled: _justFilled),
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
                                title: 'Something went wrong',
                                body: _loadError!,
                                action: 'Try again',
                                onAction: _reload,
                              );
                            }
                            if (_queue.isEmpty) {
                              return _DeckMessage(
                                title: "You've heard everyone",
                                body: "That's everyone for now. New musicians join every week.",
                                action: 'Check again',
                                onAction: _reload,
                              );
                            }
                            return _buildDeck();
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 14,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canSwipe
                                  ? () => _decide(Decision.pass)
                                  : null,
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Pass'),
                            ),
                          ),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: canSwipe
                                  ? () => _decide(Decision.jam)
                                  : null,
                              icon: const Icon(Icons.music_note_rounded),
                              label: const Text('Jam'),
                            ),
                          ),
                        ],
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Drag the card, or use the left and right arrow keys',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
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
                child: const Text('Say hi'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep swiping'),
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
