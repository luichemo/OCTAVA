import 'dart:math';

import 'package:flutter/material.dart';

/// On anything wider than a phone (iPad, laptop, desktop) the app keeps its
/// phone layout, centred, and grows with the screen (owner, 2026-10-22:
/// a centred column rather than multi-pane layouts, which felt too busy,
/// and it should grow on bigger screens rather than stay a small column).
///
/// The layout is always this many logical pixels wide...
const phoneColumnWidth = 480.0;

/// ...and is scaled up so that it's about this tall, since the feed is a
/// tall layout. A short laptop screen grows it only a little; a tall
/// desktop monitor or a portrait iPad grows it more.
const phoneColumnHeight = 760.0;

/// The largest scale, so it doesn't turn into a poster on huge screens.
const maxColumnScale = 1.6;

/// How much the phone layout is scaled on a screen of [size]: by height,
/// leaving a margin at the sides, never below 1 and at most
/// [maxColumnScale].
double columnScale(Size size) {
  final byWidth = size.width * 0.92 / phoneColumnWidth;
  final byHeight = size.height / phoneColumnHeight;
  return min(byWidth, byHeight).clamp(1.0, maxColumnScale);
}

/// Shows [child] as a centred phone layout on screens wider than a phone,
/// scaled by [columnScale]. Inside, the layout sees a [phoneColumnWidth]-
/// wide screen (its own MediaQuery: size, safe-area padding and keyboard
/// divided by the scale), so it lays out exactly as on a phone; pages,
/// dialogs and sheets open inside it and grow with it. Text and icons stay
/// sharp, because the scaled layout is drawn at the larger size.
class PhoneColumn extends StatelessWidget {
  const PhoneColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width <= phoneColumnWidth) return child;
    final scale = columnScale(size);
    final inner = Size(phoneColumnWidth, size.height / scale);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SizedBox(
          width: phoneColumnWidth * scale,
          height: size.height,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: inner,
              child: MediaQuery(
                data: media.copyWith(
                  size: inner,
                  // Images pick a sharper resolution for the bigger size.
                  devicePixelRatio: media.devicePixelRatio * scale,
                  padding: media.padding / scale,
                  viewPadding: media.viewPadding / scale,
                  viewInsets: media.viewInsets / scale,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
