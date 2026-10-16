import 'dart:math';

import 'package:flutter/material.dart';

import 'splash.dart';

/// Whether [OctavaLogo]s with `spinning: true` turn. Tests switch it off
/// (test/flutter_test_config.dart), since an endless animation never lets
/// the screen settle.
bool spinningLogoEnabled = true;

/// The OCTAVA logo (vinyl-record "O" and the wordmark), from
/// assets/images/logo.png. Screen readers hear "OCTAVA".
///
/// With [spinning], the record "O" turns slowly, like a record playing (one
/// turn every [SpinningLogo.turn]); it stands still with "reduce motion",
/// and Flutter pauses it while another screen covers it.
class OctavaLogo extends StatelessWidget {
  const OctavaLogo({super.key, required this.height, this.spinning = false});

  final double height;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      // Smooth scaling: the file is small, and it's shown at several sizes.
      filterQuality: FilterQuality.medium,
      semanticLabel: 'OCTAVA',
    );
    if (!spinning ||
        !spinningLogoEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return image;
    }
    return SpinningLogo(height: height, image: image);
  }
}

/// [image] (the whole logo) with a slowly turning record drawn over its "O".
class SpinningLogo extends StatefulWidget {
  const SpinningLogo({super.key, required this.height, required this.image});

  final double height;
  final Widget image;

  /// One full turn.
  static const turn = Duration(seconds: 6);

  @override
  State<SpinningLogo> createState() => _SpinningLogoState();
}

class _SpinningLogoState extends State<SpinningLogo>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: SpinningLogo.turn,
  )..repeat();

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // logo.png is 410 × 174.
    final s = widget.height / 174;
    const r = SpinningRecord.inLogo;
    final size = Size(r.width * s, r.height * s);
    return SizedBox(
      width: 410 * s,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(child: widget.image),
          Positioned(
            left: r.left * s,
            top: r.top * s,
            width: size.width,
            height: size.height,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, _) =>
                    SpinningRecord(size: size, angle: _turn.value * 2 * pi),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
