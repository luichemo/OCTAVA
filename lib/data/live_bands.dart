import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/band_group.dart';
import 'bands_repository.dart';

/// A band message that arrived while you weren't in that chat.
class BandMessageBanner {
  const BandMessageBanner({
    required this.band,
    required this.sender,
    required this.body,
  });
  final MyBand band;
  final BandPerson sender;
  final String body;
}

/// Your bands, invites and band chats, kept current by Realtime for the
/// whole signed-in session, like LiveUpdates is for matches.
class LiveBands extends ChangeNotifier {
  LiveBands(this.repository);

  final BandsRepository repository;

  /// Null until first loaded.
  List<MyBand>? bands;
  List<BandInvite> invites = const [];

  /// Bands you asked to join that are still voting.
  List<MyBandRequest> requests = const [];

  /// The last loading error, shown until a load works again.
  Object? error;

  /// Things waiting for you: invites to answer and votes to cast.
  int get actionCount =>
      invites.length +
      (bands?.fold<int>(
            0,
            (sum, b) => sum + b.votesWaitingFor(repository.myId),
          ) ??
          0);

  /// Unread band messages.
  int get unreadTotal =>
      bands?.fold<int>(0, (sum, b) => sum + b.unreadCount) ?? 0;

  /// Everything for the Matches badge.
  int get badgeCount => actionCount + unreadTotal;

  MyBand? bandById(String id) => bands?.where((b) => b.id == id).firstOrNull;

  final _banners = StreamController<BandMessageBanner>.broadcast();

  /// Banners for band messages outside the open band chat.
  Stream<BandMessageBanner> get banners => _banners.stream;

  StreamSubscription<BandChange>? _sub;
  String? _openChat;
  bool _disposed = false;

  void start() {
    _sub = repository.changes().listen(_onChange);
    refresh();
  }

  Future<void> _onChange(BandChange change) async {
    switch (change) {
      case BandMessageArrived(:final bandId, :final senderId, :final body):
        final fromOthers = senderId != repository.myId;
        if (fromOthers && bandId == _openChat) {
          await repository.markRead(bandId);
          if (_disposed) return;
        }
        await refresh();
        if (_disposed) return;
        final band = bandById(bandId);
        final sender = band?.memberById(senderId);
        if (fromOthers && bandId != _openChat && band != null) {
          if (sender != null) {
            _banners.add(
              BandMessageBanner(band: band, sender: sender, body: body),
            );
          }
        }
      case BandsChanged():
        await refresh();
    }
  }

  Future<void>? _loading;
  bool _again = false;

  /// Reloads. Calls during a load are merged into one more load afterwards.
  Future<void> refresh() {
    _again = true;
    return _loading ??= _loadUntilCurrent();
  }

  Future<void> _loadUntilCurrent() async {
    try {
      while (_again && !_disposed) {
        _again = false;
        try {
          final next = await repository.load();
          if (_disposed) return;
          bands = [
            // The chat on screen is read, even if the read mark is in flight.
            for (final b in next.bands)
              b.id == _openChat ? b.copyWith(unreadCount: 0) : b,
          ];
          invites = next.invites;
          requests = next.requests;
          error = null;
        } catch (e) {
          if (_disposed) return;
          error = e;
        }
        notifyListeners();
      }
    } finally {
      _loading = null;
    }
  }

  /// A band chat opened: it's read now, and stays read while open.
  void openChat(String bandId) {
    _openChat = bandId;
    final list = bands;
    if (list != null) {
      bands = [
        for (final b in list) b.id == bandId ? b.copyWith(unreadCount: 0) : b,
      ];
      // Called from initState, while widgets build; notify afterwards.
      scheduleMicrotask(() {
        if (!_disposed) notifyListeners();
      });
    }
    repository.markRead(bandId);
  }

  /// The band chat closed. Marks it read once more.
  void closeChat(String bandId) {
    if (_openChat != bandId) return;
    _openChat = null;
    repository.markRead(bandId);
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _banners.close();
    super.dispose();
  }
}
