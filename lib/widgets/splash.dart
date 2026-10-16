import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'web_splash.dart';

/// Becomes true once the app's first real screen can show (sign-in, the
/// profile form, the swipe screen, an error, or a public band page). The
/// splash waits for it; see [markAppReady].
final appReady = ValueNotifier<bool>(false);

/// Tells the splash the app is ready (after this frame, so it's safe to
/// call while building). On the web this also removes the page's own
/// splash (web/index.html).
void markAppReady() {
  if (appReady.value) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    appReady.value = true;
    removeWebSplash();
  });
}

/// The animated logo while the app starts, only when it's needed.
///
/// For the first [delay] it shows just the background (the same colour as
/// the phone's launch screen); if the app is [ready] by then, it simply
/// fades away. Otherwise the record "O" spins up while the OCTAVA letters
/// slide in, then slows and cross-fades into the real logo, which stays
/// until the app is ready. When the app becomes ready mid-animation, the
/// animation hurries to its end. [child] is built underneath from the
/// start, so loading carries on meanwhile. With "reduce motion" on, the
/// logo shows without moving.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    required this.ready,
    this.delay = const Duration(milliseconds: 800),
  });

  final Widget child;
  final ValueListenable<bool> ready;
  final Duration delay;

  /// The whole animation.
  static const duration = Duration(milliseconds: 1600);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

