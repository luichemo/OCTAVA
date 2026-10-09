import 'dart:math';
import 'dart:ui';

import '../data/profile_options.dart';
import 'profile_link.dart';
import '../l10n/l10n.dart';

/// A musician shown on a swipe card: from the database (`get_deck`), or the
/// sample people in lib/data/sample_musicians.dart.
class Musician {
  const Musician({
    this.id,
    required this.name,
    required this.age,
    this.instrumentId,
    this.area,
    this.km,
    this.genres = const [],
    this.lookingFor,
    this.likesYou = false,
    this.clipSeconds = 30,
    this.clipPath,
    this.links = const [],
    this.avatarPath,
  });

  /// Builds a card from one row returned by the `get_deck` database function.
  factory Musician.fromDeckRow(Map<String, dynamic> row) {
    final instruments = (row['instruments'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final primary =
        instruments.where((i) => i['is_primary'] == true).firstOrNull ??
        instruments.firstOrNull;
    final clips = (row['clips'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return Musician(
      id: row['id'] as String,
      name: row['display_name'] as String,
      age: row['age'] as int,
      instrumentId: primary?['instrument'] as String?,
      area: row['area'] as String?,
      km: (row['distance_km'] as num?)?.toDouble(),
      genres: (row['genres'] as List? ?? const []).cast<String>(),
      lookingFor: row['looking_for'] as String?,
      clipSeconds: clips.firstOrNull?['seconds'] as int?,
      clipPath: clips.firstOrNull?['path'] as String?,
      avatarPath: row['avatar_path'] as String?,
      links: [
        for (final l
            in (row['links'] as List? ?? const []).cast<Map<String, dynamic>>())
          ProfileLink(kind: l['kind'] as String, url: l['url'] as String),
      ],
    );
  }

  /// Database id. Null for sample musicians.
  final String? id;
  final String name;
  final int age;

  /// Main instrument's id, e.g. "drums". Matches a band lineup role.
  final String? instrumentId;

  /// Main instrument's label in the app's language, e.g. "Drums".
  String get instrument => instrumentLabel(instrumentId);
  final String? area;

  /// Distance from you; null when either of you hasn't shared a location.
  final double? km;
  final List<String> genres;
  final String? lookingFor;

  /// Sample data only: this person already chose Jam on you, so a Jam is a
  /// match. Real matches are decided by the database.
  final bool likesYou;

  /// Length of the first audio clip; null when there are no clips.
  final int? clipSeconds;

  /// Storage path of the first audio clip. Null for sample musicians, whose
  /// clips are only pictures of a waveform.
  final String? clipPath;

  final List<ProfileLink> links;

  /// AI avatar in the `avatars` bucket; null shows the halftone pattern.
  final String? avatarPath;

  /// Stable identity for widget keys.
  String get key => id ?? name;

  /// "Vera, 3 km away", "3 km away", "Vera", or "".
  String get whereText {
    final distance = km == null
        ? null
        : L10n.current.kmAway('${km! % 1 == 0 ? km!.toInt() : km}');
    return [
      area,
      distance,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  // A stable seed from the id or name, so each card's artwork looks the same
  // on every run and platform (String.hashCode isn't guaranteed to be stable).
  int get _seed => key.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7fffffff);

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

  /// 0, 1 or 2: which portrait colour this card uses.
  int get toneIndex => _seed % 3;
}

/// "a", "a and b", "a, b and c".
String listJoin(List<String> items) {
  if (items.length < 2) return items.join();
  return '${items.sublist(0, items.length - 1).join(', ')} ${L10n.current.listAnd} ${items.last}';
}
