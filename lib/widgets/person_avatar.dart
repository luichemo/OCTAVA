import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../theme.dart';
import 'avatar_section.dart';

/// A round picture of someone: their AI avatar when there is one (and
/// [avatars] is given), otherwise their initial on pink.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.avatarPath,
    this.avatars,
    this.radius = 24,
    this.zoom = 1.8,
  });

  /// How far the avatar is zoomed in (1 = the whole picture).
  final double zoom;

  final String name;
  final String? avatarPath;
  final AvatarRepository? avatars;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = Text(
      name.characters.firstOrNull?.toUpperCase() ?? '',
      style: displayStyle(size: radius * 1.1),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: OctavaColors.pink,
      foregroundColor: OctavaColors.ink,
      child: switch ((avatars, avatarPath)) {
        // The initial shows while the picture loads, then is covered.
        (final avatars?, final path?) => ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              initial,
              // Avatars are whole-figure posters; zoom in on the upper part
              // (the head) so the small circle shows the person, not a scene.
              Transform.scale(
                scale: zoom,
                alignment: const Alignment(0, -0.5),
                child: AvatarImage(avatars: avatars, path: path),
              ),
            ],
          ),
        ),
        _ => initial,
      },
    );
  }
}
