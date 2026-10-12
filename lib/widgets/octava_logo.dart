import 'package:flutter/material.dart';

/// The OCTAVA logo (vinyl-record "O" and the wordmark), from
/// assets/images/logo.png. Screen readers hear "OCTAVA".
class OctavaLogo extends StatelessWidget {
  const OctavaLogo({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      // Smooth scaling: the file is small, and it's shown at several sizes.
      filterQuality: FilterQuality.medium,
      semanticLabel: 'OCTAVA',
    );
  }
}
