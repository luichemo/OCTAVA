/// What the onboarding form collects to create a profile.
class ProfileDraft {
  const ProfileDraft({
    required this.displayName,
    required this.instruments,
    this.area = '',
    this.lookingFor = '',
    this.genres = const [],
    this.goals = const {},
    this.frequency,
    this.gear = const {},
  });

  final String displayName;

  /// Instrument id → skill level, in the order picked. The first is primary.
  final Map<String, String> instruments;
  final String area;
  final String lookingFor;
  final List<String> genres;
  final Set<String> goals;
  final String? frequency;

  /// Gear flags that are on, as profiles column names (e.g. "has_car").
  final Set<String> gear;

  /// Row for the `profiles` table.
  Map<String, dynamic> toProfileRow(String userId) => {
    'id': userId,
    'display_name': displayName.trim(),
    'area': _orNull(area),
    'looking_for': _orNull(lookingFor),
    'genres': genres,
    'goals': goals.toList(),
    'rehearsal_frequency': frequency,
    'has_own_gear': gear.contains('has_own_gear'),
    'has_car': gear.contains('has_car'),
    'has_rehearsal_space': gear.contains('has_rehearsal_space'),
    'has_home_studio': gear.contains('has_home_studio'),
  };

  /// Rows for the `profile_instruments` table.
  List<Map<String, dynamic>> toInstrumentRows(String userId) => [
    for (final (i, MapEntry(key: id, value: skill))
        in instruments.entries.indexed)
      {
        'profile_id': userId,
        'instrument_id': id,
        'skill': skill,
        'is_primary': i == 0,
      },
  ];

  static String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();
}
