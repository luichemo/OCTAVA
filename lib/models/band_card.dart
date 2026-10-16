import 'musician.dart';

/// A band as it appears in someone else's feed (`get_band_deck`). Members
/// show as instruments only: no names, so teens can see adult bands safely.
class BandCardData {
  const BandCardData({
    required this.id,
    required this.name,
    this.description,
    this.genres = const [],
    this.openRoles = const [],
    this.memberInstruments = const [],
    this.memberCount = 0,
    this.clipPath,
    this.clipSeconds,
    this.fitsYou = false,
  });

  factory BandCardData.fromRow(Map<String, dynamic> row) => BandCardData(
    id: row['id'] as String,
    name: row['name'] as String,
    description: row['description'] as String?,
    genres: (row['genres'] as List? ?? const []).cast<String>(),
    openRoles: (row['open_roles'] as List? ?? const []).cast<String>(),
    memberInstruments: [
      for (final i in row['member_instruments'] as List? ?? const [])
        ?i as String?,
    ],
    memberCount: row['member_count'] as int? ?? 0,
    clipPath: row['clip_path'] as String?,
    clipSeconds: row['clip_seconds'] as int?,
    fitsYou: row['fits_you'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String? description;
  final List<String> genres;

  /// Instrument ids the band is looking for.
  final List<String> openRoles;

  /// Each member's instrument id, oldest member first.
  final List<String> memberInstruments;
  final int memberCount;

  /// The band's clip in the band-clips bucket.
  final String? clipPath;
  final int? clipSeconds;

  /// Your main instrument is one of its open roles.
  final bool fitsYou;
}

/// One card in the swipe deck: a person or a band.
///
/// `sealed`: these two are the only kinds, so a `switch` must handle both
/// (like a TypeScript union of two object types).
sealed class DeckItem {
  const DeckItem();

  /// Stable identity, for widget keys and taking a card out of the deck.
  String get key;
}

class PersonItem extends DeckItem {
  const PersonItem(this.musician);
  final Musician musician;

  @override
  String get key => 'person:${musician.key}';
}

class BandItem extends DeckItem {
  const BandItem(this.band);
  final BandCardData band;

  @override
  String get key => 'band:${band.id}';
}

/// The deck: people, with one band after every [every] people. Bands that
/// need your instrument come first; leftover bands go at the end.
List<DeckItem> mixDeck(
  List<Musician> people,
  List<BandCardData> bands, {
  int every = 3,
}) {
  final queue = [
    ...bands.where((b) => b.fitsYou),
    ...bands.where((b) => !b.fitsYou),
  ];
  final out = <DeckItem>[];
  for (final (i, m) in people.indexed) {
    out.add(PersonItem(m));
    if ((i + 1) % every == 0 && queue.isNotEmpty) {
      out.add(BandItem(queue.removeAt(0)));
    }
  }
  out.addAll(queue.map(BandItem.new));
  return out;
}
