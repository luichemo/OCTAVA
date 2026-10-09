import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/chat_repository.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../models/chat.dart';
import '../theme.dart';
import 'chat_screen.dart';

/// Everyone you've matched with, newest activity first. Tap one to chat.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.repository, this.safety});

  final ChatRepository repository;

  /// Passed on to chats for block and report.
  final SafetyRepository? safety;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late Future<List<MatchSummary>> _matches = widget.repository.loadMatches();

  Future<void> _refresh() async {
    final next = widget.repository.loadMatches();
    setState(() {
      _matches = next;
    });
    await next.catchError((_) => <MatchSummary>[]);
  }

  Future<void> _open(MatchSummary match) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          repository: widget.repository,
          matchId: match.matchId,
          otherUserId: match.otherUserId,
          safety: widget.safety,
          name: match.name,
          instrument: match.instrument,
        ),
      ),
    );
    // New messages change the previews and the order.
    if (mounted) _refresh();
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
          child: FutureBuilder<List<MatchSummary>>(
            future: _matches,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _Message(
                  text: snapshot.error is UserFacingException
                      ? (snapshot.error as UserFacingException).message
                      : context.t.errLoadMatches,
                  action: context.t.tryAgain,
                  onAction: _refresh,
                );
              }
              final matches = snapshot.data;
              if (matches == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (matches.isEmpty) {
                return _Message(text: context.t.matchesEmpty);
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: matches.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outlineVariant),
                  itemBuilder: (context, i) => _MatchTile(
                    match: matches[i],
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
  const _MatchTile({required this.match, required this.onTap});

  final MatchSummary match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = match.lastMessage == null
        ? context.t.newMatchSayHi
        : (match.lastMessageIsMine
              ? context.t.youPrefix(match.lastMessage!)
              : match.lastMessage!);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: OctavaColors.pink,
        foregroundColor: OctavaColors.ink,
        child: Text(
          match.name.characters.first.toUpperCase(),
          style: displayStyle(size: 26),
        ),
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
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: match.lastMessage == null
              ? colors.onSurface
              : colors.onSurfaceVariant,
          fontWeight: match.lastMessage == null
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