enum _Stage { waiting, animating, leaving, gone }

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SplashGate.duration,
  );
  var _stage = _Stage.waiting;
  Timer? _timer;
  Future<void>? _logoLoaded;

  @override
  void initState() {
    super.initState();
    widget.ready.addListener(_onReady);
    _timer = Timer(widget.delay, _start);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.ready.value) _leave();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the logo now, so the animation's first frames don't stall.
    _logoLoaded ??= precacheImage(SplashLogo.image, context);
  }

  Future<void> _start() async {
    if (_stage != _Stage.waiting) return;
    if (widget.ready.value) return _leave();
    await _logoLoaded;
    if (!mounted || _stage != _Stage.waiting) return;
    if (widget.ready.value) return _leave();
    setState(() {
      _stage = _Stage.animating;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  void _onReady() {
    if (!widget.ready.value) return;
    switch (_stage) {
      case _Stage.waiting:
        _leave();
      case _Stage.animating:
        if (_controller.isCompleted) {
          _leave();
        } else {
          // Hurry to the settled logo, then go.
          _controller
              .animateTo(1, duration: const Duration(milliseconds: 350))
              .whenComplete(_leave);
        }
      case _Stage.leaving || _Stage.gone:
        break;
    }
  }

  void _leave() {
    _timer?.cancel();
    if (!mounted || _stage == _Stage.leaving || _stage == _Stage.gone) return;
    setState(() {
      _stage = _Stage.leaving;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.ready.removeListener(_onReady);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_stage != _Stage.gone)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _stage == _Stage.leaving,
              child: AnimatedOpacity(
                opacity: _stage == _Stage.leaving ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                onEnd: () {
                  if (_stage == _Stage.leaving) {
                    setState(() {
                      _stage = _Stage.gone;
                    });
                  }
                },
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _stage == _Stage.waiting
                      ? const SizedBox.expand()
                      : Center(child: SplashLogo(animation: _controller)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The logo at a point in the splash animation (0 → 1).
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, required this.animation});

  final Animation<double> animation;

  static const image = AssetImage('assets/images/logo.png');

  // Where the record "O" sits in logo.png (410 × 174).
  static const _logoW = 410.0;
  static const _logoH = 174.0;
  static const _record = Rect.fromLTWH(15, 26, 86, 138);

  /// Where the letters start (everything right of the record).
  static const _lettersFrom = 103.0;

  static const _appear = Interval(0, 0.28, curve: Curves.easeOutBack);
  static const _fadeIn = Interval(0, 0.15);
  static const _letters = Interval(0.2, 0.55, curve: Curves.easeOutCubic);
  static const _spin = Interval(0, 0.8, curve: Curves.easeInOutCubic);
  static const _toLogo = Interval(0.8, 0.95);

  /// Whole turns, so the grooves end where the logo's are.
  static const _turns = 4;

  @override
  Widget build(BuildContext context) {
    final width = min(MediaQuery.sizeOf(context).width * 0.72, 340.0);
    final s = width / _logoW;
    final logo = Image(
      image: image,
      width: width,
      height: _logoH * s,
      fit: BoxFit.fill,
      gaplessPlayback: true,
    );
    final recordSize = Size(_record.width * s, _record.height * s);
    // Drawn once and cached: each frame only moves, turns or fades it.
    final record = RepaintBoundary(child: _Record(size: recordSize));
    return Semantics(
      label: 'OCTAVA',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: _logoH * s,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = animation.value;
              final letters = _letters.transform(t);
              final toLogo = _toLogo.transform(t);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // The letters slide in from the right.
                  Positioned.fill(
                    child: Opacity(
                      opacity: letters,
                      child: Transform.translate(
                        offset: Offset((1 - letters) * 48 * s, 0),
                        child: ClipRect(
                          clipper: _Columns(from: _lettersFrom * s),
                          child: logo,
                        ),
                      ),
                    ),
                  ),
                  // The real record "O", once the drawn one has stopped.
                  if (toLogo > 0)
                    Positioned.fill(
                      child: Opacity(
                        opacity: toLogo,
                        child: ClipRect(
                          clipper: _Columns(to: _lettersFrom * s),
                          child: logo,
                        ),
                      ),
                    ),
                  if (toLogo < 1)
                    Positioned(
                      left: _record.left * s,
                      top: _record.top * s,
                      width: recordSize.width,
                      height: recordSize.height,
                      child: Opacity(
                        opacity: _fadeIn.transform(t) * (1 - toLogo),
                        child: Transform.scale(
                          scale: 0.5 + 0.5 * _appear.transform(t),
                          child: _Spinning(
                            size: recordSize,
                            angle: _spin.transform(t) * _turns * 2 * pi,
                            child: record,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Clips to the columns between [from] and [to] (in pixels).
class _Columns extends CustomClipper<Rect> {
  const _Columns({this.from = 0, this.to = double.infinity});
  final double from;
  final double to;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(from, -size.height, min(to, size.width), size.height * 2);

  @override
  bool shouldReclip(_Columns old) => old.from != from || old.to != to;
}

// The logo's record colours.
const _navy = Color(0xFF233065);
const _groove = Color(0xFFE8EBF8);

/// The logo's record "O" at [size], turned to [angle]: the rim and inside
/// stay put and only the grooves turn. The grooves are drawn once (a
/// RepaintBoundary), so turning them is cheap.
class SpinningRecord extends StatelessWidget {
  const SpinningRecord({super.key, required this.size, required this.angle});

  final Size size;
  final double angle;

  /// Where the record sits in logo.png (410 × 174).
  static const inLogo = SplashLogo._record;

  @override
  Widget build(BuildContext context) => _Spinning(
    size: size,
    angle: angle,
    child: RepaintBoundary(child: _Record(size: size)),
  );
}

/// The record's rim (pink) and inside (navy), with the turning [child]
/// (the grooves) clipped to the inside.
class _Spinning extends StatelessWidget {
  const _Spinning({
    required this.size,
    required this.angle,
    required this.child,
  });

  final Size size;
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rim = size.width * 0.08;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OctavaColors.pink,
        borderRadius: BorderRadius.circular(size.width / 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(rim),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size.width / 2 - rim),
          child: ColoredBox(
            color: _navy,
            child: OverflowBox(
              maxWidth: size.height,
              maxHeight: size.height,
              child: Transform.rotate(angle: angle, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The grooves and label, on a square as tall as the record.
class _Record extends StatelessWidget {
  const _Record({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size.height),
    painter: RecordPainter(recordWidth: size.width),
  );
}

/// White groove arcs above and below a white label (gaps at the sides),
/// centred on a square canvas; sized from the record's width.
class RecordPainter extends CustomPainter {
  const RecordPainter({required this.recordWidth});

  final double recordWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = recordWidth;
    final label = w * 0.2;
    canvas.translate(size.width / 2, size.height / 2);
    final groove = Paint()
      ..color = _groove
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    for (var r = label * 1.7; r < size.height / 2; r += w * 0.065) {
      final box = Rect.fromCircle(center: Offset.zero, radius: r);
      const sweep = pi * 0.62;
      canvas.drawArc(box, -pi / 2 - sweep / 2, sweep, false, groove);
      canvas.drawArc(box, pi / 2 - sweep / 2, sweep, false, groove);
    }
    // The label, with a small mark that turns with it.
    canvas.drawCircle(Offset.zero, label, Paint()..color = _groove);
    canvas.drawCircle(
      Offset.zero,
      label * 0.72,
      Paint()
        ..color = _navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025,
    );
    canvas.drawCircle(
      Offset(0, -label * 0.72),
      w * 0.03,
      Paint()..color = OctavaColors.pink,
    );
    canvas.drawCircle(Offset.zero, w * 0.055, Paint()..color = _navy);
  }

  @override
  bool shouldRepaint(RecordPainter old) => old.recordWidth != recordWidth;
}
