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

/// Genres: same ids and order as the `genres` table.
Map<String, String> get genreLabels {
  final t = L10n.current;
  return {
    'rock': t.genreRock,
    'pop': t.genrePop,
    'indie': t.genreIndie,
    'alt-rock': t.genreAltRock,
    'punk': t.genrePunk,
    'post-punk': t.genrePostPunk,
    'hardcore': t.genreHardcore,
    'metal': t.genreMetal,
    'grunge': t.genreGrunge,
    'math-rock': t.genreMathRock,
    'post-rock': t.genrePostRock,
    'shoegaze': t.genreShoegaze,
    'dream-pop': t.genreDreamPop,
    'synth-pop': t.genreSynthPop,
    'city-pop': t.genreCityPop,
    'disco': t.genreDisco,
    'funk': t.genreFunk,
    'soul': t.genreSoul,
    'neo-soul': t.genreNeoSoul,
    'r-and-b': t.genreRAndB,
    'hip-hop': t.genreHipHop,
    'rap': t.genreRap,
    'jazz': t.genreJazz,
    'blues': t.genreBlues,
    'gospel': t.genreGospel,
    'electronic': t.genreElectronic,
    'techno': t.genreTechno,
    'house': t.genreHouse,
    'ambient': t.genreAmbient,
    'lo-fi': t.genreLoFi,
    'experimental': t.genreExperimental,
    'folk': t.genreFolk,
    'indie-folk': t.genreIndieFolk,
    'georgian-folk': t.genreGeorgianFolk,
    'singer-songwriter': t.genreSingerSongwriter,
    'country': t.genreCountry,
    'reggae': t.genreReggae,
    'ska': t.genreSka,
    'latin': t.genreLatin,
    'world': t.genreWorld,
    'classical': t.genreClassical,
    'soundtrack': t.genreSoundtrack,
  };
}

/// A genre id's label (the id itself for anything unknown).
String genreLabel(String id) => genreLabels[id] ?? id;
