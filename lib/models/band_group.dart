import '../data/profile_options.dart';

/// Someone in (or being proposed to) a band, as the band page shows them.
class BandPerson {
  const BandPerson({
    required this.id,
    required this.name,
    this.instrumentId,
    this.avatarPath,
  });

  final String id;
  final String name;

  /// Their role in the band (members) or main instrument (candidates).
  final String? instrumentId;
  final String? avatarPath;

  String get instrument => instrumentLabel(instrumentId);
}

/// Someone a member proposed: being voted on, or invited and not yet
/// answered.
class BandProposal {
  const BandProposal({
    required this.id,
    required this.candidate,
    required this.invited,
    this.proposedBy,
    this.approvedBy = const {},
  });

  final String id;
  final BandPerson candidate;

  /// Who proposed them; null if that person has left the app.
  final BandPerson? proposedBy;

  /// True once everyone approved and the invite is out.
  final bool invited;

  /// Ids of members who said yes so far.
  final Set<String> approvedBy;
}

/// A vote on removing a member. It passes with a majority of the other
/// members (everyone but [target]); [target] never sees it.
class BandRemoval {
  const BandRemoval({
    required this.id,
    required this.target,
    this.proposedBy,
    this.yesBy = const {},
    this.votedBy = const {},
  });

  final String id;
  final BandPerson target;
  final BandPerson? proposedBy;

  /// Members who said yes, and everyone who voted either way.
  final Set<String> yesBy;
  final Set<String> votedBy;

  /// Yes votes needed: more than half of the members other than [target].
  int neededIn(int memberCount) => (memberCount - 1) ~/ 2 + 1;
}

/// The newest message in a band chat, for the Matches list.
class BandMessagePreview {
  const BandMessagePreview({
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
  });

  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;
}

/// A band you're in.
class MyBand {
  const MyBand({
    required this.id,
    required this.name,
    required this.members,
    this.proposals = const [],
    this.chatOpen = true,
    this.unreadCount = 0,
    this.lastMessage,
    this.readMarks = const {},
    this.description,
    this.genres = const [],
    this.openRoles = const [],
    this.clipPath,
    this.clipSeconds,
    this.removals = const [],
  });

  /// Open votes on removing a member (never about you: those are hidden).
  final List<BandRemoval> removals;

  /// The band's public profile, shown on its card in other people's feeds.
  final String? description;
  final List<String> genres;

  /// Instrument ids the band is looking for, in the order chosen.
  final List<String> openRoles;

  /// The band's own clip in the band-clips bucket, and its length.
  final String? clipPath;
  final int? clipSeconds;

  /// Whether members can post: 2+ members, 3+ when teens and adults mix.
  final bool chatOpen;

  /// Other members' messages you haven't read.
  final int unreadCount;
  final BandMessagePreview? lastMessage;

  /// When each other member last read the chat, for "Seen by".
  final Map<String, DateTime> readMarks;

  /// The same band with a different unread count.
  MyBand copyWith({int? unreadCount}) => MyBand(
    id: id,
    name: name,
    members: members,
    proposals: proposals,
    chatOpen: chatOpen,
    unreadCount: unreadCount ?? this.unreadCount,
    lastMessage: lastMessage,
    readMarks: readMarks,
    description: description,
    genres: genres,
    openRoles: openRoles,
    clipPath: clipPath,
    clipSeconds: clipSeconds,
    removals: removals,
  );

  BandPerson? memberById(String id) =>
      members.where((m) => m.id == id).firstOrNull;

  final String id;
  final String name;

  /// Oldest member first.
  final List<BandPerson> members;

  /// Open proposals: being voted on or invited.
  final List<BandProposal> proposals;

  bool hasMember(String id) => members.any((m) => m.id == id);

  /// Votes still waiting for [me]: new members and removals.
  int votesWaitingFor(String me) =>
      proposals.where((p) => !p.invited && !p.approvedBy.contains(me)).length +
      removals.where((r) => !r.votedBy.contains(me)).length;
}

/// An invite for you to join a band.
class BandInvite {
  const BandInvite({
    required this.proposalId,
    required this.bandId,
    required this.bandName,
    required this.members,
  });

  final String proposalId;
  final String bandId;
  final String bandName;
  final List<BandPerson> members;
}

/// Everything band-related for the signed-in person.
typedef BandsState = ({List<MyBand> bands, List<BandInvite> invites});

/// Something that changed in your bands, pushed live by the server.
sealed class BandChange {
  const BandChange();
}

/// A new message in one of your band chats (from anyone, you included).
class BandMessageArrived extends BandChange {
  const BandMessageArrived({
    required this.bandId,
    required this.senderId,
    required this.body,
  });
  final String bandId;
  final String senderId;
  final String body;
}

/// Bands, members, proposals, votes or read marks changed.
class BandsChanged extends BandChange {
  const BandsChanged();
}
