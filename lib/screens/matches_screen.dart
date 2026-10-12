import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/avatar_repository.dart';
import '../data/chat_repository.dart';
import '../data/live_updates.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../models/chat.dart';
import '../theme.dart';
import '../widgets/person_avatar.dart';
import 'chat_screen.dart';

/// Everyone you've matched with, newest activity first, updated live.
/// Tap one to chat.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
    required this.repository,
    this.live,
    this.safety,
    this.avatars,
  });

  /// Shows people's AI avatars. Without it, their initial.
  final AvatarRepository? avatars;

  final ChatRepository repository;

  /// The session's live matches. Without it the screen makes its own.
  final LiveUpdates? live;

  /// Passed on to chats for block and report.
  final SafetyRepository? safety;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // `widget.live ?? ...`: use the shared one, or own a private one.
  late final LiveUpdates _live =
      widget.live ?? (LiveUpdates(widget.repository)..start());

  @override
  void dispose() {
    if (widget.live == null) _live.dispose();
    super.dispose();
  }

  Future<void> _open(MatchSummary match) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          repository: widget.repository,
          live: _live,
          matchId: match.matchId,
          otherUserId: match.otherUserId,
          safety: widget.safety,
          name: match.name,
          instrument: match.instrument,
        ),
      ),
    );
    // Blocking in the chat removes it from the list.
    if (mounted) _live.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          context.t.navMatches,
          style: displayStyle(size: 32, color: colors.onSurface),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: _live,
            builder: (context, _) {
              final matches = _live.matches;
              final error = _live.error;
              if (error != null && matches == null) {
                return _Message(
                  text: error is UserFacingException
                      ? error.message
                      : context.t.errLoadMatches,
                  action: context.t.tryAgain,
                  onAction: _live.refresh,
                );
              }
              if (matches == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (matches.isEmpty) {
                return _Message(text: context.t.matchesEmpty);
              }
              return RefreshIndicator(
                onRefresh: _live.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: matches.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outlineVariant),
                  itemBuilder: (context, i) => _MatchTile(
                    match: matches[i],
                    avatars: widget.avatars,
                    onTap: () => _open(matches[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.onTap, this.avatars});

  final MatchSummary match;
  final AvatarRepository? avatars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = match.unreadCount > 0;
    final preview = match.lastMessage == null
        ? context.t.newMatchSayHi
        : (match.lastMessageIsMine
              ? context.t.youPrefix(match.lastMessage!)
              : match.lastMessage!);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: PersonAvatar(
        name: match.name,
        avatarPath: match.avatarPath,
        avatars: avatars,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: match.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: '  ${match.instrument}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatMessageTime(match.lastActivity),
            style: TextStyle(
              fontSize: 13,
              color: unread ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
      trailing: unread
          ? Badge(
              label: Text('${match.unreadCount}'),
              backgroundColor: OctavaColors.pink,
              textColor: OctavaColors.ink,
            )
          : null,
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: match.lastMessage == null || unread
              ? colors.onSurface
              : colors.onSurfaceVariant,
          fontWeight: match.lastMessage == null || unread
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (action != null)
            OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
