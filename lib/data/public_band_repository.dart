import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import 'repositories.dart';

/// Where the tester preview lives; public band links point here.
const publicSiteUrl = 'https://luichemo.github.io/OCTAVA/';

/// The shareable link to a band's public page.
String publicBandLink(String bandId) => '$publicSiteUrl?band=$bandId';

/// The band id in a public page link's `band` query, or null.
String? bandIdFromLink(Uri uri) {
  final id = uri.queryParameters['band'];
  return id != null &&
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false,
          ).hasMatch(id)
      ? id
      : null;
}

/// One member as the public sees them: adults with their name and avatar,
/// 16–17 year olds as their instrument only (name and avatar null).
typedef PublicMember = ({String instrument, String? name, String? avatarUrl});

/// What a band's public page shows, from the `band-page` Edge Function.
class PublicBand {
  const PublicBand({
    required this.id,
    required this.name,
    this.description,
    this.genres = const [],
    this.openRoles = const [],
    this.clipUrl,
    this.clipSeconds,
    this.members = const [],
    this.songs = const [],
  });

  factory PublicBand.fromJson(Map<String, dynamic> j) => PublicBand(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    genres: (j['genres'] as List? ?? const []).cast<String>(),
    openRoles: (j['openRoles'] as List? ?? const []).cast<String>(),
    clipUrl: j['clipUrl'] as String?,
    clipSeconds: j['clipSeconds'] as int?,
    members: [
      for (final m in (j['members'] as List? ?? const []))
        (
          instrument: m['instrument'] as String,
          name: m['name'] as String?,
          avatarUrl: m['avatarUrl'] as String?,
        ),
    ],
    songs: (j['songs'] as List? ?? const []).cast<String>(),
  );

  final String id;
  final String name;
  final String? description;
  final List<String> genres;
  final List<String> openRoles;

  /// A temporary (1 hour) link to the band clip.
  final String? clipUrl;
  final int? clipSeconds;
  final List<PublicMember> members;

  /// Titles of the songs marked Ready.
  final List<String> songs;
}

/// Loads public band pages. Works signed out.
abstract interface class PublicBandSource {
  /// The band's page, or null when there's no such band or its page is off.
  Future<PublicBand?> load(String bandId);
}

class SupabasePublicBands implements PublicBandSource {
  SupabasePublicBands(this._client);
  final SupabaseClient _client;

  @override
  Future<PublicBand?> load(String bandId) async {
    try {
      final response = await _client.functions.invoke(
        'band-page',
        body: {'band': bandId},
      );
      return PublicBand.fromJson(response.data as Map<String, dynamic>);
    } on FunctionException catch (e) {
      if (e.status == 404) return null;
      throw UserFacingException(L10n.current.errPublicBandLoad);
    } catch (_) {
      throw UserFacingException(L10n.current.errPublicBandLoad);
    }
  }
}
