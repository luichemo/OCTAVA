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
  String get fieldArea => 'Neighbourhood or city (optional)';

  @override
  String get fieldAreaHint =>
      'Where you live or rehearse, as you\'d tell a friend';

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
  String swipeHint(String jam, String pass) {
    return 'Swipe right to $jam, left to $pass';
  }

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
      'That\'s everyone for now. Invite musicians you know, or widen your filters.';

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
  String get seeTheirCard => 'See their card';

  @override
  String get openChat => 'Open chat';

  @override
  String get matchCardGone => 'This card isn\'t available any more.';

  @override
  String get errMatchCard =>
      'Couldn\'t load the card. Check your connection and try again.';

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
  String get themeColours => 'Colours';

  @override
  String get paletteOctava => 'OCTAVA';

  @override
  String get paletteSunset => 'Sunset';

  @override
  String get paletteGarage => 'Garage';

  @override
  String get paletteSynthwave => 'Synthwave';

  @override
  String get paletteMono => 'Mono';

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
  String get voiceMessage => '🎤 Voice message';

  @override
  String get voiceRecord => 'Record a voice message';

  @override
  String get voiceCancel => 'Cancel recording';

  @override
  String get voiceSend => 'Send voice message';

  @override
  String voiceRecording(String time) {
    return 'Recording… $time';
  }

  @override
  String get voicePlay => 'Play voice message';

  @override
  String get voiceStop => 'Stop voice message';

  @override
  String get editMessage => 'Edit message';

  @override
  String get editMessageHint =>
      'You can edit a message for 15 minutes after sending it.';

  @override
  String get editSave => 'Save';

  @override
  String editedAt(String time) {
    return 'edited · $time';
  }

  @override
  String get errEditTooLate => 'Messages can only be edited for 15 minutes.';

  @override
  String get errEdit => 'Couldn\'t edit the message. Try again.';

  @override
  String get rehearsalsTitle => 'Rehearsals';

  @override
  String get rehearsalAdd => 'Add';

  @override
  String get rehearsalsEmpty =>
      'No rehearsals planned. Add one, and everyone can say if they\'re coming.';

  @override
  String get rehearsalsShowAll => 'Show all';

  @override
  String get rehearsalsShowLess => 'Show less';

  @override
  String get rehearsalGoing => 'Going';

  @override
  String get rehearsalCant => 'Can\'t';

  @override
  String get rehearsalNoAnswer => 'No answer yet';

  @override
  String rehearsalCounts(int going, int cant) {
    return '$going going · $cant can\'t';
  }

  @override
  String get rehearsalCancelledLabel => 'Called off';

  @override
  String get rehearsalEdit => 'Edit rehearsal';

  @override
  String get rehearsalCallOff => 'Call off this date';

  @override
  String get rehearsalRestore => 'Put this date back';

  @override
  String get rehearsalDelete => 'Delete rehearsal';

  @override
  String get rehearsalDeleteTitle => 'Delete this rehearsal?';

  @override
  String get rehearsalDeleteBody => 'It disappears for everyone in the band.';

  @override
  String get rehearsalDeleteWeeklyBody =>
      'This deletes every week of it, for everyone in the band. To skip one week, call off that date instead.';

  @override
  String get rehearsalAdded => 'Rehearsal added.';

  @override
  String get rehearsalSaved => 'Rehearsal saved.';

  @override
  String get rehearsalCalledOff => 'That date is called off.';

  @override
  String get rehearsalDeleted => 'Rehearsal deleted.';

  @override
  String get rehearsalAddTitle => 'Add rehearsal';

  @override
  String get rehearsalEditTitle => 'Edit rehearsal';

  @override
  String get rehearsalDay => 'Day';

  @override
  String get rehearsalStart => 'Starts';

  @override
  String get rehearsalLength => 'Length';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get rehearsalPlace => 'Place (optional)';

  @override
  String get rehearsalPlaceHint => 'A studio, an address, or someone\'s place';

  @override
  String get rehearsalNotes => 'Notes (optional)';

  @override
  String get rehearsalNotesHint => 'What to bring, what to practise…';

  @override
  String get rehearsalWeekly => 'Repeat every week';

  @override
  String rehearsalWeeklyHint(String weekday) {
    return 'Every $weekday, same time';
  }

  @override
  String get rehearsalUntil => 'Until';

  @override
  String get rehearsalNoEnd => 'No end date';

  @override
  String get rehearsalClearEnd => 'No end date';

  @override
  String rehearsalReminder(String band, String time) {
    return '$band: rehearsal at $time';
  }

  @override
  String get rehearsalReminderBody => 'Starts soon. Tap to see who\'s coming.';

  @override
  String get errRehearsalsLoad =>
      'Couldn\'t load rehearsals. Check your connection.';

  @override
  String get errRehearsalSave => 'Couldn\'t save the rehearsal. Try again.';

  @override
  String get rehearsalsNoneThisWeek => 'Nothing in the next 7 days.';

  @override
  String recordLimitAt(String time) {
    return 'Recording stops by itself at $time.';
  }

  @override
  String get songsTitle => 'Songs';

  @override
  String get songsEmpty =>
      'No songs yet. Add the ones you play or want to learn.';

  @override
  String songsShowAll(int count) {
    return 'All $count songs';
  }

  @override
  String get songReady => 'Ready';

  @override
  String get songLearning => 'Learning';

  @override
  String get songIdea => 'Idea';

  @override
  String songBpm(int bpm) {
    return '$bpm BPM';
  }

  @override
  String get songPlay => 'Play the recording';

  @override
  String get songAddTitle => 'Add a song';

  @override
  String get songTitleLabel => 'Song title';

  @override
  String get songTitleError => 'Give the song a title.';

  @override
  String get songTempoError => 'Tempo should be a number between 20 and 320.';

  @override
  String get songPageTitle => 'Song';

  @override
  String get songKeyLabel => 'Key';

  @override
  String get songKeyHint => 'e.g. E minor';

  @override
  String get songTempoLabel => 'Tempo (BPM)';

  @override
  String get songNotesLabel => 'Notes';

  @override
  String get songNotesHint => 'Structure, capo, who sings what…';

  @override
  String get songLinksLabel => 'Links';

  @override
  String get songLinkHint => 'YouTube, Spotify, chords or lyrics link';

  @override
  String get songAddLink => 'Add link';

  @override
  String get songRemoveLink => 'Remove link';

  @override
  String get songRecordingLabel => 'Recording';

  @override
  String get songNoRecording => 'No recording yet';

  @override
  String get songAddRecording => 'Record or upload';

  @override
  String get songReplaceRecording => 'Replace the recording';

  @override
  String get songRemoveRecording => 'Remove the recording';

  @override
  String get songUseRecording => 'Use for this song';

  @override
  String get songRecordingSaved => 'Recording saved.';

  @override
  String get songSaved => 'Song saved.';

  @override
  String get songDelete => 'Delete song';

  @override
  String songDeleteTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get songDeleteBody =>
      'It and its recording disappear for everyone in the band.';

  @override
  String get errSongsLoad => 'Couldn\'t load the songs. Check your connection.';

  @override
  String get errSongSave => 'Couldn\'t save the song. Try again.';

  @override
  String errSongTooLong(String length) {
    return 'Song recordings can be up to 10 minutes. This one is $length.';
  }

  @override
  String get setlistsTitle => 'Setlists';

  @override
  String get setlistsEmpty =>
      'No setlists yet. Make one for your next gig or rehearsal.';

  @override
  String get setlistAddTitle => 'New setlist';

  @override
  String get setlistNameLabel => 'Setlist name';

  @override
  String get setlistNameHint => 'e.g. Friday gig';

  @override
  String get setlistPageTitle => 'Setlist';

  @override
  String setlistSongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String setlistNoLength(int count) {
    return '$count without a recording';
  }

  @override
  String get setlistEmptySongs =>
      'No songs in this setlist yet. Add some from the band\'s songs.';

  @override
  String get setlistAddSongs => 'Add songs';

  @override
  String setlistAddSongsButton(int count) {
    return 'Add $count';
  }

  @override
  String get setlistAllAdded => 'Every song is already in this setlist.';

  @override
  String get setlistNoBandSongs =>
      'The band has no songs yet. Add them under Songs first.';

  @override
  String get setlistRemoveSong => 'Remove from setlist';

  @override
  String get setlistDragHint => 'Hold a song and drag it to change the order.';

  @override
  String get setlistRename => 'Rename';

  @override
  String get setlistDelete => 'Delete setlist';

  @override
  String setlistDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get setlistDeleteBody =>
      'The songs stay in the band; only this list goes. Rehearsals that used it keep their other details.';

  @override
  String get setlistDeleted => 'Setlist deleted.';

  @override
  String get errSetlistsLoad =>
      'Couldn\'t load the setlists. Check your connection.';

  @override
  String get errSetlistSave => 'Couldn\'t save the setlist. Try again.';

  @override
  String get rehearsalSetlist => 'Setlist to practise';

  @override
  String get rehearsalNoSetlist => 'None';

  @override
  String rehearsalPractise(String name) {
    return 'Practise: $name';
  }

  @override
  String get publicPageTitle => 'Public page';

  @override
  String get publicPageOffHint =>
      'Off: only band members can see the band\'s page.';

  @override
  String get publicPageOnHint =>
      'On: anyone with the link can see the name, profile, clip, members and ready songs. Members aged 16–17 show only as their instrument.';

  @override
  String get publicPageCopy => 'Copy link';

  @override
  String get publicPageCopied => 'Link copied.';

  @override
  String get publicPageView => 'View page';

  @override
  String get publicPageTurnedOn => 'The band\'s public page is on.';

  @override
  String get publicPageTurnedOff => 'The public page is off.';

  @override
  String get publicBandSongs => 'Ready to play';

  @override
  String get publicBandNotFound =>
      'This band page isn\'t available. The band may have made it private.';

  @override
  String get publicBandJoin => 'Join OCTAVA';

  @override
  String get publicBandJoinHint =>
      'Musicians find each other and form bands on OCTAVA.';

  @override
  String get errPublicBandLoad =>
      'Couldn\'t load this band. Check your connection.';

  @override
  String get profileGroup => 'Profile';

  @override
  String get settingsGroup => 'Settings';

  @override
  String get summaryEmpty => 'Not set yet';

  @override
  String clipsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clips',
      one: '1 clip',
      zero: 'No clips yet',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, clips, avatar, matches, messages and band memberships. It can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete my account';

  @override
  String get accountDeleted => 'Your account was deleted.';

  @override
  String get errDeleteAccount =>
      'Couldn\'t delete your account. Check your connection and try again.';

  @override
  String get modGroup => 'Moderation';

  @override
  String get modReports => 'Reports';

  @override
  String modOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open reports',
      one: '1 open report',
      zero: 'No open reports',
    );
    return '$_temp0';
  }

  @override
  String get modEmpty => 'No open reports. All clear.';

  @override
  String modReportedBy(String name, String when) {
    return 'Reported by $name · $when';
  }

  @override
  String modAgainstCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open reports against them',
      one: '1 open report against them',
    );
    return '$_temp0';
  }

  @override
  String get modHiddenFromFeed => 'Hidden from the feed until reviewed';

  @override
  String get modSuspended => 'Suspended';

  @override
  String get modMessageGone => 'The message was already deleted.';

  @override
  String get modDismiss => 'Dismiss';

  @override
  String get modRemoveMessage => 'Remove message';

  @override
  String get modSuspend => 'Suspend';

  @override
  String get modUnsuspend => 'Lift suspension';

  @override
  String modSuspendTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String get modSuspendBody =>
      'They\'ll be hidden from the feed, signed out and unable to sign in. All their open reports will close.';

  @override
  String get modDismissed => 'Report dismissed.';

  @override
  String get modMessageRemoved => 'Message removed.';

  @override
  String modSuspendedDone(String name) {
    return '$name is suspended.';
  }

  @override
  String get modUnsuspended => 'Suspension lifted.';

  @override
  String get errModeration =>
      'Couldn\'t load or update the reports. Try again.';

  @override
  String get legalAgree => 'By creating an account you agree to the';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String get legalPrivacy => 'Privacy policy';

  @override
  String get legalTermsRow => 'Terms of use';

  @override
  String get legalPrivacyRow => 'Privacy policy';

  @override
  String get modViewProfile => 'View profile';

  @override
  String modEvidenceTitle(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Their last $count messages to $name',
      one: 'Their last message to $name',
    );
    return '$_temp0';
  }

  @override
  String get modEvidenceNote =>
      'Copied when the report was filed; it stays even if they delete the chat.';

  @override
  String modJoined(String date) {
    return 'Joined $date';
  }

  @override
  String get modProfileGone => 'This account no longer exists.';

  @override
  String get modModerators => 'Moderators';

  @override
  String modModeratorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moderators',
      one: '1 moderator',
    );
    return '$_temp0';
  }

  @override
  String get modSearchPeople => 'Search people by name';

  @override
  String get modSearchHint => 'Type at least 2 letters to find someone.';

  @override
  String get modNoOneFound => 'No one by that name.';

  @override
  String get modMakeModerator => 'Make moderator';

  @override
  String get modIsModerator => 'Moderator';

  @override
  String get modAdmin => 'Admin';

  @override
  String get modRemoveModerator => 'Remove';

  @override
  String modRemoveModeratorTitle(String name) {
    return 'Remove $name as a moderator?';
  }

  @override
  String get modRemoveModeratorBody =>
      'They\'ll stop seeing reports. You can add them again later.';

  @override
  String modMakeModeratorTitle(String name) {
    return 'Make $name a moderator?';
  }

  @override
  String get modMakeModeratorBody =>
      'They\'ll see every report, the reported messages and people\'s profiles, and can suspend accounts.';

  @override
  String modMadeModerator(String name) {
    return '$name is now a moderator.';
  }

  @override
  String modRemovedModerator(String name) {
    return '$name is no longer a moderator.';
  }

  @override
  String get errModSuspendedCant =>
      'A suspended account can\'t be a moderator.';

  @override
  String get errModAdminStays => 'An admin always stays a moderator.';

  @override
  String get authForgot => 'Forgot password?';

  @override
  String authResetSent(String email) {
    return 'If there\'s an account for $email, we\'ve sent it a link to choose a new password. Check your inbox and spam folder.';
  }

  @override
  String get resetTitle => 'Choose a new password';

  @override
  String get resetBody => 'You\'ll use it to sign in on every device.';

  @override
  String get resetNew => 'New password';

  @override
  String get resetRepeat => 'Repeat the password';

  @override
  String get resetMismatch => 'The passwords don\'t match.';

  @override
  String get resetSave => 'Save password';

  @override
  String get resetNotNow => 'Not now';

  @override
  String get resetDone => 'Password changed.';

  @override
  String get forgotTitle => 'Forgot your password?';

  @override
  String get forgotBody =>
      'Type the email you signed up with and we\'ll send you a link to choose a new password.';

  @override
  String get forgotSend => 'Send link';

  @override
  String get forgotSentTitle => 'Check your email';

  @override
  String get forgotHint =>
      'Didn\'t get it? Look in your spam folder, or send it again.';

  @override
  String get forgotResend => 'Send again';

  @override
  String forgotResendIn(int seconds) {
    return 'Send again in $seconds s';
  }

  @override
  String get errResetWait =>
      'Please wait a minute before asking for another link.';

  @override
  String get resetBack => 'Back to sign in';

  @override
  String get errResetLink =>
      'This link has expired or was already used. Ask for a new one on the sign-in screen.';

  @override
  String get errSamePassword =>
      'That\'s your current password. Pick a different one.';

  @override
  String get inviteGroup => 'Friends';

  @override
  String get inviteMusicians => 'Invite musicians';

  @override
  String get inviteSummary => 'Bring your bandmates and friends';

  @override
  String get inviteSubject => 'Join me on OCTAVA';

  @override
  String inviteMessage(String link) {
    return 'I\'m on OCTAVA, an app where musicians hear each other play and form bands. Join me: $link';
  }

  @override
  String get inviteCopied => 'Invite link copied. Paste it in a chat.';

  @override
  String get heardSection => 'One last thing';

  @override
  String get heardQuestion => 'Where did you hear about OCTAVA? (optional)';

  @override
  String get heardTiktok => 'TikTok';

  @override
  String get heardInstagram => 'Instagram';

  @override
  String get heardFriend => 'A friend';

  @override
  String get heardPoster => 'Poster or flyer';

  @override
  String get heardJamNight => 'Jam night';

  @override
  String get heardSearch => 'Search or app store';

  @override
  String get heardOther => 'Somewhere else';

  @override
  String get navMessages => 'Messages';

  @override
  String get navRequests => 'Requests';

  @override
  String get requestsInvites => 'Invites';

  @override
  String get requestsVotes => 'Your vote';

  @override
  String get requestsMine => 'You asked to join';

  @override
  String get requestsEmpty =>
      'Nothing waiting for you. Band invites, votes in your bands and your requests to join show up here.';

  @override
  String get bandsEmpty =>
      'You\'re not in a band yet. Create one, or Jam on a band card in the feed.';

  @override
  String requestVoteAsked(String band) {
    return 'Asked to join $band';
  }

  @override
  String requestVoteProposed(String band, String name) {
    return 'Proposed for $band by $name';
  }

  @override
  String requestVoteRemoval(String band) {
    return 'Vote on removing them from $band';
  }

  @override
  String get lineupEdit => 'Edit';

  @override
  String get lineupEditLabel => 'Choose the roles your band needs';

  @override
  String get lineupHint => 'Tap here to choose which musicians your band needs';
}
