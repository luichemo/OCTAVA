import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:url_launcher/url_launcher.dart';

import '../config/links.dart';
import '../data/avatar_repository.dart';
import '../data/band_repository.dart';
import '../data/clip_repository.dart';
import '../data/location_repository.dart';
import '../data/moderation_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../data/theme_setting.dart';
import '../models/profile_draft.dart';
import '../theme.dart';
import '../widgets/avatar_section.dart';
import '../widgets/band_roles_sheet.dart';
import '../widgets/clips_section.dart';
import '../widgets/invite.dart';
import '../widgets/language_picker.dart';
import '../widgets/location_section.dart';
import '../widgets/record_sheet.dart';
import '../widgets/theme_picker.dart';
import 'card_preview_screen.dart';
import 'moderation_screen.dart';
import 'moderators_screen.dart';
import 'onboarding_screen.dart';

/// Your profile page (owner's design, 2026-10-19): your avatar, name and
/// main instrument centred at the top (an eye icon at the end of the app bar
/// shows your card), then a plain list.
/// Each row shows a one-line summary and opens its section on its own page:
/// the form sections (About you, What you play, What you want, Links) open
/// the profile form showing just that section, with Save changes; the rest
/// (avatar, clips, band needs, location, language, theme) save as you go.
/// Sign out and Delete account (asks first) are the last rows.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.repository,
    this.clips,
    this.player,
    this.avatars,
    this.location,
    this.bandNeeds,
    this.onSignOut,
    this.moderation,
  });

  /// For moderators: a Moderation group with Reports.
  final ModerationRepository? moderation;

  final ProfileRepository repository;
  final ClipRepository? clips;
  final ClipPlayer? player;
  final AvatarRepository? avatars;
  final LocationRepository? location;
  final BandNeedsRepository? bandNeeds;
  final VoidCallback? onSignOut;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late Future<ProfileDraft> _profile = widget.repository.loadMyProfile();
  String? _avatarPath;

  /// Null until counted; 0 shows the "hidden from the feed" warning.
  int? _clipCount;

  /// Moderators see Reports with the number of open ones.
  bool _moderator = false;
  bool _admin = false;
  int? _openReports;
  int? _moderatorCount;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  @override
  void dispose() {
    // Don't keep playing a clip from this screen after leaving it.
    widget.player?.stop();
    super.dispose();
  }

  Future<void> _loadExtras() async {
    try {
      final path = await widget.avatars?.myAvatarPath();
      if (mounted) {
        setState(() {
          _avatarPath = path;
        });
      }
    } catch (_) {
      // The header just shows the initial instead.
    }
    if (widget.moderation case final moderation?) {
      final moderator = await moderation.isModerator();
      final admin = moderator && await moderation.isAdmin();
      int? open;
      int? mods;
      if (moderator) {
        try {
          open = (await moderation.openReports()).length;
          if (admin) mods = (await moderation.moderators()).length;
        } on UserFacingException {
          // The rows still open their pages, which show the error.
        }
      }
      if (mounted) {
        setState(() {
          _moderator = moderator;
          _admin = admin;
          _openReports = open;
          _moderatorCount = mods;
        });
      }
    }
    try {
      final clips = await widget.clips?.myClips();
      if (mounted && clips != null) {
        setState(() {
          _clipCount = clips.length;
        });
      }
    } catch (_) {
      // No warning is better than a wrong one.
    }
  }

  void _reload() {
    setState(() {
      _profile = widget.repository.loadMyProfile();
    });
    _loadExtras();
  }

  /// One section of the profile form, on its own page.
  Future<void> _openForm(ProfileDraft profile, String section) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.t.profileSaved;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          repository: widget.repository,
          needsBirthDate: false,
          initial: profile,
          only: section,
          onDone: () {
            messenger.showSnackBar(SnackBar(content: Text(saved)));
            navigator.pop();
          },
        ),
      ),
    );
    if (mounted) _reload();
  }

  /// A section that saves as you go, on its own page.
  Future<void> _openPage(String section, Widget child) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(sectionTitle(context, section))),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [child],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) _reload();
  }

  /// Asks first, then deletes the account on the server. On success the
  /// app is signed out, so it goes back to sign-in.
  Future<void> _deleteAccount() async {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteAccountTitle),
        content: Text(t.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
              side: BorderSide(color: colors.error, width: 2),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // A spinner that can't be dismissed while the server works.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await widget.repository.deleteAccount();
      // Back to the first screen, which becomes sign-in.
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(SnackBar(content: Text(t.accountDeleted)));
    } on UserFacingException catch (e) {
      navigator.pop(); // the spinner
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _recordClip() async {
    await showRecordSheet(context, clips: widget.clips!);
    if (mounted) _loadExtras();
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
                    onPressed: _reload,
                    child: Text(context.t.tryAgain),
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
        return _page(context, profile);
      },
    );
  }

  Widget _page(BuildContext context, ProfileDraft p) {
    final t = context.t;
    String orEmpty(Iterable<String> parts) {
      final text = parts.where((s) => s.trim().isNotEmpty).join(', ');
      return text.isEmpty ? t.summaryEmpty : text;
    }

    final rows = <_RowData>[
      if (widget.avatars != null)
        _RowData(
          'avatar',
          Icons.face_retouching_natural_outlined,
          null,
          () => _openPage('avatar', AvatarSection(avatars: widget.avatars!)),
        ),
      _RowData(
        'about',
        Icons.person_outline_rounded,
        [p.displayName, p.area].where((s) => s.isNotEmpty).join(' · '),
        () => _openForm(p, 'about'),
      ),
      _RowData(
        'play',
        Icons.music_note_outlined,
        orEmpty(p.instruments.keys.map(instrumentLabel)),
        () => _openForm(p, 'play'),
      ),
      _RowData(
        'want',
        Icons.flag_outlined,
        orEmpty([
          ...p.goals.map((g) => goalLabels[g] ?? g),
          if (p.frequency case final f?) frequencyLabels[f] ?? f,
        ]),
        () => _openForm(p, 'want'),
      ),
      if (widget.clips != null && widget.player != null)
        _RowData(
          'clips',
          Icons.graphic_eq_rounded,
          _clipCount == null ? null : t.clipsCount(_clipCount!),
          () => _openPage(
            'clips',
            ClipsSection(clips: widget.clips!, player: widget.player!),
          ),
        ),
      _RowData(
        'links',
        Icons.link_rounded,
        orEmpty(p.links.map((l) => l.label)),
        () => _openForm(p, 'links'),
      ),
      if (widget.bandNeeds != null)
        _RowData(
          'band',
          Icons.groups_outlined,
          null,
          () => _openPage(
            'band',
            BandNeedsSection(
              repository: widget.bandNeeds!,
              // The first instrument is the main one.
              myRole: p.instruments.keys.firstOrNull,
            ),
          ),
        ),
      if (widget.location != null)
        _RowData(
          'location',
          Icons.place_outlined,
          null,
          () => _openPage(
            'location',
            LocationSection(location: widget.location!),
          ),
        ),
    ];
    final settings = <_RowData>[
      _RowData(
        'language',
        Icons.translate_rounded,
        languageName(context, appLanguage.value),
        () => _openPage('language', const LanguageSection()),
      ),
      _RowData('theme', Icons.contrast_rounded, switch (appTheme.value) {
        ThemeMode.light => t.themeLight,
        ThemeMode.dark => t.themeDark,
        ThemeMode.system => t.languageDevice,
      }, () => _openPage('theme', const ThemeSection())),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: t.seeYourCard,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CardPreviewScreen(
                  repository: widget.repository,
                  player: widget.player,
                  avatars: widget.avatars,
                ),
              ),
            ),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                _Header(
                  profile: p,
                  avatars: widget.avatars,
                  avatarPath: _avatarPath,
                ),
                if (widget.clips != null && _clipCount == 0) ...[
                  const SizedBox(height: 16),
                  NoClipsWarning(onRecord: _recordClip),
                ],
                _Group(
                  title: t.profileGroup,
                  rows: [
                    for (final r in rows)
                      _Row(
                        icon: r.icon,
                        title: sectionTitle(context, r.section),
                        summary: r.summary,
                        onTap: r.onTap,
                      ),
                  ],
                ),
                _Group(
                  title: t.inviteGroup,
                  rows: [
                    Builder(
                      builder: (context) => _Row(
                        icon: Icons.group_add_outlined,
                        title: t.inviteMusicians,
                        summary: t.inviteSummary,
                        onTap: () => inviteMusicians(context),
                      ),
                    ),
                  ],
                ),
                if (_moderator && widget.moderation != null)
                  _Group(
                    title: t.modGroup,
                    rows: [
                      _Row(
                        icon: Icons.flag_outlined,
                        title: t.modReports,
                        summary: _openReports == null
                            ? null
                            : t.modOpenCount(_openReports!),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ModerationScreen(
                                repository: widget.moderation!,
                                player: widget.player,
                                avatars: widget.avatars,
                              ),
                            ),
                          );
                          if (mounted) _loadExtras();
                        },
                      ),
                      if (_admin)
                        _Row(
                          icon: Icons.shield_outlined,
                          title: t.modModerators,
                          summary: _moderatorCount == null
                              ? null
                              : t.modModeratorCount(_moderatorCount!),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ModeratorsScreen(
                                  repository: widget.moderation!,
                                  avatars: widget.avatars,
                                ),
                              ),
                            );
                            if (mounted) _loadExtras();
                          },
                        ),
                    ],
                  ),
                _Group(
                  title: t.settingsGroup,
                  rows: [
                    for (final r in settings)
                      _Row(
                        icon: r.icon,
                        title: sectionTitle(context, r.section),
                        summary: r.summary,
                        onTap: r.onTap,
                      ),
                    _Row(
                      icon: Icons.policy_outlined,
                      title: t.legalPrivacyRow,
                      onTap: () => launchUrl(
                        Uri.parse(privacyUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    _Row(
                      icon: Icons.gavel_rounded,
                      title: t.legalTermsRow,
                      onTap: () => launchUrl(
                        Uri.parse(termsUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    if (widget.onSignOut case final signOut?)
                      _Row(
                        icon: Icons.logout_rounded,
                        title: t.signOut,
                        danger: true,
                        onTap: () {
                          // Back to the first screen, which becomes sign-in.
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          signOut();
                        },
                      ),
                    _Row(
                      icon: Icons.delete_forever_outlined,
                      title: t.deleteAccount,
                      danger: true,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What one row shows and opens.
class _RowData {
  const _RowData(this.section, this.icon, this.summary, this.onTap);
  final String section;
  final IconData icon;
  final String? summary;
  final VoidCallback onTap;
}

/// Avatar (or initial), name and main instrument, centred.
class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.avatars,
    required this.avatarPath,
  });

  final ProfileDraft profile;
  final AvatarRepository? avatars;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = profile.displayName;
    final main = profile.instruments.entries.firstOrNull;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OctavaColors.pinkTint,
            border: Border.all(color: colors.outline, width: 2),
          ),
          alignment: Alignment.center,
          child: avatars != null && avatarPath != null
              ? AvatarImage(avatars: avatars!, path: avatarPath!)
              : Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: displayStyle(
                    size: 40,
                    color: OctavaColors.ink,
                    latin: !hasGeorgian(name),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: displayStyle(
            size: 34,
            color: colors.onSurface,
            latin: !hasGeorgian(name),
          ),
        ),
        if (main != null)
          Text(
            '${instrumentLabel(main.key)} · '
            '${skillLabels[main.value] ?? main.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// A small grey label and a quiet rounded box of rows with thin dividers.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 28, 4, 8),
          child: Text(
            hasGeorgian(title) ? title : title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: hasGeorgian(title) ? 0 : 0.8,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0)
                  Divider(height: 1, indent: 52, color: colors.outlineVariant),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row: an icon, the title, an optional one-line summary, and ›.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.summary,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? summary;
  final VoidCallback onTap;

  /// Sign out: red, no chevron.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = this.summary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
      minLeadingWidth: 22,
      leading: Icon(
        icon,
        size: 22,
        color: danger ? colors.error : colors.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: danger ? colors.error : colors.onSurface,
        ),
      ),
      subtitle: summary == null || summary.isEmpty
          ? null
          : Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
      trailing: danger
          ? null
          : Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
    );
  }
}
