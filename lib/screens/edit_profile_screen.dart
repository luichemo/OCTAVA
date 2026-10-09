import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/repositories.dart';
import '../models/profile_draft.dart';
import 'onboarding_screen.dart';

/// Loads your profile, then shows the profile form in edit mode.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.repository,
    this.clips,
    this.player,
  });

  final ProfileRepository repository;
  final ClipRepository? clips;
  final ClipPlayer? player;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late Future<ProfileDraft> _profile = widget.repository.loadMyProfile();

  @override
  void dispose() {
    // Don't keep playing a clip from this screen after leaving it.
    widget.player?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileDraft>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  FilledButton(
                    onPressed: () => setState(() {
                      _profile = widget.repository.loadMyProfile();
                    }),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return OnboardingScreen(
          repository: widget.repository,
          needsBirthDate: false,
          initial: profile,
          clips: widget.clips,
          player: widget.player,
          onDone: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Profile saved.')));
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
