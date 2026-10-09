import 'profile_link.dart';

/// What the profile form collects, to create or update a profile.
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
    this.links = const [],
  });

  /// Rebuilds a draft from the database rows, for editing.
  factory ProfileDraft.fromRows({
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> instruments,
    required List<Map<String, dynamic>> links,
  }) {
    // Main instrument first, so it stays the main one when saved again.
    final sorted = [...instruments]
      ..sort(
        (a, b) =>
            (b['is_primary'] == true ? 1 : 0) -
            (a['is_primary'] == true ? 1 : 0),
      );
    return ProfileDraft(
      displayName: profile['display_name'] as String,
      area: (profile['area'] as String?) ?? '',
      lookingFor: (profile['looking_for'] as String?) ?? '',
      genres: (profile['genres'] as List).cast<String>(),
      goals: (profile['goals'] as List).cast<String>().toSet(),
      frequency: profile['rehearsal_frequency'] as String?,
      gear: {
        for (final flag in const [
          'has_own_gear',
          'has_car',
          'has_rehearsal_space',
          'has_home_studio',
        ])
          if (profile[flag] == true) flag,
      },
      instruments: {
        for (final i in sorted)
          i['instrument_id'] as String: i['skill'] as String,
      },
      links: [
        for (final l in links)
          ProfileLink(kind: l['kind'] as String, url: l['url'] as String),
      ],
    );
  }

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

  /// Links to YouTube, TikTok and so on. Saved when editing a profile.
  final List<ProfileLink> links;

  /// Rows for the `profile_links` table.
  List<Map<String, dynamic>> toLinkRows(String userId) => [
    for (final l in links) {'profile_id': userId, 'kind': l.kind, 'url': l.url},
  ];

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
