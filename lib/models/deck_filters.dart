/// What the swipe deck is filtered by. Maps onto get_deck's parameters.
class DeckFilters {
  const DeckFilters({
    this.maxKm = 25,
    this.instruments = const {},
    this.minSkill,
    this.genres = const [],
    this.goals = const {},
    this.frequencies = const {},
  });

  factory DeckFilters.fromJson(Map<String, dynamic> json) => DeckFilters(
    maxKm: json['maxKm'] as int?,
    instruments: {...(json['instruments'] as List? ?? const []).cast<String>()},
    minSkill: json['minSkill'] as String?,
    genres: [...(json['genres'] as List? ?? const []).cast<String>()],
    goals: {...(json['goals'] as List? ?? const []).cast<String>()},
    frequencies: {...(json['frequencies'] as List? ?? const []).cast<String>()},
  );

  /// Kilometres; null means anywhere. Only applies once you've shared a location.
  final int? maxKm;

  /// Instrument ids. Empty means any.
  final Set<String> instruments;

  /// Lowest `skill_level` on one of [instruments]; ignored without instruments.
  final String? minSkill;
  final List<String> genres;

  /// `goal` values.
  final Set<String> goals;

  /// `rehearsal_frequency` values.
  final Set<String> frequencies;

  static const distanceChoices = [5, 10, 25, 50, 100];

  /// Filters other than distance that narrow the deck.
  int get activeCount =>
      (instruments.isNotEmpty ? 1 : 0) +
      (instruments.isNotEmpty && minSkill != null ? 1 : 0) +
      (genres.isNotEmpty ? 1 : 0) +
      (goals.isNotEmpty ? 1 : 0) +
      (frequencies.isNotEmpty ? 1 : 0);

  /// Header text, e.g. "Within 25 km, 2 filters".
  String describe({required bool hasLocation}) {
    final where = hasLocation && maxKm != null
        ? 'Within $maxKm km'
        : 'Everywhere';
    final n = activeCount;
    return n == 0 ? where : '$where, $n ${n == 1 ? 'filter' : 'filters'}';
  }

  /// Parameters for the get_deck database function. Null means "any".
  Map<String, dynamic> toRpcParams({required bool hasLocation}) => {
    'max_km': hasLocation ? maxKm : null,
    'instrument_ids': instruments.isEmpty ? null : instruments.toList(),
    'min_skill': instruments.isEmpty ? null : minSkill,
    'genre_filter': genres.isEmpty ? null : genres,
    'goal_filter': goals.isEmpty ? null : goals.toList(),
    'frequency_filter': frequencies.isEmpty ? null : frequencies.toList(),
  };

  Map<String, dynamic> toJson() => {
    'maxKm': maxKm,
    'instruments': instruments.toList(),
    'minSkill': minSkill,
    'genres': genres,
    'goals': goals.toList(),
    'frequencies': frequencies.toList(),
  };
}
