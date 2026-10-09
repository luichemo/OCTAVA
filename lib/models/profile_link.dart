/// A link on a profile, such as a YouTube video or a SoundCloud page.
class ProfileLink {
  const ProfileLink({required this.kind, required this.url});

  /// Builds a link from what someone pasted, or returns null if it isn't a
  /// usable web address. Adds https:// when missing (the database only
  /// accepts https) and works out the site.
  static ProfileLink? fromInput(String input) {
    var text = input.trim();
    if (text.isEmpty || text.contains(' ')) return null;
    if (text.startsWith('http://')) text = 'https://${text.substring(7)}';
    if (!text.startsWith('https://')) text = 'https://$text';
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.host.contains('.') || text.length > 300) {
      return null;
    }
    return ProfileLink(kind: kindFor(uri.host), url: text);
  }

  /// `link_kind` value for a host name.
  static String kindFor(String host) {
    final h = host.toLowerCase();
    bool on(String domain) => h == domain || h.endsWith('.$domain');
    if (on('youtube.com') || on('youtu.be')) return 'youtube';
    if (on('tiktok.com')) return 'tiktok';
    if (on('instagram.com')) return 'instagram';
    if (on('spotify.com')) return 'spotify';
    if (on('soundcloud.com')) return 'soundcloud';
    if (on('bandcamp.com')) return 'bandcamp';
    return 'other';
  }

  /// `link_kind` enum value.
  final String kind;
  final String url;

  String get label => linkKindLabels[kind] ?? 'Website';

  @override
  bool operator ==(Object other) =>
      other is ProfileLink && other.kind == kind && other.url == url;

  @override
  int get hashCode => Object.hash(kind, url);
}

/// `link_kind` enum → label.
const linkKindLabels = <String, String>{
  'youtube': 'YouTube',
  'tiktok': 'TikTok',
  'instagram': 'Instagram',
  'spotify': 'Spotify',
  'soundcloud': 'SoundCloud',
  'bandcamp': 'Bandcamp',
  'other': 'Website',
};
