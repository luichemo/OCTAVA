import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import 'chat_repository.dart';

/// Something worth a banner while you're elsewhere in the app.
sealed class LiveBanner {
  const LiveBanner(this.match);
  final MatchSummary match;
}

class MessageBanner extends LiveBanner {
  const MessageBanner(super.match, this.body);
  final String body;
}

/// Someone else's swipe completed a match with you.
class NewMatchBanner extends LiveBanner {
  const NewMatchBanner(super.match);
}

/// Your matches, kept current by Realtime for the whole signed-in session:
/// the Matches list, unread badges, "Seen", banners and the band row.
///
/// A `ChangeNotifier` is Flutter's simple observable: widgets wrapped in a
/// `ListenableBuilder` rebuild whenever it calls `notifyListeners()`.
class LiveUpdates extends ChangeNotifier {
  LiveUpdates(this.repository);

  final ChatRepository repository;

  /// Null until first loaded.
  List<MatchSummary>? matches;

  /// The last loading error, shown until a load works again.
  Object? error;

  /// Goes up whenever a match appears or disappears, so the band row knows
  /// to reload.
  int matchSetVersion = 0;

  int get unreadTotal =>
      matches?.fold<int>(0, (sum, m) => sum + m.unreadCount) ?? 0;

  MatchSummary? matchById(String id) =>
      matches?.where((m) => m.matchId == id).firstOrNull;

  final _banners = StreamController<LiveBanner>.broadcast();

  /// Banners for messages and matches that arrive while you're not in that
  /// chat.
  Stream<LiveBanner> get banners => _banners.stream;

  StreamSubscription<LiveChange>? _sub;
  String? _openChat;
  bool _disposed = false;

  /// Loads matches and starts listening. Call once.
  void start() {
    _sub = repository.changes().listen(_onChange);
    refresh();
  }

  Future<void>? _loading;
  bool _again = false;

  /// Reloads matches. Calls during a load are merged into one more load
  /// afterwards, and every caller waits for that, so nobody sees stale data.
  Future<void> refresh() {
    _again = true;
    return _loading ??= _loadUntilCurrent();
  }

  Future<void> _loadUntilCurrent() async {
    try {
      while (_again && !_disposed) {
        _again = false;
        await _load();
      }
    } finally {
      _loading = null;
    }
  }

  Future<void> _load() async {
    try {
      final next = await repository.loadMatches();
      if (_disposed) return;
      matches = [
        // The chat on screen is read, even if the read mark is in flight.
        for (final m in next)
          m.matchId == _openChat ? m.copyWith(unreadCount: 0) : m,
      ];
      error = null;
    } catch (e) {
      if (_disposed) return;
      error = e;
    }
    notifyListeners();
  }

  Future<void> _onChange(LiveChange change) async {
    switch (change) {
      case MessageArrived(:final matchId, :final senderId, :final body):
        final fromThem = senderId != repository.myId;
        if (fromThem && matchId == _openChat) {
          await repository.markRead(matchId);
          if (_disposed) return;
        }
        await refresh();
        if (_disposed) return;
        final match = matchById(matchId);
        if (fromThem && matchId != _openChat && match != null) {
          _banners.add(MessageBanner(match, body));
        }
      case MatchMade(:final matchId, :final createdBy):
        await refresh();
        if (_disposed) return;
        matchSetVersion++;
        notifyListeners();
        final match = matchById(matchId);
        // Your own swipe already showed the "wants to jam too" dialog.
        if (createdBy != repository.myId && match != null) {
          _banners.add(NewMatchBanner(match));
        }
      case MatchRemoved():
        await refresh();
        if (_disposed) return;
        matchSetVersion++;
        notifyListeners();
      case ReadMarked():
        await refresh();
        if (_disposed) return;
    }
  }

  /// A chat screen opened: it's read now, and stays read while open.
  void openChat(String matchId) {
    _openChat = matchId;
    _clearUnread(matchId);
    repository.markRead(matchId);
  }

  /// The chat screen closed. Marks it read once more, for anything that
  /// arrived while it was open.
  void closeChat(String matchId) {
    if (_openChat != matchId) return;
    _openChat = null;
    repository.markRead(matchId);
  }

  void _clearUnread(String matchId) {
    final list = matches;
    if (list == null) return;
    matches = [
      for (final m in list)
        m.matchId == matchId ? m.copyWith(unreadCount: 0) : m,
    ];
    // Chat screens call this from initState, while widgets are building;
    // listeners may only be told once the build is over.
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _banners.close();
    super.dispose();
  }
}
