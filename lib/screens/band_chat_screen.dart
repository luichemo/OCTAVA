import 'package:flutter/material.dart';

import '../data/avatar_repository.dart';
import '../data/live_bands.dart';
import '../data/live_updates.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../models/band_group.dart';
import '../models/chat.dart';
import '../models/musician.dart' show listJoin;
import '../theme.dart';
import '../widgets/person_avatar.dart';
import 'band_screen.dart';
import 'chat_screen.dart' show ChatBubble, DayChip, sameDay;

/// A band's group chat. Messages arrive live; each shows who sent it, and
/// your newest one says how many bandmates have seen it. While the chat is
/// closed (too few members), the input is replaced by the reason.
class BandChatScreen extends StatefulWidget {
  const BandChatScreen({
    super.key,
    required this.bands,
    required this.bandId,
    this.matches,
    this.avatars,
  });

  final LiveBands bands;
  final String bandId;

  /// Passed on to the members page, for Add member.
  final LiveUpdates? matches;
  final AvatarRepository? avatars;

  @override
  State<BandChatScreen> createState() => _BandChatScreenState();
}

class _BandChatScreenState extends State<BandChatScreen> {
  late final Stream<List<ChatMessage>> _messages = widget.bands.repository
      .messages(widget.bandId);
  final _input = TextEditingController();
  bool _sending = false;

  String get _me => widget.bands.repository.myId;

  @override
  void initState() {
    super.initState();
    widget.bands.openChat(widget.bandId);
  }

  @override
  void dispose() {
    widget.bands.closeChat(widget.bandId);
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
      await widget.bands.repository.send(widget.bandId, text);
      _input.clear();
    } on UserFacingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      // The band may have changed (someone left), so the closed state shows.
      await widget.bands.refresh();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _openMembers() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BandScreen(
        bands: widget.bands,
        bandId: widget.bandId,
        matches: widget.matches,
        avatars: widget.avatars,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.bands,
      builder: (context, _) {
        final band = widget.bands.bandById(widget.bandId);
        final votes = band?.votesWaitingFor(_me) ?? 0;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  band?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: displayStyle(
                    size: 28,
                    color: colors.onSurface,
                    latin: !hasGeorgian(band?.name ?? ''),
                  ),
                ),
                if (band != null)
                  Text(
                    listMembers(band),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: t.bandMembersButton,
                onPressed: _openMembers,
                icon: Badge(
                  isLabelVisible: votes > 0,
                  label: Text('$votes'),
                  backgroundColor: OctavaColors.pink,
                  textColor: OctavaColors.ink,
                  child: const Icon(Icons.groups_rounded),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Expanded(child: _messageList(band)),
                    if (band == null)
                      const SizedBox.shrink()
                    else if (band.chatOpen)
                      _composer()
                    else
                      _ClosedNotice(
                        text: band.members.length <= 1
                            ? t.bandChatClosedAlone
                            : t.bandChatClosedAges,
                        action: t.bandMembersButton,
                        onAction: _openMembers,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _messageList(MyBand? band) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<List<ChatMessage>>(
      stream: _messages,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.t.chatLoadError, textAlign: TextAlign.center),
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
                context.t.bandChatEmpty,
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
            final older = i + 1 < messages.length
                ? messages[messages.length - 2 - i]
                : null;
            final mine = message.senderId == _me;
            final newDay =
                older == null || !sameDay(older.sentAt, message.sentAt);
            // The list is newest first, so the message below is at i - 1.
            final newer = i > 0 ? messages[messages.length - i] : null;
            // An avatar ends each run of messages from one person.
            final lastOfRun =
                newer == null ||
                newer.senderId != message.senderId ||
                !sameDay(newer.sentAt, message.sentAt);
            final sender = band?.memberById(message.senderId);
            final senderName = sender?.name ?? context.t.musicianFallback;
            Widget bubble = ChatBubble(message: message, mine: mine);
            if (!mine) {
              bubble = Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 6,
                children: [
                  if (lastOfRun)
                    // No names on messages: tap the circle to see who it is.
                    Semantics(
                      button: true,
                      label: senderName,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: sender == null || band == null
                            ? null
                            : () => _showPerson(sender, band),
                        child: ExcludeSemantics(
                          child: PersonAvatar(
                            name: senderName,
                            avatarPath: sender?.avatarPath,
                            avatars: widget.avatars,
                            radius: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 28),
                  Expanded(child: bubble),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (newDay) Center(child: DayChip(day: message.sentAt)),
                bubble,
                // "Seen by" under your newest message only.
                if (i == 0 && mine && band != null) _SeenBy(band, message),
              ],
            );
          },
        );
      },
    );
  }

  /// A pop-up about a bandmate: their picture, name and role in the band.
  Future<void> _showPerson(BandPerson person, MyBand band) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                PersonAvatar(
                  name: person.name,
                  avatarPath: person.avatarPath,
                  avatars: widget.avatars,
                  radius: 44,
                  zoom: 1.4,
                ),
                const SizedBox(height: 4),
                Text(
                  person.name,
                  textAlign: TextAlign.center,
                  style: displayStyle(
                    size: 34,
                    color: Theme.of(context).colorScheme.onSurface,
                    latin: !hasGeorgian(person.name),
                  ),
                ),
                Text(
                  context.t.bandMemberRole(person.instrument, band.name),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _composer() => Padding(
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
  );
}

/// "Luka, Nika and Tamar": who's in the band, under its name.
String listMembers(MyBand band) =>
    listJoin([for (final m in band.members) m.name]);

/// "Seen by 2" (or "Seen by everyone") under your newest message.
class _SeenBy extends StatelessWidget {
  const _SeenBy(this.band, this.message);

  final MyBand band;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final others = band.members.length - 1;
    final seen = band.readMarks.values
        .where((at) => !at.isBefore(message.sentAt))
        .length;
    if (seen == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 2),
      child: Text(
        seen >= others ? context.t.bandSeenByAll : context.t.bandSeenBy(seen),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Instead of the message box while the chat is closed.
class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    padding: const EdgeInsets.all(14),
    decoration: printBox(
      context,
      color: OctavaColors.yellow,
      radius: 16,
      shadow: 2,
      borderColor: OctavaColors.ink,
    ),
    child: Row(
      spacing: 12,
      children: [
        const Icon(Icons.lock_outline_rounded, color: OctavaColors.ink),
        Expanded(
          child: Text(text, style: const TextStyle(color: OctavaColors.ink)),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: OctavaColors.ink),
          child: Text(action),
        ),
      ],
    ),
  );
}
