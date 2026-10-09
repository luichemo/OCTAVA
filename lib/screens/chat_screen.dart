import 'package:flutter/material.dart';

import '../data/chat_repository.dart';
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
  });

  final ChatRepository repository;
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
  void dispose() {
    _input.dispose();
    super.dispose();
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
          if (widget.safety != null)
            IconButton(
              tooltip: 'Block or report',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () async {
                final blocked = await showSafetyOptions(
                  context,
                  safety: widget.safety!,
                  userId: widget.otherUserId,
                  name: widget.name,
                );
                // A blocked chat is closed; the Matches list no longer shows it.
                if (blocked && context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: displayStyle(size: 28, color: colors.onSurface),
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
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              "Couldn't load messages. Check your connection, then go back and open the chat again.",
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
                              'You and ${widget.name} both want to jam. Say hi and plan a first rehearsal.',
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
                          return _Bubble(
                            message: message,
                            mine: message.senderId == widget.repository.myId,
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
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            counterText: '',
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Send',
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
                formatMessageTime(message.sentAt),
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
