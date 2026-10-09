import 'dart:math';
import 'dart:ui';

/// A musician shown on a swipe card. Until Supabase is wired in, these come
/// from lib/data/sample_musicians.dart.
class Musician {
  const Musician({
    required this.name,
    required this.age,
    required this.instrument,
    required this.area,
    required this.km,
    required this.genres,
    required this.lookingFor,
    required this.likesYou,
    this.clipSeconds = 30,
  });

  final String name;
  final int age;

  /// Matches a role in the band lineup, e.g. "Drums".
  final String instrument;
  final String area;
  final double km;
  final List<String> genres;
  final String lookingFor;

  /// Whether this person already swiped right on you, so a Jam is a match.
  final bool likesYou;
  final int clipSeconds;

  // A stable seed from the name, so each card's artwork looks the same on
  // every run and platform (String.hashCode isn't guaranteed to be stable).
  int get _seed => name.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7fffffff);

  /// Where the halftone portrait's "spotlight" sits, as fractions of its size.
  Offset get spotlight {
    final r = Random(_seed);
    return Offset(0.3 + r.nextDouble() * 0.5, 0.2 + r.nextDouble() * 0.4);
  }

  /// Bar heights (0–1) for the audio clip's waveform.
  List<double> get waveform {
    final r = Random(_seed + 1);
    return List.generate(36, (_) => 0.2 + r.nextDouble() * 0.8);
  }
}

/// "a", "a and b", "a, b and c".
String listJoin(List<String> items) {
  if (items.length < 2) return items.join();
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}
