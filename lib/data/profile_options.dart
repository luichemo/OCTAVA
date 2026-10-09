// Labels for the fixed values stored in the database (enums and the
// instruments table). Keys must match the database exactly.
// English for now; these move to translation files with Georgian support.

/// Same order as the `instruments` table's sort_order.
const instrumentLabels = <String, String>{
  'vocals': 'Vocals',
  'guitar': 'Guitar',
  'bass': 'Bass',
  'drums': 'Drums',
  'keys': 'Keys',
  'percussion': 'Percussion',
  'violin': 'Violin',
  'cello': 'Cello',
  'saxophone': 'Saxophone',
  'trumpet': 'Trumpet',
  'trombone': 'Trombone',
  'flute': 'Flute',
  'clarinet': 'Clarinet',
  'dj': 'DJ',
  'production': 'Production',
  'other': 'Other',
};

/// `skill_level` enum, lowest to highest.
const skillLabels = <String, String>{
  'beginner': 'Beginner',
  'intermediate': 'Intermediate',
  'advanced': 'Advanced',
  'pro': 'Pro',
};

/// `goal` enum.
const goalLabels = <String, String>{
  'fun': 'For fun',
  'gigging': 'Gigging',
  'recording': 'Recording',
  'paid': 'Paid work',
};

/// `rehearsal_frequency` enum.
const frequencyLabels = <String, String>{
  'occasionally': 'Now and then',
  'monthly': 'Monthly',
  'weekly': 'Weekly',
  'several_a_week': 'Several times a week',
};

/// Gear and logistics flags: profiles column → label.
const gearLabels = <String, String>{
  'has_own_gear': 'Own gear',
  'has_car': 'Car',
  'has_rehearsal_space': 'Rehearsal space',
  'has_home_studio': 'Home studio',
};
