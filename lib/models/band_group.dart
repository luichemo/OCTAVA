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

/// A band you're in.
class MyBand {
  const MyBand({
    required this.id,
    required this.name,
    required this.members,
    this.proposals = const [],
  });

  final String id;
  final String name;

  /// Oldest member first.
  final List<BandPerson> members;

  /// Open proposals: being voted on or invited.
  final List<BandProposal> proposals;

  bool hasMember(String id) => members.any((m) => m.id == id);

  /// Proposals still waiting for [me] to vote.
  int votesWaitingFor(String me) =>
      proposals.where((p) => !p.invited && !p.approvedBy.contains(me)).length;
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
