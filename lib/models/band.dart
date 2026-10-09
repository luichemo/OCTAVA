/// One slot in the "Your band" row.
///
/// This is a Dart *record* type: a small immutable value with named fields,
/// like a TypeScript `{ role: string; member: string | null }` object type.
/// `member` is null while the slot is open, or [youMarker] for yourself.
typedef BandSlot = ({String role, String? member});

/// A match who can fill a slot: their name and main instrument id.
typedef BandMember = ({String name, String? role});

/// Marks your own slot in a lineup (shown as "You").
const youMarker = '@you';

/// Most people a lineup has room for besides you, and most of one role.
/// The database enforces the same limits (band_roles).
const maxBandSlots = 8;
const maxSlotsPerRole = 4;

/// The roles a band needs until its owner chooses: these five minus your
/// own main instrument, one each. Matches get_deck's default on the server.
const defaultBandRoles = ['vocals', 'guitar', 'bass', 'drums', 'keys'];

/// Role id → how many. Map order is display order.
Map<String, int> defaultBandNeeds(String? myRole) => {
  for (final role in defaultBandRoles)
    if (role != myRole) role: 1,
};

/// Your slot first, then each needed role as many times as needed. Each
/// member fills the first open slot of their main instrument, in order;
/// members with no open slot are left out.
List<BandSlot> buildLineup({
  required String? myRole,
  required Map<String, int>? needs,
  List<BandMember> members = const [],
}) {
  final slots = <BandSlot>[
    if (myRole != null) (role: myRole, member: youMarker),
    for (final MapEntry(key: role, value: count)
        in (needs ?? defaultBandNeeds(myRole)).entries)
      for (var i = 0; i < count; i++) (role: role, member: null),
  ];
  for (final m in members) {
    final open = slots.indexWhere((s) => s.role == m.role && s.member == null);
    if (open >= 0) slots[open] = (role: m.role!, member: m.name);
  }
  return slots;
}
