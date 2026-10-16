// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get signOut => 'Sign out';

  @override
  String get navProfile => 'Profile';

  @override
  String get navMatches => 'Matches';

  @override
  String get errOffline =>
      'Couldn\'t reach OCTAVA. Check your connection and try again.';

  @override
  String get authTagline => 'Find people to make music with.';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailError => 'Enter your email address';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHelper => 'At least 8 characters';

  @override
  String get authPasswordEmpty => 'Enter your password';

  @override
  String get authPasswordShort => 'Use at least 8 characters';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCheckEmail =>
      'Check your email: we sent you a link to confirm your account. Open it, then sign in here.';

  @override
  String get errEmailTaken =>
      'There is already an account with this email. Sign in instead.';

  @override
  String get errBadLogin => 'That email and password don\'t match an account.';

  @override
  String get errEmailNotConfirmed =>
      'Confirm your email first: open the link we sent you, then sign in.';

  @override
  String get errWeakPassword =>
      'Choose a stronger password: at least 8 characters, mixing letters and numbers.';

  @override
  String get errEmailInvalid => 'Enter a valid email address.';

  @override
  String get errTooManyAttempts =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get profileSetUpTitle => 'Set up your profile';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileSubtitle =>
      'This is what other musicians see when they swipe.';

  @override
  String get seeYourCard => 'See your card';

  @override
  String get sectionAvatar => 'Avatar';

  @override
  String get sectionAbout => 'About you';

  @override
  String get sectionLocation => 'Location';

  @override
  String get sectionPlay => 'What you play';

  @override
  String get sectionWant => 'What you want';

  @override
  String get sectionLinks => 'Links';

  @override
  String get sectionClips => 'Audio clips';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldNameError => 'Enter the name people will see';

  @override
  String get fieldBirthDate => 'Date of birth';

  @override
  String get fieldBirthDateHelper =>
      'OCTAVA is for ages 16 and over. Others only see your age.';

  @override
  String get fieldBirthDateError => 'Enter your date of birth';

  @override
  String get birthDatePickerTitle => 'Your date of birth';

  @override
  String get confirmBirthDateTitle => 'Is your date of birth right?';

  @override
  String confirmBirthDateBody(String date) {
    return '$date. You can\'t change it later, because it decides who you can meet on OCTAVA.';
  }

  @override
  String get confirmBirthDateNo => 'Change it';

  @override
  String get confirmBirthDateYes => 'Yes, it\'s right';

  @override
  String get fieldArea => 'Area (optional)';

  @override
  String get fieldAreaHint => 'e.g. Vake, Tbilisi';

  @override
  String instrumentMain(String instrument) {
    return '$instrument (main)';
  }

  @override
  String get pickInstrumentError => 'Pick at least one instrument';

  @override
  String get fieldGenres => 'Genres';

  @override
  String get rehearseQuestion => 'How often can you rehearse?';

  @override
  String get gearQuestion => 'What do you have?';

  @override
  String get fieldLookingFor => 'What are you looking for? (optional)';

  @override
  String get fieldLookingForHint =>
      'e.g. A band that rehearses weekly and plays shows';

  @override
  String get linksLabel => 'YouTube, TikTok, SoundCloud, Spotify…';

  @override
  String get linksHint => 'Paste a link and press Enter';

  @override
  String get addLink => 'Add link';

  @override
  String get removeLink => 'Remove link';

  @override
  String get linkInvalid =>
      'Paste a full web address, like youtube.com/watch?v=…';

  @override
  String get linkMax => 'You can add up to 6 links.';

  @override
  String get linkCheckError =>
      'Check the link: it isn\'t a web address we can use.';

  @override
  String get answersMissing =>
      'Some answers are missing. Check the fields marked in red above.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get createProfile => 'Create profile';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get errSaveProfile =>
      'Couldn\'t save your profile. Try again in a moment.';

  @override
  String get errUnder16 => 'OCTAVA is for people aged 16 and over.';

  @override
  String get errBirthDateInvalid => 'Enter a real date of birth.';

  @override
  String get genresChoose => 'Choose genres';

  @override
  String get genresChange => 'Change genres';

  @override
  String get genresSearch => 'Search genres';

  @override
  String get genresDone => 'Done';

  @override
  String get genresMax => 'You can pick up to 10 genres.';

  @override
  String get genresNoResults => 'No genre matches that.';

  @override
  String get noClipsTitle => 'You\'re hidden from the feed';

  @override
  String get noClipsBody =>
      'Musicians without an audio clip don\'t appear when others swipe. Add at least one so people can hear you.';

  @override
  String get noClipsAction => 'Record a clip';

  @override
  String get deckEverywhere => 'Everywhere';

  @override
  String deckWithin(int km) {
    return 'Within $km km';
  }

  @override
  String deckWithFilters(String where, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters',
      one: '1 filter',
    );
    return '$where, $_temp0';
  }

  @override
  String get stampJam => 'Jam';

  @override
  String get stampPass => 'Pass';

  @override
  String get actionJam => 'Jam';

  @override
  String get actionPass => 'Pass';

  @override
  String passedOn(String name) {
    return 'Passed on $name.';
  }

  @override
  String askedToJam(String name) {
    return 'You asked $name to jam';
  }

  @override
  String matchTitle(String name) {
    return '$name wants to jam too';
  }

  @override
  String matchSlotFilled(String instrument) {
    return '$instrument is now filled in your band. Say hi and plan a first rehearsal.';
  }

  @override
  String matchSlotTaken(String holder, String instrument) {
    return '$holder already plays $instrument in your band, but you can still say hi.';
  }

  @override
  String matchSlotYours(String instrument) {
    return 'You already cover $instrument yourself, but you can still say hi.';
  }

  @override
  String saidHi(String name) {
    return 'You said hi to $name';
  }

  @override
  String get sayHi => 'Say hi';

  @override
  String get keepSwiping => 'Keep swiping';

  @override
  String get loadErrorTitle => 'Something went wrong';

  @override
  String get errLoadMusiciansShort => 'Couldn\'t load musicians. Try again.';

  @override
  String get noMatchTitle => 'Nobody matches';

  @override
  String get noMatchBody =>
      'Nobody matches your filters right now. Try fewer filters or a bigger distance.';

  @override
  String get changeFilters => 'Change filters';

  @override
  String get heardEveryoneTitle => 'You\'ve heard everyone';

  @override
  String get heardEveryoneBody =>
      'That\'s everyone for now. New musicians join every week.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get locationPrompt => 'See how far away people are.';

  @override
  String get shareLocation => 'Share location';

  @override
  String get shareLocationShort => 'Share location';

  @override
  String get findingYou => 'Finding you…';

  @override
  String get yourBand => 'Your band';

  @override
  String get slotOpen => 'Open';

  @override
  String get slotYou => 'You';

  @override
  String cardSemantics(String name, int age, String instrument) {
    return '$name, $age, $instrument';
  }

  @override
  String nameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String kmAway(String distance) {
    return '$distance km away';
  }

  @override
  String fitsSlot(String instrument) {
    return 'Fits your open $instrument slot';
  }

  @override
  String plays(String genres) {
    return 'Plays $genres';
  }

  @override
  String get listAnd => 'and';

  @override
  String quoted(String text) {
    return '“$text”';
  }

  @override
  String get noClip => 'No clip to play';

  @override
  String playClipOf(String name) {
    return 'Play $name\'s clip';
  }

  @override
  String stopClipOf(String name) {
    return 'Stop $name\'s clip';
  }

  @override
  String get blockOrReport => 'Block or report';

  @override
  String get musicianFallback => 'Musician';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get matchesEmpty =>
      'No matches yet. When someone you chose Jam on chooses Jam on you too, they appear here.';

  @override
  String get newMatchSayHi => 'New match. Say hi!';

  @override
  String youPrefix(String message) {
    return 'You: $message';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String chatEmpty(String name) {
    return 'You and $name both want to jam. Say hi and plan a first rehearsal.';
  }

  @override
  String get messageHint => 'Message';

  @override
  String get send => 'Send';

  @override
  String get chatLoadError =>
      'Couldn\'t load messages. Check your connection, then go back and open the chat again.';

  @override
  String get errLoadMatches =>
      'Couldn\'t load your matches. Check your connection and try again.';

  @override
  String get errSendBlocked => 'You can\'t send messages in this chat anymore.';

  @override
  String get errSend => 'Couldn\'t send your message. Try again.';

  @override
  String get errSendOffline =>
      'Couldn\'t send your message. Check your connection and try again.';

  @override
  String blockName(String name) {
    return 'Block $name';
  }

  @override
  String get blockSubtitle =>
      'You won\'t see each other and can\'t message. They aren\'t told.';

  @override
  String reportName(String name) {
    return 'Report $name';
  }

  @override
  String get reportSubtitle =>
      'Tell us about something wrong. Reports are private.';

  @override
  String blockedName(String name) {
    return 'You blocked $name.';
  }

  @override
  String reportThanksBlocked(String name) {
    return 'Thanks for reporting. You also blocked $name.';
  }

  @override
  String get reportThanks => 'Thanks for reporting. We review every report.';

  @override
  String blockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String blockConfirmBody(String name) {
    return 'You won\'t see each other on OCTAVA anymore, and neither of you can send messages. $name won\'t be told.';
  }

  @override
  String get whatsWrong => 'What\'s wrong?';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String alsoBlock(String name) {
    return 'Also block $name';
  }

  @override
  String get sendReport => 'Send report';

  @override
  String get reasonHarassment => 'Harassment or hate';

  @override
  String get reasonInappropriate => 'Inappropriate messages or content';

  @override
  String get reasonSpam => 'Spam or a scam';

  @override
  String get reasonFake => 'Fake profile';

  @override
  String get reasonUnderage => 'Seems to be under 16';

  @override
  String get reasonOther => 'Something else';

  @override
  String get errBlock => 'Couldn\'t block. Try again.';

  @override
  String get errBlockOffline =>
      'Couldn\'t block. Check your connection and try again.';

  @override
  String get errReport =>
      'Couldn\'t send your report. Check your connection and try again.';

  @override
  String get navAdd => 'Record a clip';

  @override
  String get recordTitle => 'New clip';

  @override
  String get recordStarting => 'Starting the microphone…';

  @override
  String get recordRecording => 'Recording';

  @override
  String get recordLimit => 'Recording stops by itself at 2:00.';

  @override
  String get recordStop => 'Stop';

  @override
  String recordDone(String length) {
    return 'Recorded $length';
  }

  @override
  String get recordSave => 'Add to profile';

  @override
  String get recordListen => 'Listen back';

  @override
  String get recordStopListening => 'Stop listening';

  @override
  String get recordAgain => 'Record again';

  @override
  String get recordUploadFile => 'Upload a file instead';

  @override
  String get errMicDenied =>
      'OCTAVA can\'t use your microphone. Allow it in your browser or phone settings, then try again.';

  @override
  String get errRecord => 'Couldn\'t record. Try again.';

  @override
  String get errRecordShort => 'That\'s too short. Record at least a second.';

  @override
  String get clipsInfo =>
      'Up to 5 clips, 2 minutes each. Star one to make it your card\'s song; otherwise your first clip plays.';

  @override
  String get clipMakeSong => 'Make this your card\'s song';

  @override
  String get clipIsSong => 'Your card\'s song';

  @override
  String get errClipSong =>
      'Couldn\'t change your card\'s song. Check your connection and try again.';

  @override
  String get clipAdded => 'Clip added to your profile.';

  @override
  String get deleteClipTitle => 'Delete this clip?';

  @override
  String deleteClipBody(String title) {
    return '\"$title\" will be removed from your profile.';
  }

  @override
  String get clipFallback => 'Clip';

  @override
  String get deleteClip => 'Delete clip';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String get uploading => 'Uploading…';

  @override
  String get clipsFull => 'You have 5 clips';

  @override
  String get addClip => 'Add a clip';

  @override
  String get errOpenFiles =>
      'Couldn\'t open your files. Restart the app and try again.';

  @override
  String get errClipsLoad =>
      'Couldn\'t load your clips. Check your connection and try again.';

  @override
  String get errClipType =>
      'Use an MP3, M4A, AAC, WAV, OGG, WEBM or FLAC file.';

  @override
  String get errClipSize =>
      'That file is over 10 MB. Try a shorter or more compressed clip.';

  @override
  String get errClipsMax =>
      'You can have up to 5 clips. Delete one to add another.';

  @override
  String get errClipUpload =>
      'Couldn\'t upload your clip. Check your connection and try again.';

  @override
  String get errClipUnreadable =>
      'Couldn\'t play that file. Try exporting it as MP3 or M4A.';

  @override
  String errClipTooLong(String length) {
    return 'Clips can be up to 2 minutes. This one is $length.';
  }

  @override
  String get errClipSave => 'Couldn\'t save your clip. Try again.';

  @override
  String get errClipDelete =>
      'Couldn\'t delete the clip. Check your connection and try again.';

  @override
  String get errClipPlay =>
      'Couldn\'t play the clip. Check your connection and try again.';

  @override
  String get avatarPainting =>
      'Painting your avatar… this takes a few seconds.';

  @override
  String get avatarInfo =>
      'A riso-print illustration made by AI from your main instrument and genres.';

  @override
  String get avatarGenerate => 'Generate my avatar';

  @override
  String get avatarNew => 'Make a new one';

  @override
  String avatarRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more today',
      one: '1 more today',
    );
    return '$_temp0';
  }

  @override
  String get errAvatarLoad =>
      'Couldn\'t load your avatar. Check your connection and try again.';

  @override
  String get errAvatarGeneric =>
      'Couldn\'t make an avatar right now. Try again.';

  @override
  String get errAvatarOffline =>
      'Couldn\'t make an avatar. Check your connection and try again.';

  @override
  String get errAvatarDaily =>
      'You\'ve made 5 avatars today. Try again tomorrow.';

  @override
  String get errAvatarBusy =>
      'Too many avatars are being made right now. Try again later.';

  @override
  String get errAvatarNotReady =>
      'Avatar generation isn\'t set up yet. Try again later.';

  @override
  String get locationSharing =>
      'You share an approximate location (to about 1 km). People see how far away you are, never where you are.';

  @override
  String get locationNotSharing =>
      'You don\'t share a location, so nobody sees distances to you and distance filters are off.';

  @override
  String get locationSaved => 'Location saved.';

  @override
  String get updateLocation => 'Update location';

  @override
  String get locationStopped => 'You no longer share a location.';

  @override
  String get stopSharing => 'Stop sharing';

  @override
  String get errLocationOff =>
      'Location is turned off on this device. Turn it on and try again.';

  @override
  String get errLocationDenied =>
      'OCTAVA isn\'t allowed to use your location. Allow it in your browser or phone settings, then try again.';

  @override
  String get errLocationFind =>
      'Couldn\'t find your location. Try again in a moment.';

  @override
  String get errLocationSave =>
      'Couldn\'t save your location. Check your connection and try again.';

  @override
  String get errLocationRemove =>
      'Couldn\'t remove your location. Check your connection and try again.';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get reset => 'Reset';

  @override
  String get filterDistance => 'Distance';

  @override
  String get filterDistanceNoLocation =>
      'Share your location to filter by distance. Until then you see everyone.';

  @override
  String kmShort(int km) {
    return '$km km';
  }

  @override
  String get anywhere => 'Anywhere';

  @override
  String get filterInstruments => 'Instruments';

  @override
  String get filterInstrumentsHint =>
      'Show only people who play these. Leave empty for everyone.';

  @override
  String get filterSkill => 'Lowest skill level';

  @override
  String get filterSkillNeedsInstruments =>
      'Pick instruments first; the skill level applies to them.';

  @override
  String get any => 'Any';

  @override
  String skillOrBetter(String skill) {
    return '$skill or better';
  }

  @override
  String get filterGenresHint => 'Show people who play at least one of these.';

  @override
  String get filterGoals => 'Goals';

  @override
  String get filterRehearses => 'Rehearses';

  @override
  String get showMusicians => 'Show musicians';

  @override
  String get errLoadMusicians =>
      'Couldn\'t load musicians. Check your connection and try again.';

  @override
  String get errSaveSwipe =>
      'Couldn\'t save that. Check your connection and try again.';

  @override
  String get errLoadBand =>
      'Couldn\'t load your band. Check your connection and try again.';

  @override
  String get yourCard => 'Your card';

  @override
  String get cardPreviewInfo =>
      'This is how other musicians see you. Distance shows for them once you both share a location.';

  @override
  String get languageDevice => 'Device';

  @override
  String get languageInfo =>
      '\"Device\" follows your phone or browser language.';

  @override
  String get instrumentVocals => 'Vocals';

  @override
  String get instrumentGuitar => 'Guitar';

  @override
  String get instrumentBass => 'Bass';

  @override
  String get instrumentDrums => 'Drums';

  @override
  String get instrumentKeys => 'Keys';

  @override
  String get instrumentPercussion => 'Percussion';

  @override
  String get instrumentViolin => 'Violin';

  @override
  String get instrumentCello => 'Cello';

  @override
  String get instrumentSaxophone => 'Saxophone';

  @override
  String get instrumentTrumpet => 'Trumpet';

  @override
  String get instrumentTrombone => 'Trombone';

  @override
  String get instrumentFlute => 'Flute';

  @override
  String get instrumentClarinet => 'Clarinet';

  @override
  String get instrumentDj => 'DJ';

  @override
  String get instrumentProduction => 'Production';

  @override
  String get instrumentOther => 'Other';

  @override
  String get skillBeginner => 'Beginner';

  @override
  String get skillIntermediate => 'Intermediate';

  @override
  String get skillAdvanced => 'Advanced';

  @override
  String get skillPro => 'Pro';

  @override
  String get goalFun => 'For fun';

  @override
  String get goalGigging => 'Gigging';

  @override
  String get goalRecording => 'Recording';

  @override
  String get goalPaid => 'Paid work';

  @override
  String get freqOccasionally => 'Now and then';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqSeveralAWeek => 'Several times a week';

  @override
  String get gearOwnGear => 'Own gear';

  @override
  String get gearCar => 'Car';

  @override
  String get gearRehearsalSpace => 'Rehearsal space';

  @override
  String get gearHomeStudio => 'Home studio';

  @override
  String get linkWebsite => 'Website';

  @override
  String get genreRock => 'Rock';

  @override
  String get genrePop => 'Pop';

  @override
  String get genreIndie => 'Indie';

  @override
  String get genreAltRock => 'Alternative rock';

  @override
  String get genrePunk => 'Punk';

  @override
  String get genrePostPunk => 'Post-punk';

  @override
  String get genreHardcore => 'Hardcore';

  @override
  String get genreMetal => 'Metal';

  @override
  String get genreGrunge => 'Grunge';

  @override
  String get genreMathRock => 'Math rock';

  @override
  String get genrePostRock => 'Post-rock';

  @override
  String get genreShoegaze => 'Shoegaze';

  @override
  String get genreDreamPop => 'Dream pop';

  @override
  String get genreSynthPop => 'Synth-pop';

  @override
  String get genreCityPop => 'City pop';

  @override
  String get genreDisco => 'Disco';

  @override
  String get genreFunk => 'Funk';

  @override
  String get genreSoul => 'Soul';

  @override
  String get genreNeoSoul => 'Neo-soul';

  @override
  String get genreRAndB => 'R&B';

  @override
  String get genreHipHop => 'Hip-hop';

  @override
  String get genreRap => 'Rap';

  @override
  String get genreJazz => 'Jazz';

  @override
  String get genreBlues => 'Blues';

  @override
  String get genreGospel => 'Gospel';

  @override
  String get genreElectronic => 'Electronic';

  @override
  String get genreTechno => 'Techno';

  @override
  String get genreHouse => 'House';

  @override
  String get genreAmbient => 'Ambient';

  @override
  String get genreLoFi => 'Lo-fi';

  @override
  String get genreExperimental => 'Experimental';

  @override
  String get genreFolk => 'Folk';

  @override
  String get genreIndieFolk => 'Indie folk';

  @override
  String get genreGeorgianFolk => 'Georgian folk';

  @override
  String get genreSingerSongwriter => 'Singer-songwriter';

  @override
  String get genreCountry => 'Country';

  @override
  String get genreReggae => 'Reggae';

  @override
  String get genreSka => 'Ska';

  @override
  String get genreLatin => 'Latin';

  @override
  String get genreWorld => 'World music';

  @override
  String get genreClassical => 'Classical';

  @override
  String get genreSoundtrack => 'Soundtrack';

  @override
  String get bandEdit => 'Edit';

  @override
  String get bandRolesTitle => 'Who does your band need?';

  @override
  String bandRolesHint(int max) {
    return 'Room for up to $max people besides you.';
  }

  @override
  String bandRolesCount(int count, int max) {
    return '$count of $max';
  }

  @override
  String get bandRolesEmpty => 'Pick at least one role.';

  @override
  String get bandRolesSave => 'Save';

  @override
  String get roleMore => 'One more';

  @override
  String get roleFewer => 'One fewer';

  @override
  String roleCount(String instrument, int count) {
    return '$instrument ×$count';
  }

  @override
  String get sectionBand => 'Your band needs';

  @override
  String get bandChange => 'Change roles';

  @override
  String get bandDefaultNote => 'Not chosen yet, so these are the usual roles.';

  @override
  String matchNoSlot(String instrument) {
    return 'Your band isn\'t looking for $instrument right now, but you can still say hi.';
  }

  @override
  String get errSaveBand =>
      'Couldn\'t save your band\'s roles. Check your connection and try again.';

  @override
  String get bannerNewMatch => 'You both want to play together. Tap to say hi.';

  @override
  String get seen => 'Seen';

  @override
  String get today => 'Today';

  @override
  String get chatMore => 'More';

  @override
  String get unmatch => 'Unmatch';

  @override
  String unmatchTitle(String name) {
    return 'Unmatch $name?';
  }

  @override
  String get unmatchBody =>
      'This chat will disappear for both of you. You can\'t undo this.';

  @override
  String unmatchDone(String name) {
    return 'You unmatched $name.';
  }

  @override
  String get errUnmatch =>
      'Couldn\'t unmatch. Check your connection and try again.';

  @override
  String get undo => 'Undo';

  @override
  String get errUndo =>
      'Couldn\'t bring the card back. Check your connection and try again.';

  @override
  String get authHeadline => 'Swipe. Jam. Form a band.';

  @override
  String get authAgeTitle => '16+ musicians only';

  @override
  String get authAgeBody => 'By joining, you confirm you\'re 16 or older.';

  @override
  String bandFilled(int filled, int total) {
    return '$filled of $total filled';
  }

  @override
  String get sectionTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeInfo => '\"Device\" follows your phone or browser setting.';

  @override
  String get themeToDark => 'Switch to dark mode';

  @override
  String get themeToLight => 'Switch to light mode';

  @override
  String cardAlsoPlays(String instruments) {
    return 'Also: $instruments';
  }

  @override
  String get instrumentMakeMain => 'Make this your main instrument';

  @override
  String get instrumentIsMain => 'Your main instrument';

  @override
  String get errEmailBusy =>
      'Sign-ups are busy right now. Please try again in an hour.';

  @override
  String get clipPosition => 'Position in the clip';

  @override
  String get bandsTitle => 'Bands';

  @override
  String get bandCreate => 'Create a band';

  @override
  String get bandCreateTitle => 'Name your band';

  @override
  String get bandNameLabel => 'Band name';

  @override
  String get bandNameError => 'Give your band a name';

  @override
  String get bandCreateConfirm => 'Create';

  @override
  String bandInviteTitle(String band) {
    return '$band wants you to join';
  }

  @override
  String get bandAccept => 'Accept';

  @override
  String get bandDecline => 'Decline';

  @override
  String bandJoined(String band) {
    return 'You joined $band!';
  }

  @override
  String bandMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String bandVotesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes waiting for you',
      one: '1 vote waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get bandMembers => 'Members';

  @override
  String get bandYou => 'You';

  @override
  String get bandAddMember => 'Add member';

  @override
  String get bandAddMemberTitle => 'Propose one of your matches';

  @override
  String get bandAddMemberEmpty =>
      'Nobody left to propose. Match with more musicians first.';

  @override
  String bandProposedVote(String name) {
    return 'Proposed $name. Your bandmates will vote.';
  }

  @override
  String bandProposedInvite(String name) {
    return 'Invite sent to $name.';
  }

  @override
  String get bandWaiting => 'New members';

  @override
  String bandProposedBy(String name) {
    return 'Proposed by $name';
  }

  @override
  String bandApprovals(int yes, int total) {
    return '$yes of $total approved';
  }

  @override
  String get bandApprove => 'Approve';

  @override
  String get bandReject => 'Reject';

  @override
  String get bandYouApproved => 'You approved';

  @override
  String get bandInvited => 'Invited, waiting for their answer';

  @override
  String bandRejectTitle(String name) {
    return 'Reject $name?';
  }

  @override
  String get bandRejectBody =>
      'One no is enough: they won\'t be invited, and they won\'t be told.';

  @override
  String get bandLeave => 'Leave band';

  @override
  String bandLeaveTitle(String band) {
    return 'Leave $band?';
  }

  @override
  String get bandLeaveBody =>
      'You\'ll stop seeing its members and votes. If you\'re the last member, the band is deleted.';

  @override
  String get errBandLoad => 'Couldn\'t load your bands. Check your connection.';

  @override
  String get errBandAction =>
      'That didn\'t work. Check your connection and try again.';

  @override
  String get errBandNotMatched =>
      'You can only propose people you\'ve matched with.';

  @override
  String get errBandAlreadyIn => 'They\'re already in the band.';

  @override
  String get errBandAlreadyProposed => 'They\'ve already been proposed.';

  @override
  String get errBandFull => 'A band can have at most 12 members.';

  @override
  String get errBandTooMany => 'You can be in at most 10 bands.';

  @override
  String get errBandAgeRule =>
      'A band needs at least 2 members before someone from another age group can join.';

  @override
  String get errBandUnavailable => 'This person isn\'t available.';

  @override
  String get errBandVoteOver => 'The vote on this person is already over.';

  @override
  String get errBandInviteClosed => 'This invite is no longer open.';

  @override
  String get errBandNotMember => 'You\'re not in this band anymore.';

  @override
  String get errBandNeedsProfile => 'Set up your profile first.';

  @override
  String get bandCancelRequest => 'Cancel request';

  @override
  String bandCancelTitle(String name) {
    return 'Cancel the request for $name?';
  }

  @override
  String get bandCancelBody =>
      'They won\'t be told. You can propose them again later.';

  @override
  String get bandCancelKeep => 'Keep it';

  @override
  String bandCancelled(String name) {
    return 'Request for $name cancelled.';
  }

  @override
  String get errBandCancelNotYours =>
      'Only the person who proposed them can cancel.';

  @override
  String get bandChatOpen => 'Open band chat';

  @override
  String get bandChatEmpty => 'No messages yet. Say hi to the band!';

  @override
  String get bandChatClosedAlone => 'Add a member to start the band chat.';

  @override
  String get bandChatClosedAges =>
      'The chat is paused: a band with teens and adults needs at least 3 members. It opens again when someone else joins.';

  @override
  String bandSeenBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seen by $count',
      one: 'Seen by 1',
    );
    return '$_temp0';
  }

  @override
  String get bandSeenByAll => 'Seen by everyone';

  @override
  String get bandMembersButton => 'Members';

  @override
  String bandMessagePreview(String name, String message) {
    return '$name: $message';
  }

  @override
  String get errBandSendClosed => 'The band chat is closed right now.';

  @override
  String bandMemberRole(String instrument, String band) {
    return '$instrument in $band';
  }

  @override
  String get resetSwipes => 'Reset my swipes (test)';

  @override
  String get resetSwipesDone => 'Your swipes are cleared. Everyone\'s back.';

  @override
  String get errResetSwipes =>
      'Couldn\'t reset your swipes. Check your connection.';

  @override
  String get reportMessage => 'Report this message';

  @override
  String get errBandProfile =>
      'Some of those genres or roles aren\'t on the list.';

  @override
  String get bandEditTitle => 'Edit band';

  @override
  String get bandEditHint =>
      'This is what musicians see on your band\'s card in their feed.';

  @override
  String get bandDescriptionLabel => 'About the band';

  @override
  String get bandDescriptionHint =>
      'What you play, what you\'re aiming for, how often you rehearse…';

  @override
  String get bandOpenRolesLabel => 'Looking for';

  @override
  String get bandOpenRolesHint =>
      'The instruments you\'d like to add. Musicians who play them see your band first.';

  @override
  String get bandProfileTitle => 'Band profile';

  @override
  String get bandProfileEmpty =>
      'Add a description, genres and the roles you\'re looking for, so musicians know what you\'re about.';

  @override
  String bandLookingFor(String roles) {
    return 'Looking for: $roles';
  }

  @override
  String get bandClipPlay => 'Play the band clip';

  @override
  String get bandClipStop => 'Stop the band clip';

  @override
  String get bandClipNone => 'No band clip yet';

  @override
  String bandClipLength(String length) {
    return 'Band clip · $length';
  }

  @override
  String get bandClipAdd => 'Record or upload a band clip';

  @override
  String get bandClipReplace => 'Replace the band clip';

  @override
  String get bandClipRemove => 'Remove the band clip';

  @override
  String get bandClipSave => 'Use as band clip';

  @override
  String get bandClipSaved => 'Band clip saved.';

  @override
  String get bandClipRemoved => 'Band clip removed.';

  @override
  String get bandProfileSaved => 'Band profile saved.';

  @override
  String get errBandRemoveSelf => 'To leave, use Leave band.';

  @override
  String get errBandNotInBand => 'They\'re not in the band anymore.';

  @override
  String get errBandRemovalExists =>
      'There\'s already a vote on removing them.';

  @override
  String bandMemberOptions(String name) {
    return 'Options for $name';
  }

  @override
  String get bandRemoveMember => 'Remove from band';

  @override
  String bandRemoveTitle(String name, String band) {
    return 'Remove $name from $band?';
  }

  @override
  String bandRemoveBody(String name) {
    return 'This starts a vote: a majority of the other members has to agree. $name won\'t see the vote.';
  }

  @override
  String get bandRemoveConfirm => 'Start the vote';

  @override
  String bandRemoveStarted(String name) {
    return 'Vote started on removing $name.';
  }

  @override
  String bandRemovedNow(String name) {
    return '$name was removed from the band.';
  }

  @override
  String get bandRemovalsHeading => 'Removing members';

  @override
  String bandRemovalCount(int yes, int needed) {
    return '$yes of $needed needed';
  }

  @override
  String get bandRemovalYes => 'Remove';

  @override
  String get bandRemovalNo => 'Keep';

  @override
  String get bandYouAgreed => 'You agreed';

  @override
  String get bandYouDisagreed => 'You said keep';

  @override
  String get bandRemovalCancel => 'Cancel vote';

  @override
  String get bandRemovalCancelled => 'Vote cancelled.';

  @override
  String bandCardSemantics(String name) {
    return 'Band: $name';
  }

  @override
  String get bandCardStamp => 'Band';

  @override
  String get bandCardNeedsYou => 'Needs your instrument';

  @override
  String bandAskedToJoin(String band) {
    return 'Asked to join $band. Its members will vote.';
  }

  @override
  String bandPassedOn(String band) {
    return 'Passed on $band.';
  }

  @override
  String get bandNoOpenRoles => 'Not looking for specific roles yet';

  @override
  String get bandSlotFilled => 'In the band';

  @override
  String get bandRequestsHeading => 'Asked to join';

  @override
  String get bandAskedToJoinLabel => 'Asked to join';

  @override
  String bandMemberJoined(String name) {
    return '$name joined the band!';
  }

  @override
  String get bandRequestWaiting =>
      'Asked to join · waiting for the band\'s vote';

  @override
  String get bandWithdraw => 'Withdraw';

  @override
  String get bandWithdrawn => 'Request withdrawn.';

  @override
  String get resetSwipesTitle => 'Reset all your swipes?';

  @override
  String get resetSwipesBody =>
      'Everyone you passed on or chose Jam on comes back, and bands too. Your matches and chats stay. This is a testing tool.';

  @override
  String get resetSwipesConfirm => 'Reset swipes';
}
