import 'package:flutter/material.dart';

import '../data/location_repository.dart';
import '../data/repositories.dart';

/// Whether you share an approximate location, with buttons to share,
/// update or stop. Saved right away.
class LocationSection extends StatefulWidget {
  const LocationSection({super.key, required this.location});

  final LocationRepository location;

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  bool? _sharing;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.location.hasLocation().then((v) {
      if (mounted) {
        setState(() {
          _sharing = v;
        });
      }
    });
  }

  Future<void> _run(
    Future<void> Function() action, {
    required bool sharing,
    required String done,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
    });
    try {
      await action();
      if (mounted) {
        setState(() {
          _sharing = sharing;
        });
      }
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sharing = _sharing;
    if (sharing == null) return const LinearProgressIndicator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          sharing
              ? "You share an approximate location (to about 1 km). People see how far away you are, never where you are."
              : "You don't share a location, so nobody sees distances to you and distance filters are off.",
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                      widget.location.shareCurrentLocation,
                      sharing: true,
                      done: 'Location saved.',
                    ),
              icon: const Icon(Icons.my_location_rounded),
              label: Text(sharing ? 'Update location' : 'Share location'),
            ),
            if (sharing)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        widget.location.stopSharing,
                        sharing: false,
                        done: 'You no longer share a location.',
                      ),
                child: const Text('Stop sharing'),
              ),
          ],
        ),
      ],
    );
  }
}
