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
  String get authHaveAccount => 'I already have an account';

  @override
  String get authNewAccount => 'Create a new account';

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
  String get fieldGenresHint => 'Type a genre and press Enter';

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
  String get tagMax => 'You can add up to 10';

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
  String get swipeHint => 'Swipe right to Jam, left to Pass';

  @override
  String get swipeHintWeb =>
      'Swipe right to Jam, left to Pass, or use the arrow keys';

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
  String get clipsInfo =>
      'Up to 5 clips, 2 minutes each. Your first clip plays on your card.';

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
}
