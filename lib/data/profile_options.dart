// Labels for the fixed values stored in the database (enums and the
// instruments table). Keys must match the database exactly; the labels come
// from the translation files, in the app's current language.

import '../l10n/l10n.dart';

/// Same order as the `instruments` table's sort_order.
Map<String, String> get instrumentLabels {
  final t = L10n.current;
  return {
    'vocals': t.instrumentVocals,
    'guitar': t.instrumentGuitar,
    'bass': t.instrumentBass,
    'drums': t.instrumentDrums,
    'keys': t.instrumentKeys,
    'percussion': t.instrumentPercussion,
    'violin': t.instrumentViolin,
    'cello': t.instrumentCello,
    'saxophone': t.instrumentSaxophone,
    'trumpet': t.instrumentTrumpet,
    'trombone': t.instrumentTrombone,
    'flute': t.instrumentFlute,
    'clarinet': t.instrumentClarinet,
    'dj': t.instrumentDj,
    'production': t.instrumentProduction,
    'other': t.instrumentOther,
  };
}

/// An instrument id's label, or "Musician" for none or an unknown id.
String instrumentLabel(String? id) =>
    instrumentLabels[id] ?? L10n.current.musicianFallback;

/// `skill_level` enum, lowest to highest.
Map<String, String> get skillLabels {
  final t = L10n.current;
  return {
    'beginner': t.skillBeginner,
    'intermediate': t.skillIntermediate,
    'advanced': t.skillAdvanced,
    'pro': t.skillPro,
  };
}

/// `goal` enum.
Map<String, String> get goalLabels {
  final t = L10n.current;
  return {
    'fun': t.goalFun,
    'gigging': t.goalGigging,
    'recording': t.goalRecording,
    'paid': t.goalPaid,
  };
}

/// `rehearsal_frequency` enum.
Map<String, String> get frequencyLabels {
  final t = L10n.current;
  return {
    'occasionally': t.freqOccasionally,
    'monthly': t.freqMonthly,
    'weekly': t.freqWeekly,
    'several_a_week': t.freqSeveralAWeek,
  };
}

/// Gear and logistics flags: profiles column → label.
Map<String, String> get gearLabels {
  final t = L10n.current;
  return {
    'has_own_gear': t.gearOwnGear,
    'has_car': t.gearCar,
    'has_rehearsal_space': t.gearRehearsalSpace,
    'has_home_studio': t.gearHomeStudio,
  };
}
