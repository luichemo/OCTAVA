import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/repositories.dart';
import '../theme.dart';

/// Your avatar, with a button to make a new one from your profile.
class AvatarSection extends StatefulWidget {
  const AvatarSection({super.key, required this.avatars});

  final AvatarRepository avatars;

  @override
  State<AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends State<AvatarSection> {
  String? _path;
  bool _loading = true;
  bool _generating = false;
  int? _remaining;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final path = await widget.avatars.myAvatarPath();
      if (mounted) {
        setState(() {
          _path = path;
        });
      }
    } on UserFacingException {
      // No avatar shown; generating still works.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _generate() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _generating = true;
    });
    try {
      final result = await widget.avatars.generate();
      if (mounted) {
        setState(() {
          _path = result.path;
          _remaining = result.remaining;
        });
      }
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final path = _path;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: OctavaColors.pinkTint,
              border: Border.all(color: colors.outlineVariant, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _generating || _loading
                ? const Center(child: CircularProgressIndicator())
                : path == null
                ? Icon(
                    Icons.person_outline_rounded,
                    size: 56,
                    color: colors.onSurfaceVariant,
                  )
                : AvatarImage(avatars: widget.avatars, path: path),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                _generating
                    ? 'Painting your avatar… this takes a few seconds.'
                    : 'A riso-print illustration made by AI from your main instrument and genres.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              OutlinedButton.icon(
                onPressed: _generating || _loading ? null : _generate,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  path == null ? 'Generate my avatar' : 'Make a new one',
                ),
              ),
              if (_remaining != null)
                Text(
                  _remaining == 1 ? '1 more today' : '$_remaining more today',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows an avatar from the private bucket (fetches a signed link first).
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.avatars,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final AvatarRepository avatars;
  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: avatars.imageUrl(path),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) return const SizedBox.expand();
        return Image.network(
          url,
          key: ValueKey(path),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          // Fade in over the halftone pattern instead of popping in.
          frameBuilder: (context, child, frame, wasSync) => AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: child,
          ),
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        );
      },
    );
  }
}
