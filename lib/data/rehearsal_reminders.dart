import 'dart:async';

import '../models/rehearsal.dart';
import 'rehearsal_repository.dart';

/// In-app rehearsal reminders: while the app is open, checks every [every]
/// and announces each rehearsal date once, when it starts within [lead].
/// (Phone notifications while the app is closed need push setup later.)
class RehearsalReminders {
  RehearsalReminders(
    this.repository, {
    this.lead = const Duration(hours: 1),
    this.every = const Duration(minutes: 5),
  });

  final RehearsalRepository repository;
  final Duration lead;
  final Duration every;

  final _banners = StreamController<BandRehearsal>.broadcast();
  final _shown = <String>{};
  Timer? _timer;

  /// Rehearsals about to start, once each.
  Stream<BandRehearsal> get banners => _banners.stream;

  void start() {
    check();
    _timer = Timer.periodic(every, (_) => check());
  }

  Future<void> check() async {
    final soon = await repository.soonForMe(within: lead);
    for (final r in soon) {
      final key = '${r.date.rehearsal.id}/${dayKey(r.date.day)}';
      if (_shown.add(key) && !_banners.isClosed) _banners.add(r);
    }
  }

  void dispose() {
    _timer?.cancel();
    _banners.close();
  }
}
