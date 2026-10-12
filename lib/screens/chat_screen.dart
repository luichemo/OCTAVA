import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/chat_repository.dart';
import '../data/live_updates.dart';
import '../data/repositories.dart';
import '../data/safety_repository.dart';
import '../widgets/safety_sheet.dart';
import '../models/chat.dart';
import '../theme.dart';

/// One-on-one chat with a match. New messages arrive live.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.repository,
    required this.matchId,
    required this.otherUserId,
    required this.name,
    required this.instrument,
    this.safety,
    this.live,
  });

  final ChatRepository repository;

  /// Marks the chat read while it's open and provides "Seen".
  final LiveUpdates? live;
  final String matchId;
  final String otherUserId;

  /// Block and report. Without it there's no safety menu.
  final SafetyRepository? safety;
  final String name;
  final String instrument;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Created once, so rebuilding the screen doesn't reconnect.
  late final Stream<List<ChatMessage>> _messages = widget.repository.messages(
    widget.matchId,
  );
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    widget.live?.openChat(widget.matchId);
  }

  @override
  void dispose() {
    widget.live?.closeChat(widget.matchId);
    _input.dispose();
    super.dispose();
  }

  Future<void> _safety() async {
    final blocked = await showSafetyOptions(
      context,
      safety: widget.safety!,
      userId: widget.otherUserId,
      name: widget.name,
    );
    // A blocked chat is closed; the Matches list no longer shows it.
    if (blocked && mounted) Navigator.of(context).pop();
  }

  Future<void> _unmatch() async {
    final t = context.t;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.unmatchTitle(widget.name)),
        content: Text(t.unmatchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.unmatch),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.unmatch(widget.matchId);
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(t.unmatchDone(widget.name))));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
    });
    try {
      await widget.repository.send(widget.matchId, text);
      _input.clear();
    } on UserFacingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        actions: [
          PopupMenuButton<_MenuChoice>(
            tooltip: context.t.chatMore,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (choice) => switch (choice) {
              _MenuChoice.unmatch => _unmatch(),
              _MenuChoice.safety => _safety(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuChoice.unmatch,
                child: Text(context.t.unmatch),
              ),
              if (widget.safety != null)
                PopupMenuItem(
                  value: _MenuChoice.safety,
                  child: Text(context.t.blockOrReport),
                ),
            ],
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: displayStyle(
                size: 28,
                color: colors.onSurface,
                latin: !hasGeorgian(widget.name),
              ),
            ),
            Text(
              widget.instrument,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _messages,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              context.t.chatLoadError,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final messages = snapshot.data;
                      if (messages == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.t.chatEmpty(widget.name),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ),
                        );
                      }
                      // reverse: newest at the bottom, and the list starts there.
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final message = messages[messages.length - 1 - i];
                          final mine =
                              message.senderId == widget.repository.myId;
                          // Messages are listed newest first, so the one
                          // above on screen is at index i + 1.
                          final older = i + 1 < messages.length
                              ? messages[messages.length - 2 - i]
                              : null;
                          final newDay =
                              older == null ||
                              !_sameDay(older.sentAt, message.sentAt);
                          final bubble = newDay
                              ? Column(
                                  children: [
                                    _DayChip(day: message.sentAt),
                                    _Bubble(message: message, mine: mine),
                                  ],
                                )
                              : _Bubble(message: message, mine: mine);
                          // "Seen" goes under your newest message only.
                          if (i != 0 || !mine || widget.live == null) {
                            return bubble;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              bubble,
                              ListenableBuilder(
                                listenable: widget.live!,
                                builder: (context, _) {
                                  final read = widget.live!
                                      .matchById(widget.matchId)
                                      ?.theirLastReadAt;
                                  final seen =
                                      read != null &&
                                      !read.isBefore(message.sentAt);
                                  return seen
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                            bottom: 2,
                                          ),
                                          child: Text(
                                            context.t.seen,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
                  child: Row(
                    spacing: 6,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 2000,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: context.t.messageHint,
                            counterText: '',
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: context.t.send,
                        onPressed: _sending ? null : _send,
                        style: IconButton.styleFrom(
                          backgroundColor: OctavaColors.pink,
                          foregroundColor: OctavaColors.ink,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MenuChoice { unmatch, safety }

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Yesterday" or a date, between messages from different days.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formatDay(day),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
          decoration: BoxDecoration(
            color: mine ? OctavaColors.pink : colors.surfaceContainer,
            border: mine
                ? null
                : Border.all(color: colors.outlineVariant, width: 1.5),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 15,
                  color: mine ? OctavaColors.ink : colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatClock(message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: mine
                      ? OctavaColors.ink.withValues(alpha: 0.7)
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
