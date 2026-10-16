import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/chat_repository.dart';
import '../data/clip_repository.dart';
import '../data/voice_recorder.dart';
import '../widgets/chat_composer.dart';
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
    this.player,
    this.recorder,
  });

  /// Plays voice messages.
  final ClipPlayer? player;

  /// Makes the voice recorder (tests pass a fake).
  final VoiceRecorder Function()? recorder;

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

  @override
  void initState() {
    super.initState();
    widget.live?.openChat(widget.matchId);
  }

  @override
  void dispose() {
    widget.live?.closeChat(widget.matchId);
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
                              !sameDay(older.sentAt, message.sentAt);
                          // Long-press your own message to edit it.
                          final tappable = GestureDetector(
                            onLongPress: mine
                                ? () => showEditMessage(
                                    context,
                                    message: message,
                                    me: widget.repository.myId,
                                    save: (body) => widget.repository.edit(
                                      message.id,
                                      body,
                                    ),
                                  )
                                : null,
                            child: ChatBubble(
                              message: message,
                              mine: mine,
                              player: widget.player,
                            ),
                          );
                          final bubble = newDay
                              ? Column(
                                  children: [
                                    DayChip(day: message.sentAt),
                                    tappable,
                                  ],
                                )
                              : tappable;
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
                ChatComposer(
                  onSendText: (text) =>
                      widget.repository.send(widget.matchId, text),
                  onSendVoice: (take) => widget.repository.sendVoice(
                    widget.matchId,
                    bytes: take.bytes,
                    fileName: take.fileName,
                    seconds: take.seconds,
                  ),
                  recorder: widget.recorder,
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

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Yesterday" or a date, between messages from different days.
class DayChip extends StatelessWidget {
  const DayChip({super.key, required this.day});

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

/// One message. [sender]: their name above the text, for group chats.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.mine,
    this.sender,
    this.player,
  });

  final ChatMessage message;
  final bool mine;
  final String? sender;

  /// Plays a voice message; without it the play button is disabled.
  final ClipPlayer? player;

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
          // Voice messages are one compact row; text gets more room.
          padding: message.isVoice
              ? const EdgeInsets.fromLTRB(6, 4, 12, 4)
              : const EdgeInsets.fromLTRB(12, 7, 12, 7),
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
          // IntrinsicWidth: as wide as the longest line (name, text or
          // time), so the bubble hugs short messages instead of stretching.
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sender != null)
                  Text(
                    sender!,
                    // Pink text would be too faint on the pale bubble.
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                if (message.audioPath case final path?)
                  _VoiceRow(
                    path: path,
                    seconds: message.audioSeconds ?? 0,
                    mine: mine,
                    player: player,
                    time: formatClock(message.sentAt),
                  )
                else
                  // Text and time in one row, the time at the bottom
                  // right: one compact line for short messages, like voice.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 8,
                    children: [
                      Flexible(
                        child: Text(
                          message.body,
                          style: TextStyle(
                            fontSize: 15,
                            color: mine ? OctavaColors.ink : colors.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          message.editedAt == null
                              ? formatClock(message.sentAt)
                              : context.t.editedAt(formatClock(message.sentAt)),
                          style: TextStyle(
                            fontSize: 11,
                            color: mine
                                ? OctavaColors.ink.withValues(alpha: 0.7)
                                : colors.onSurfaceVariant,
                          ),
                        ),
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

/// Long-press on your own message: Edit (while it can still be edited).
/// [save] sends the new text. Does nothing for messages you can't edit.
Future<void> showEditMessage(
  BuildContext context, {
  required ChatMessage message,
  required String me,
  required Future<void> Function(String body) save,
}) async {
  if (!message.canEdit(me)) return;
  final t = context.t;
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: Text(t.editMessage),
        subtitle: Text(t.editMessageHint),
        onTap: () => Navigator.pop(context, true),
      ),
    ),
  );
  if (choice != true || !context.mounted) return;
  final body = await showDialog<String>(
    context: context,
    builder: (_) => _EditDialog(initial: message.body),
  );
  if (body == null || body.trim() == message.body) return;
  try {
    await save(body);
  } on UserFacingException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initial});
  final String initial;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.editMessage),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 1,
        maxLines: 6,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        ValueListenableBuilder(
          valueListenable: _text,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, value.text),
            child: Text(t.editSave),
          ),
        ),
      ],
    );
  }
}

/// A voice message inside a bubble: play / stop and its length.
class _VoiceRow extends StatelessWidget {
  const _VoiceRow({
    required this.path,
    required this.seconds,
    required this.mine,
    required this.time,
    this.player,
  });

  final String path;
  final int seconds;
  final bool mine;
  final ClipPlayer? player;

  /// When it was sent, at the end of the row.
  final String time;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final ink = mine ? OctavaColors.ink : colors.onSurface;
    final player = this.player;
    Widget button(bool playing) => IconButton(
      tooltip: playing ? t.voiceStop : t.voicePlay,
      onPressed: player == null ? null : () => player.toggle(voiceKey(path)),
      color: ink,
      // Compact: no padding or 48 px tap-target margin around the icon.
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        playing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
        size: 30,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        if (player == null)
          button(false)
        else
          ValueListenableBuilder<String?>(
            valueListenable: player.playing,
            builder: (context, playing, _) => button(playing == voiceKey(path)),
          ),
        Icon(Icons.graphic_eq_rounded, color: ink, size: 20),
        Text(
          clipLength(seconds),
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: mine
                ? OctavaColors.ink.withValues(alpha: 0.7)
                : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
