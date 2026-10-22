import 'dart:async';

import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/moderation_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/person_avatar.dart';

/// For admins: the current moderators (Remove, which asks first; admins
/// can't be removed), and a search by name to make someone a moderator.
class ModeratorsScreen extends StatefulWidget {
  const ModeratorsScreen({super.key, required this.repository, this.avatars});

  final ModerationRepository repository;
  final AvatarRepository? avatars;

  @override
  State<ModeratorsScreen> createState() => _ModeratorsScreenState();
}

class _ModeratorsScreenState extends State<ModeratorsScreen> {
  final _search = TextEditingController();
  late Future<List<ModPerson>> _moderators = widget.repository.moderators();
  Future<List<ModPerson>>? _results;
  Timer? _debounce;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  /// Searches 300 ms after the last key press.
  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
    setState(() {});
  }

  void _runSearch() {
    if (!mounted) return;
    setState(() {
      _results = _query.length < 2
          ? null
          : widget.repository.findPeople(_query);
    });
  }

  Future<void> _set(ModPerson p, bool make) async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          make
              ? t.modMakeModeratorTitle(p.name)
              : t.modRemoveModeratorTitle(p.name),
        ),
        content: Text(make ? t.modMakeModeratorBody : t.modRemoveModeratorBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(make ? t.modMakeModerator : t.modRemoveModerator),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() {
      _busy = true;
    });
    try {
      await widget.repository.setModerator(p.id, make);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            make ? t.modMadeModerator(p.name) : t.modRemovedModerator(p.name),
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _moderators = widget.repository.moderators();
        if (_results != null) _results = widget.repository.findPeople(_query);
      });
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
    final t = context.t;
    final searching = _query.length >= 2;
    return Scaffold(
      appBar: AppBar(title: Text(t.modModerators)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t.modSearchPeople,
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: t.cancel,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                _onSearch('');
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: searching
                      ? _list(_results, empty: t.modNoOneFound)
                      : _list(
                          _moderators,
                          hint: _search.text.isEmpty ? null : t.modSearchHint,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(Future<List<ModPerson>>? people, {String? empty, String? hint}) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<ModPerson>>(
      future: people,
      builder: (context, snap) {
        if (people == null || snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              snap.error is UserFacingException
                  ? (snap.error as UserFacingException).message
                  : t.errModeration,
              style: TextStyle(color: colors.error),
            ),
          );
        }
        final list = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  hint,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            if (list.isEmpty && empty != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  empty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            for (final p in list) _row(p),
          ],
        );
      },
    );
  }

  Widget _row(ModPerson p) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final subtitle = [
      if (p.instrumentId != null) instrumentLabel(p.instrumentId),
      if (p.age != null) '${p.age}',
      if (p.suspended) t.modSuspended,
    ].join(' · ');
    return ListTile(
      leading: PersonAvatar(
        name: p.name,
        avatarPath: p.avatarPath,
        avatars: widget.avatars,
        radius: 20,
      ),
      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: p.isAdmin
          ? _Pill(text: t.modAdmin, color: OctavaColors.yellow)
          : p.isModerator && _query.length >= 2
          ? _Pill(text: t.modIsModerator, color: OctavaColors.aqua)
          : p.isModerator
          ? TextButton(
              onPressed: () => _set(p, false),
              style: TextButton.styleFrom(foregroundColor: colors.error),
              child: Text(t.modRemoveModerator),
            )
          : p.suspended
          ? null
          : TextButton(
              onPressed: () => _set(p, true),
              child: Text(t.modMakeModerator),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: OctavaColors.ink,
      ),
    ),
  );
}
