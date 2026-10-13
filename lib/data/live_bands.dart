import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/band_group.dart';
import 'bands_repository.dart';

/// Your bands and invites, kept current by Realtime for the whole signed-in
/// session, like LiveUpdates is for matches.
class LiveBands extends ChangeNotifier {
  LiveBands(this.repository);

  final BandsRepository repository;

  /// Null until first loaded.
  List<MyBand>? bands;
  List<BandInvite> invites = const [];

  /// The last loading error, shown until a load works again.
  Object? error;

  /// Things waiting for you: invites to answer and votes to cast. Shown on
  /// the Matches badge.
  int get actionCount =>
      invites.length +
      (bands?.fold<int>(
            0,
            (sum, b) => sum + b.votesWaitingFor(repository.myId),
          ) ??
          0);

  MyBand? bandById(String id) => bands?.where((b) => b.id == id).firstOrNull;

  StreamSubscription<void>? _sub;
  bool _disposed = false;

  void start() {
    _sub = repository.changes().listen((_) => refresh());
    refresh();
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
          bands = next.bands;
          invites = next.invites;
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

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
