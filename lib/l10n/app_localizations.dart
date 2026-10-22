import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ka'),
  ];

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach OCTAVA. Check your connection and try again.'**
  String get errOffline;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Find people to make music with.'**
  String get authTagline;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get authEmailError;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHelper;

  /// No description provided for @authPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordEmpty;

  /// No description provided for @authPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authPasswordShort;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email: we sent you a link to confirm your account. Open it, then sign in here.'**
  String get authCheckEmail;

  /// No description provided for @errEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'There is already an account with this email. Sign in instead.'**
  String get errEmailTaken;

  /// No description provided for @errBadLogin.
  ///
  /// In en, this message translates to:
  /// **'That email and password don\'t match an account.'**
  String get errBadLogin;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first: open the link we sent you, then sign in.'**
  String get errEmailNotConfirmed;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password: at least 8 characters, mixing letters and numbers.'**
  String get errWeakPassword;

  /// No description provided for @errEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errEmailInvalid;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get errTooManyAttempts;

  /// No description provided for @profileSetUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileSetUpTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is what other musicians see when they swipe.'**
  String get profileSubtitle;

  /// No description provided for @seeYourCard.
  ///
  /// In en, this message translates to:
  /// **'See your card'**
  String get seeYourCard;

  /// No description provided for @sectionAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get sectionAvatar;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get sectionAbout;

  /// No description provided for @sectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sectionLocation;

  /// No description provided for @sectionPlay.
  ///
  /// In en, this message translates to:
  /// **'What you play'**
  String get sectionPlay;

  /// No description provided for @sectionWant.
  ///
  /// In en, this message translates to:
  /// **'What you want'**
  String get sectionWant;

  /// No description provided for @sectionLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get sectionLinks;

  /// No description provided for @sectionClips.
  ///
  /// In en, this message translates to:
  /// **'Audio clips'**
  String get sectionClips;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the name people will see'**
  String get fieldNameError;

  /// No description provided for @fieldBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fieldBirthDate;

  /// No description provided for @fieldBirthDateHelper.
  ///
  /// In en, this message translates to:
  /// **'OCTAVA is for ages 16 and over. Others only see your age.'**
  String get fieldBirthDateHelper;

  /// No description provided for @fieldBirthDateError.
  ///
  /// In en, this message translates to:
  /// **'Enter your date of birth'**
  String get fieldBirthDateError;

  /// No description provided for @birthDatePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth'**
  String get birthDatePickerTitle;

  /// No description provided for @confirmBirthDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Is your date of birth right?'**
  String get confirmBirthDateTitle;

  /// No description provided for @confirmBirthDateBody.
  ///
  /// In en, this message translates to:
  /// **'{date}. You can\'t change it later, because it decides who you can meet on OCTAVA.'**
  String confirmBirthDateBody(String date);

  /// No description provided for @confirmBirthDateNo.
  ///
  /// In en, this message translates to:
  /// **'Change it'**
  String get confirmBirthDateNo;

  /// No description provided for @confirmBirthDateYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, it\'s right'**
  String get confirmBirthDateYes;

  /// No description provided for @fieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area (optional)'**
  String get fieldArea;

  /// No description provided for @fieldAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vake, Tbilisi'**
  String get fieldAreaHint;

  /// No description provided for @instrumentMain.
  ///
  /// In en, this message translates to:
  /// **'{instrument} (main)'**
  String instrumentMain(String instrument);

  /// No description provided for @pickInstrumentError.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one instrument'**
  String get pickInstrumentError;

  /// No description provided for @fieldGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get fieldGenres;

  /// No description provided for @rehearseQuestion.
  ///
  /// In en, this message translates to:
  /// **'How often can you rehearse?'**
  String get rehearseQuestion;

  /// No description provided for @gearQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you have?'**
  String get gearQuestion;

  /// No description provided for @fieldLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for? (optional)'**
  String get fieldLookingFor;

  /// No description provided for @fieldLookingForHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A band that rehearses weekly and plays shows'**
  String get fieldLookingForHint;

  /// No description provided for @linksLabel.
  ///
  /// In en, this message translates to:
  /// **'YouTube, TikTok, SoundCloud, Spotify…'**
  String get linksLabel;

  /// No description provided for @linksHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link and press Enter'**
  String get linksHint;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get addLink;

  /// No description provided for @removeLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get removeLink;

  /// No description provided for @linkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Paste a full web address, like youtube.com/watch?v=…'**
  String get linkInvalid;

  /// No description provided for @linkMax.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 6 links.'**
  String get linkMax;

  /// No description provided for @linkCheckError.
  ///
  /// In en, this message translates to:
  /// **'Check the link: it isn\'t a web address we can use.'**
  String get linkCheckError;

  /// No description provided for @answersMissing.
  ///
  /// In en, this message translates to:
  /// **'Some answers are missing. Check the fields marked in red above.'**
  String get answersMissing;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get createProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @errSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Try again in a moment.'**
  String get errSaveProfile;

  /// No description provided for @errUnder16.
  ///
  /// In en, this message translates to:
  /// **'OCTAVA is for people aged 16 and over.'**
  String get errUnder16;

  /// No description provided for @errBirthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a real date of birth.'**
  String get errBirthDateInvalid;

  /// No description provided for @genresChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose genres'**
  String get genresChoose;

  /// No description provided for @genresChange.
  ///
  /// In en, this message translates to:
  /// **'Change genres'**
  String get genresChange;

  /// No description provided for @genresSearch.
  ///
  /// In en, this message translates to:
  /// **'Search genres'**
  String get genresSearch;

  /// No description provided for @genresDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get genresDone;

  /// No description provided for @genresMax.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to 10 genres.'**
  String get genresMax;

  /// No description provided for @genresNoResults.
  ///
  /// In en, this message translates to:
  /// **'No genre matches that.'**
  String get genresNoResults;

  /// No description provided for @noClipsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re hidden from the feed'**
  String get noClipsTitle;

  /// No description provided for @noClipsBody.
  ///
  /// In en, this message translates to:
  /// **'Musicians without an audio clip don\'t appear when others swipe. Add at least one so people can hear you.'**
  String get noClipsBody;

  /// No description provided for @noClipsAction.
  ///
  /// In en, this message translates to:
  /// **'Record a clip'**
  String get noClipsAction;

  /// No description provided for @deckEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Everywhere'**
  String get deckEverywhere;

  /// No description provided for @deckWithin.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String deckWithin(int km);

  /// No description provided for @deckWithFilters.
  ///
  /// In en, this message translates to:
  /// **'{where}, {count, plural, =1{1 filter} other{{count} filters}}'**
  String deckWithFilters(String where, int count);

  /// No description provided for @stampJam.
  ///
  /// In en, this message translates to:
  /// **'Jam'**
  String get stampJam;

  /// No description provided for @stampPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get stampPass;

  /// First-time hint over the top card; jam and pass are the stamp words.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to {jam}, left to {pass}'**
  String swipeHint(String jam, String pass);

  /// No description provided for @actionJam.
  ///
  /// In en, this message translates to:
  /// **'Jam'**
  String get actionJam;

  /// No description provided for @actionPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get actionPass;

  /// No description provided for @passedOn.
  ///
  /// In en, this message translates to:
  /// **'Passed on {name}.'**
  String passedOn(String name);

  /// No description provided for @askedToJam.
  ///
  /// In en, this message translates to:
  /// **'You asked {name} to jam'**
  String askedToJam(String name);

  /// No description provided for @matchTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to jam too'**
  String matchTitle(String name);

  /// No description provided for @matchSlotFilled.
  ///
  /// In en, this message translates to:
  /// **'{instrument} is now filled in your band. Say hi and plan a first rehearsal.'**
  String matchSlotFilled(String instrument);

  /// No description provided for @matchSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'{holder} already plays {instrument} in your band, but you can still say hi.'**
  String matchSlotTaken(String holder, String instrument);

  /// No description provided for @matchSlotYours.
  ///
  /// In en, this message translates to:
  /// **'You already cover {instrument} yourself, but you can still say hi.'**
  String matchSlotYours(String instrument);

  /// No description provided for @saidHi.
  ///
  /// In en, this message translates to:
  /// **'You said hi to {name}'**
  String saidHi(String name);

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi'**
  String get sayHi;

  /// No description provided for @keepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep swiping'**
  String get keepSwiping;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get loadErrorTitle;

  /// No description provided for @errLoadMusiciansShort.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load musicians. Try again.'**
  String get errLoadMusiciansShort;

  /// No description provided for @noMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches'**
  String get noMatchTitle;

  /// No description provided for @noMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches your filters right now. Try fewer filters or a bigger distance.'**
  String get noMatchBody;

  /// No description provided for @changeFilters.
  ///
  /// In en, this message translates to:
  /// **'Change filters'**
  String get changeFilters;

  /// No description provided for @heardEveryoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve heard everyone'**
  String get heardEveryoneTitle;

  /// No description provided for @heardEveryoneBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s everyone for now. Invite musicians you know, or widen your filters.'**
  String get heardEveryoneBody;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @locationPrompt.
  ///
  /// In en, this message translates to:
  /// **'See how far away people are.'**
  String get locationPrompt;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// No description provided for @shareLocationShort.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocationShort;

  /// No description provided for @findingYou.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get findingYou;

  /// No description provided for @yourBand.
  ///
  /// In en, this message translates to:
  /// **'Your band'**
  String get yourBand;

  /// No description provided for @slotOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get slotOpen;

  /// No description provided for @slotYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get slotYou;

  /// No description provided for @cardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}, {instrument}'**
  String cardSemantics(String name, int age, String instrument);

  /// No description provided for @nameAge.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}'**
  String nameAge(String name, int age);

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @fitsSlot.
  ///
  /// In en, this message translates to:
  /// **'Fits your open {instrument} slot'**
  String fitsSlot(String instrument);

  /// No description provided for @plays.
  ///
  /// In en, this message translates to:
  /// **'Plays {genres}'**
  String plays(String genres);

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get listAnd;

  /// No description provided for @quoted.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String quoted(String text);

  /// No description provided for @noClip.
  ///
  /// In en, this message translates to:
  /// **'No clip to play'**
  String get noClip;

  /// No description provided for @playClipOf.
  ///
  /// In en, this message translates to:
  /// **'Play {name}\'s clip'**
  String playClipOf(String name);

  /// No description provided for @stopClipOf.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}\'s clip'**
  String stopClipOf(String name);

  /// No description provided for @blockOrReport.
  ///
  /// In en, this message translates to:
  /// **'Block or report'**
  String get blockOrReport;

  /// No description provided for @musicianFallback.
  ///
  /// In en, this message translates to:
  /// **'Musician'**
  String get musicianFallback;

  /// No description provided for @matchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTitle;

  /// No description provided for @matchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matches yet. When someone you chose Jam on chooses Jam on you too, they appear here.'**
  String get matchesEmpty;

  /// No description provided for @newMatchSayHi.
  ///
  /// In en, this message translates to:
  /// **'New match. Say hi!'**
  String get newMatchSayHi;

  /// No description provided for @youPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {message}'**
  String youPrefix(String message);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'You and {name} both want to jam. Say hi and plan a first rehearsal.'**
  String chatEmpty(String name);

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @chatLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages. Check your connection, then go back and open the chat again.'**
  String get chatLoadError;

  /// No description provided for @errLoadMatches.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your matches. Check your connection and try again.'**
  String get errLoadMatches;

  /// No description provided for @errSendBlocked.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send messages in this chat anymore.'**
  String get errSendBlocked;

  /// No description provided for @errSend.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message. Try again.'**
  String get errSend;

  /// No description provided for @errSendOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message. Check your connection and try again.'**
  String get errSendOffline;

  /// No description provided for @blockName.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String blockName(String name);

  /// No description provided for @blockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see each other and can\'t message. They aren\'t told.'**
  String get blockSubtitle;

  /// No description provided for @reportName.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportName(String name);

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about something wrong. Reports are private.'**
  String get reportSubtitle;

  /// No description provided for @blockedName.
  ///
  /// In en, this message translates to:
  /// **'You blocked {name}.'**
  String blockedName(String name);

  /// No description provided for @reportThanksBlocked.
  ///
  /// In en, this message translates to:
  /// **'Thanks for reporting. You also blocked {name}.'**
  String reportThanksBlocked(String name);

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for reporting. We review every report.'**
  String get reportThanks;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockConfirmTitle(String name);

  /// No description provided for @blockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see each other on OCTAVA anymore, and neither of you can send messages. {name} won\'t be told.'**
  String blockConfirmBody(String name);

  /// No description provided for @whatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get whatsWrong;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetails;

  /// No description provided for @alsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Also block {name}'**
  String alsoBlock(String name);

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @reasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or hate'**
  String get reasonHarassment;

  /// No description provided for @reasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate messages or content'**
  String get reasonInappropriate;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or a scam'**
  String get reasonSpam;

  /// No description provided for @reasonFake.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reasonFake;

  /// No description provided for @reasonUnderage.
  ///
  /// In en, this message translates to:
  /// **'Seems to be under 16'**
  String get reasonUnderage;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reasonOther;

  /// No description provided for @errBlock.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t block. Try again.'**
  String get errBlock;

  /// No description provided for @errBlockOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t block. Check your connection and try again.'**
  String get errBlockOffline;

  /// No description provided for @errReport.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your report. Check your connection and try again.'**
  String get errReport;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Record a clip'**
  String get navAdd;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'New clip'**
  String get recordTitle;

  /// No description provided for @recordStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting the microphone…'**
  String get recordStarting;

  /// No description provided for @recordRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordRecording;

  /// No description provided for @recordStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recordStop;

  /// No description provided for @recordDone.
  ///
  /// In en, this message translates to:
  /// **'Recorded {length}'**
  String recordDone(String length);

  /// No description provided for @recordSave.
  ///
  /// In en, this message translates to:
  /// **'Add to profile'**
  String get recordSave;

  /// No description provided for @recordListen.
  ///
  /// In en, this message translates to:
  /// **'Listen back'**
  String get recordListen;

  /// No description provided for @recordStopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get recordStopListening;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @recordUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload a file instead'**
  String get recordUploadFile;

  /// No description provided for @errMicDenied.
  ///
  /// In en, this message translates to:
  /// **'OCTAVA can\'t use your microphone. Allow it in your browser or phone settings, then try again.'**
  String get errMicDenied;

  /// No description provided for @errRecord.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t record. Try again.'**
  String get errRecord;

  /// No description provided for @errRecordShort.
  ///
  /// In en, this message translates to:
  /// **'That\'s too short. Record at least a second.'**
  String get errRecordShort;

  /// No description provided for @clipsInfo.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 clips, 2 minutes each. Star one to make it your card\'s song; otherwise your first clip plays.'**
  String get clipsInfo;

  /// No description provided for @clipMakeSong.
  ///
  /// In en, this message translates to:
  /// **'Make this your card\'s song'**
  String get clipMakeSong;

  /// No description provided for @clipIsSong.
  ///
  /// In en, this message translates to:
  /// **'Your card\'s song'**
  String get clipIsSong;

  /// No description provided for @errClipSong.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change your card\'s song. Check your connection and try again.'**
  String get errClipSong;

  /// No description provided for @clipAdded.
  ///
  /// In en, this message translates to:
  /// **'Clip added to your profile.'**
  String get clipAdded;

  /// No description provided for @deleteClipTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this clip?'**
  String get deleteClipTitle;

  /// No description provided for @deleteClipBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from your profile.'**
  String deleteClipBody(String title);

  /// No description provided for @clipFallback.
  ///
  /// In en, this message translates to:
  /// **'Clip'**
  String get clipFallback;

  /// No description provided for @deleteClip.
  ///
  /// In en, this message translates to:
  /// **'Delete clip'**
  String get deleteClip;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @clipsFull.
  ///
  /// In en, this message translates to:
  /// **'You have 5 clips'**
  String get clipsFull;

  /// No description provided for @addClip.
  ///
  /// In en, this message translates to:
  /// **'Add a clip'**
  String get addClip;

  /// No description provided for @errOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your files. Restart the app and try again.'**
  String get errOpenFiles;

  /// No description provided for @errClipsLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your clips. Check your connection and try again.'**
  String get errClipsLoad;

  /// No description provided for @errClipType.
  ///
  /// In en, this message translates to:
  /// **'Use an MP3, M4A, AAC, WAV, OGG, WEBM or FLAC file.'**
  String get errClipType;

  /// No description provided for @errClipSize.
  ///
  /// In en, this message translates to:
  /// **'That file is over 10 MB. Try a shorter or more compressed clip.'**
  String get errClipSize;

  /// No description provided for @errClipsMax.
  ///
  /// In en, this message translates to:
  /// **'You can have up to 5 clips. Delete one to add another.'**
  String get errClipsMax;

  /// No description provided for @errClipUpload.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your clip. Check your connection and try again.'**
  String get errClipUpload;

  /// No description provided for @errClipUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play that file. Try exporting it as MP3 or M4A.'**
  String get errClipUnreadable;

  /// No description provided for @errClipTooLong.
  ///
  /// In en, this message translates to:
  /// **'Clips can be up to 2 minutes. This one is {length}.'**
  String errClipTooLong(String length);

  /// No description provided for @errClipSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your clip. Try again.'**
  String get errClipSave;

  /// No description provided for @errClipDelete.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the clip. Check your connection and try again.'**
  String get errClipDelete;

  /// No description provided for @errClipPlay.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play the clip. Check your connection and try again.'**
  String get errClipPlay;

  /// No description provided for @avatarPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting your avatar… this takes a few seconds.'**
  String get avatarPainting;

  /// No description provided for @avatarInfo.
  ///
  /// In en, this message translates to:
  /// **'A riso-print illustration made by AI from your main instrument and genres.'**
  String get avatarInfo;

  /// No description provided for @avatarGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate my avatar'**
  String get avatarGenerate;

  /// No description provided for @avatarNew.
  ///
  /// In en, this message translates to:
  /// **'Make a new one'**
  String get avatarNew;

  /// No description provided for @avatarRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more today} other{{count} more today}}'**
  String avatarRemaining(int count);

  /// No description provided for @errAvatarLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your avatar. Check your connection and try again.'**
  String get errAvatarLoad;

  /// No description provided for @errAvatarGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make an avatar right now. Try again.'**
  String get errAvatarGeneric;

  /// No description provided for @errAvatarOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make an avatar. Check your connection and try again.'**
  String get errAvatarOffline;

  /// No description provided for @errAvatarDaily.
  ///
  /// In en, this message translates to:
  /// **'You\'ve made 5 avatars today. Try again tomorrow.'**
  String get errAvatarDaily;

  /// No description provided for @errAvatarBusy.
  ///
  /// In en, this message translates to:
  /// **'Too many avatars are being made right now. Try again later.'**
  String get errAvatarBusy;

  /// No description provided for @errAvatarNotReady.
  ///
  /// In en, this message translates to:
  /// **'Avatar generation isn\'t set up yet. Try again later.'**
  String get errAvatarNotReady;

  /// No description provided for @locationSharing.
  ///
  /// In en, this message translates to:
  /// **'You share an approximate location (to about 1 km). People see how far away you are, never where you are.'**
  String get locationSharing;

  /// No description provided for @locationNotSharing.
  ///
  /// In en, this message translates to:
  /// **'You don\'t share a location, so nobody sees distances to you and distance filters are off.'**
  String get locationNotSharing;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved.'**
  String get locationSaved;

  /// No description provided for @updateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get updateLocation;

  /// No description provided for @locationStopped.
  ///
  /// In en, this message translates to:
  /// **'You no longer share a location.'**
  String get locationStopped;

  /// No description provided for @stopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get stopSharing;

  /// No description provided for @errLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on this device. Turn it on and try again.'**
  String get errLocationOff;

  /// No description provided for @errLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'OCTAVA isn\'t allowed to use your location. Allow it in your browser or phone settings, then try again.'**
  String get errLocationDenied;

  /// No description provided for @errLocationFind.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location. Try again in a moment.'**
  String get errLocationFind;

  /// No description provided for @errLocationSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your location. Check your connection and try again.'**
  String get errLocationSave;

  /// No description provided for @errLocationRemove.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove your location. Check your connection and try again.'**
  String get errLocationRemove;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @filterDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterDistance;

  /// No description provided for @filterDistanceNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Share your location to filter by distance. Until then you see everyone.'**
  String get filterDistanceNoLocation;

  /// No description provided for @kmShort.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmShort(int km);

  /// No description provided for @anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get anywhere;

  /// No description provided for @filterInstruments.
  ///
  /// In en, this message translates to:
  /// **'Instruments'**
  String get filterInstruments;

  /// No description provided for @filterInstrumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Show only people who play these. Leave empty for everyone.'**
  String get filterInstrumentsHint;

  /// No description provided for @filterSkill.
  ///
  /// In en, this message translates to:
  /// **'Lowest skill level'**
  String get filterSkill;

  /// No description provided for @filterSkillNeedsInstruments.
  ///
  /// In en, this message translates to:
  /// **'Pick instruments first; the skill level applies to them.'**
  String get filterSkillNeedsInstruments;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @skillOrBetter.
  ///
  /// In en, this message translates to:
  /// **'{skill} or better'**
  String skillOrBetter(String skill);

  /// No description provided for @filterGenresHint.
  ///
  /// In en, this message translates to:
  /// **'Show people who play at least one of these.'**
  String get filterGenresHint;

  /// No description provided for @filterGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get filterGoals;

  /// No description provided for @filterRehearses.
  ///
  /// In en, this message translates to:
  /// **'Rehearses'**
  String get filterRehearses;

  /// No description provided for @showMusicians.
  ///
  /// In en, this message translates to:
  /// **'Show musicians'**
  String get showMusicians;

  /// No description provided for @errLoadMusicians.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load musicians. Check your connection and try again.'**
  String get errLoadMusicians;

  /// No description provided for @errSaveSwipe.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Check your connection and try again.'**
  String get errSaveSwipe;

  /// No description provided for @errLoadBand.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your band. Check your connection and try again.'**
  String get errLoadBand;

  /// No description provided for @yourCard.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get yourCard;

  /// No description provided for @cardPreviewInfo.
  ///
  /// In en, this message translates to:
  /// **'This is how other musicians see you. Distance shows for them once you both share a location.'**
  String get cardPreviewInfo;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get languageDevice;

  /// No description provided for @languageInfo.
  ///
  /// In en, this message translates to:
  /// **'\"Device\" follows your phone or browser language.'**
  String get languageInfo;

  /// No description provided for @instrumentVocals.
  ///
  /// In en, this message translates to:
  /// **'Vocals'**
  String get instrumentVocals;

  /// No description provided for @instrumentGuitar.
  ///
  /// In en, this message translates to:
  /// **'Guitar'**
  String get instrumentGuitar;

  /// No description provided for @instrumentBass.
  ///
  /// In en, this message translates to:
  /// **'Bass'**
  String get instrumentBass;

  /// No description provided for @instrumentDrums.
  ///
  /// In en, this message translates to:
  /// **'Drums'**
  String get instrumentDrums;

  /// No description provided for @instrumentKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get instrumentKeys;

  /// No description provided for @instrumentPercussion.
  ///
  /// In en, this message translates to:
  /// **'Percussion'**
  String get instrumentPercussion;

  /// No description provided for @instrumentViolin.
  ///
  /// In en, this message translates to:
  /// **'Violin'**
  String get instrumentViolin;

  /// No description provided for @instrumentCello.
  ///
  /// In en, this message translates to:
  /// **'Cello'**
  String get instrumentCello;

  /// No description provided for @instrumentSaxophone.
  ///
  /// In en, this message translates to:
  /// **'Saxophone'**
  String get instrumentSaxophone;

  /// No description provided for @instrumentTrumpet.
  ///
  /// In en, this message translates to:
  /// **'Trumpet'**
  String get instrumentTrumpet;

  /// No description provided for @instrumentTrombone.
  ///
  /// In en, this message translates to:
  /// **'Trombone'**
  String get instrumentTrombone;

  /// No description provided for @instrumentFlute.
  ///
  /// In en, this message translates to:
  /// **'Flute'**
  String get instrumentFlute;

  /// No description provided for @instrumentClarinet.
  ///
  /// In en, this message translates to:
  /// **'Clarinet'**
  String get instrumentClarinet;

  /// No description provided for @instrumentDj.
  ///
  /// In en, this message translates to:
  /// **'DJ'**
  String get instrumentDj;

  /// No description provided for @instrumentProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get instrumentProduction;

  /// No description provided for @instrumentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get instrumentOther;

  /// No description provided for @skillBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get skillBeginner;

  /// No description provided for @skillIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get skillIntermediate;

  /// No description provided for @skillAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get skillAdvanced;

  /// No description provided for @skillPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get skillPro;

  /// No description provided for @goalFun.
  ///
  /// In en, this message translates to:
  /// **'For fun'**
  String get goalFun;

  /// No description provided for @goalGigging.
  ///
  /// In en, this message translates to:
  /// **'Gigging'**
  String get goalGigging;

  /// No description provided for @goalRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get goalRecording;

  /// No description provided for @goalPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid work'**
  String get goalPaid;

  /// No description provided for @freqOccasionally.
  ///
  /// In en, this message translates to:
  /// **'Now and then'**
  String get freqOccasionally;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqSeveralAWeek.
  ///
  /// In en, this message translates to:
  /// **'Several times a week'**
  String get freqSeveralAWeek;

  /// No description provided for @gearOwnGear.
  ///
  /// In en, this message translates to:
  /// **'Own gear'**
  String get gearOwnGear;

  /// No description provided for @gearCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get gearCar;

  /// No description provided for @gearRehearsalSpace.
  ///
  /// In en, this message translates to:
  /// **'Rehearsal space'**
  String get gearRehearsalSpace;

  /// No description provided for @gearHomeStudio.
  ///
  /// In en, this message translates to:
  /// **'Home studio'**
  String get gearHomeStudio;

  /// No description provided for @linkWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get linkWebsite;

  /// No description provided for @genreRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get genreRock;

  /// No description provided for @genrePop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get genrePop;

  /// No description provided for @genreIndie.
  ///
  /// In en, this message translates to:
  /// **'Indie'**
  String get genreIndie;

  /// No description provided for @genreAltRock.
  ///
  /// In en, this message translates to:
  /// **'Alternative rock'**
  String get genreAltRock;

  /// No description provided for @genrePunk.
  ///
  /// In en, this message translates to:
  /// **'Punk'**
  String get genrePunk;

  /// No description provided for @genrePostPunk.
  ///
  /// In en, this message translates to:
  /// **'Post-punk'**
  String get genrePostPunk;

  /// No description provided for @genreHardcore.
  ///
  /// In en, this message translates to:
  /// **'Hardcore'**
  String get genreHardcore;

  /// No description provided for @genreMetal.
  ///
  /// In en, this message translates to:
  /// **'Metal'**
  String get genreMetal;

  /// No description provided for @genreGrunge.
  ///
  /// In en, this message translates to:
  /// **'Grunge'**
  String get genreGrunge;

  /// No description provided for @genreMathRock.
  ///
  /// In en, this message translates to:
  /// **'Math rock'**
  String get genreMathRock;

  /// No description provided for @genrePostRock.
  ///
  /// In en, this message translates to:
  /// **'Post-rock'**
  String get genrePostRock;

  /// No description provided for @genreShoegaze.
  ///
  /// In en, this message translates to:
  /// **'Shoegaze'**
  String get genreShoegaze;

  /// No description provided for @genreDreamPop.
  ///
  /// In en, this message translates to:
  /// **'Dream pop'**
  String get genreDreamPop;

  /// No description provided for @genreSynthPop.
  ///
  /// In en, this message translates to:
  /// **'Synth-pop'**
  String get genreSynthPop;

  /// No description provided for @genreCityPop.
  ///
  /// In en, this message translates to:
  /// **'City pop'**
  String get genreCityPop;

  /// No description provided for @genreDisco.
  ///
  /// In en, this message translates to:
  /// **'Disco'**
  String get genreDisco;

  /// No description provided for @genreFunk.
  ///
  /// In en, this message translates to:
  /// **'Funk'**
  String get genreFunk;

  /// No description provided for @genreSoul.
  ///
  /// In en, this message translates to:
  /// **'Soul'**
  String get genreSoul;

  /// No description provided for @genreNeoSoul.
  ///
  /// In en, this message translates to:
  /// **'Neo-soul'**
  String get genreNeoSoul;

  /// No description provided for @genreRAndB.
  ///
  /// In en, this message translates to:
  /// **'R&B'**
  String get genreRAndB;

  /// No description provided for @genreHipHop.
  ///
  /// In en, this message translates to:
  /// **'Hip-hop'**
  String get genreHipHop;

  /// No description provided for @genreRap.
  ///
  /// In en, this message translates to:
  /// **'Rap'**
  String get genreRap;

  /// No description provided for @genreJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get genreJazz;

  /// No description provided for @genreBlues.
  ///
  /// In en, this message translates to:
  /// **'Blues'**
  String get genreBlues;

  /// No description provided for @genreGospel.
  ///
  /// In en, this message translates to:
  /// **'Gospel'**
  String get genreGospel;

  /// No description provided for @genreElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get genreElectronic;

  /// No description provided for @genreTechno.
  ///
  /// In en, this message translates to:
  /// **'Techno'**
  String get genreTechno;

  /// No description provided for @genreHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get genreHouse;

  /// No description provided for @genreAmbient.
  ///
  /// In en, this message translates to:
  /// **'Ambient'**
  String get genreAmbient;

  /// No description provided for @genreLoFi.
  ///
  /// In en, this message translates to:
  /// **'Lo-fi'**
  String get genreLoFi;

  /// No description provided for @genreExperimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get genreExperimental;

  /// No description provided for @genreFolk.
  ///
  /// In en, this message translates to:
  /// **'Folk'**
  String get genreFolk;

  /// No description provided for @genreIndieFolk.
  ///
  /// In en, this message translates to:
  /// **'Indie folk'**
  String get genreIndieFolk;

  /// No description provided for @genreGeorgianFolk.
  ///
  /// In en, this message translates to:
  /// **'Georgian folk'**
  String get genreGeorgianFolk;

  /// No description provided for @genreSingerSongwriter.
  ///
  /// In en, this message translates to:
  /// **'Singer-songwriter'**
  String get genreSingerSongwriter;

  /// No description provided for @genreCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get genreCountry;

  /// No description provided for @genreReggae.
  ///
  /// In en, this message translates to:
  /// **'Reggae'**
  String get genreReggae;

  /// No description provided for @genreSka.
  ///
  /// In en, this message translates to:
  /// **'Ska'**
  String get genreSka;

  /// No description provided for @genreLatin.
  ///
  /// In en, this message translates to:
  /// **'Latin'**
  String get genreLatin;

  /// No description provided for @genreWorld.
  ///
  /// In en, this message translates to:
  /// **'World music'**
  String get genreWorld;

  /// No description provided for @genreClassical.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get genreClassical;

  /// No description provided for @genreSoundtrack.
  ///
  /// In en, this message translates to:
  /// **'Soundtrack'**
  String get genreSoundtrack;

  /// No description provided for @bandEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get bandEdit;

  /// No description provided for @bandRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Who does your band need?'**
  String get bandRolesTitle;

  /// No description provided for @bandRolesHint.
  ///
  /// In en, this message translates to:
  /// **'Room for up to {max} people besides you.'**
  String bandRolesHint(int max);

  /// No description provided for @bandRolesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max}'**
  String bandRolesCount(int count, int max);

  /// No description provided for @bandRolesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one role.'**
  String get bandRolesEmpty;

  /// No description provided for @bandRolesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bandRolesSave;

  /// No description provided for @roleMore.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get roleMore;

  /// No description provided for @roleFewer.
  ///
  /// In en, this message translates to:
  /// **'One fewer'**
  String get roleFewer;

  /// No description provided for @roleCount.
  ///
  /// In en, this message translates to:
  /// **'{instrument} ×{count}'**
  String roleCount(String instrument, int count);

  /// No description provided for @sectionBand.
  ///
  /// In en, this message translates to:
  /// **'Your band needs'**
  String get sectionBand;

  /// No description provided for @bandChange.
  ///
  /// In en, this message translates to:
  /// **'Change roles'**
  String get bandChange;

  /// No description provided for @bandDefaultNote.
  ///
  /// In en, this message translates to:
  /// **'Not chosen yet, so these are the usual roles.'**
  String get bandDefaultNote;

  /// No description provided for @matchNoSlot.
  ///
  /// In en, this message translates to:
  /// **'Your band isn\'t looking for {instrument} right now, but you can still say hi.'**
  String matchNoSlot(String instrument);

  /// No description provided for @errSaveBand.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your band\'s roles. Check your connection and try again.'**
  String get errSaveBand;

  /// No description provided for @bannerNewMatch.
  ///
  /// In en, this message translates to:
  /// **'You both want to play together. Tap to say hi.'**
  String get bannerNewMatch;

  /// No description provided for @seen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seen;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @chatMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chatMore;

  /// No description provided for @unmatch.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get unmatch;

  /// No description provided for @unmatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Unmatch {name}?'**
  String unmatchTitle(String name);

  /// No description provided for @unmatchBody.
  ///
  /// In en, this message translates to:
  /// **'This chat will disappear for both of you. You can\'t undo this.'**
  String get unmatchBody;

  /// No description provided for @unmatchDone.
  ///
  /// In en, this message translates to:
  /// **'You unmatched {name}.'**
  String unmatchDone(String name);

  /// No description provided for @errUnmatch.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unmatch. Check your connection and try again.'**
  String get errUnmatch;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @errUndo.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t bring the card back. Check your connection and try again.'**
  String get errUndo;

  /// No description provided for @authHeadline.
  ///
  /// In en, this message translates to:
  /// **'Swipe. Jam. Form a band.'**
  String get authHeadline;

  /// No description provided for @authAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'16+ musicians only'**
  String get authAgeTitle;

  /// No description provided for @authAgeBody.
  ///
  /// In en, this message translates to:
  /// **'By joining, you confirm you\'re 16 or older.'**
  String get authAgeBody;

  /// No description provided for @bandFilled.
  ///
  /// In en, this message translates to:
  /// **'{filled} of {total} filled'**
  String bandFilled(int filled, int total);

  /// No description provided for @sectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get sectionTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeColours.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get themeColours;

  /// No description provided for @paletteOctava.
  ///
  /// In en, this message translates to:
  /// **'OCTAVA'**
  String get paletteOctava;

  /// No description provided for @paletteSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get paletteSunset;

  /// No description provided for @paletteGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get paletteGarage;

  /// No description provided for @paletteSynthwave.
  ///
  /// In en, this message translates to:
  /// **'Synthwave'**
  String get paletteSynthwave;

  /// No description provided for @paletteMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get paletteMono;

  /// No description provided for @themeInfo.
  ///
  /// In en, this message translates to:
  /// **'\"Device\" follows your phone or browser setting.'**
  String get themeInfo;

  /// No description provided for @themeToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get themeToDark;

  /// No description provided for @themeToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get themeToLight;

  /// Under the name on a card: the person's other instruments with skill, e.g. 'Guitar · Pro, Keys · Advanced'.
  ///
  /// In en, this message translates to:
  /// **'Also: {instruments}'**
  String cardAlsoPlays(String instruments);

  /// No description provided for @instrumentMakeMain.
  ///
  /// In en, this message translates to:
  /// **'Make this your main instrument'**
  String get instrumentMakeMain;

  /// No description provided for @instrumentIsMain.
  ///
  /// In en, this message translates to:
  /// **'Your main instrument'**
  String get instrumentIsMain;

  /// Sign-up failed because the project's email sending limit was reached (affects everyone).
  ///
  /// In en, this message translates to:
  /// **'Sign-ups are busy right now. Please try again in an hour.'**
  String get errEmailBusy;

  /// No description provided for @clipPosition.
  ///
  /// In en, this message translates to:
  /// **'Position in the clip'**
  String get clipPosition;

  /// No description provided for @bandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bands'**
  String get bandsTitle;

  /// No description provided for @bandCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a band'**
  String get bandCreate;

  /// No description provided for @bandCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Name your band'**
  String get bandCreateTitle;

  /// No description provided for @bandNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Band name'**
  String get bandNameLabel;

  /// No description provided for @bandNameError.
  ///
  /// In en, this message translates to:
  /// **'Give your band a name'**
  String get bandNameError;

  /// No description provided for @bandCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get bandCreateConfirm;

  /// No description provided for @bandInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'{band} wants you to join'**
  String bandInviteTitle(String band);

  /// No description provided for @bandAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get bandAccept;

  /// No description provided for @bandDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get bandDecline;

  /// No description provided for @bandJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined {band}!'**
  String bandJoined(String band);

  /// No description provided for @bandMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String bandMemberCount(int count);

  /// No description provided for @bandVotesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vote waiting for you} other{{count} votes waiting for you}}'**
  String bandVotesWaiting(int count);

  /// No description provided for @bandMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get bandMembers;

  /// No description provided for @bandYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get bandYou;

  /// No description provided for @bandAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get bandAddMember;

  /// No description provided for @bandAddMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose one of your matches'**
  String get bandAddMemberTitle;

  /// No description provided for @bandAddMemberEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody left to propose. Match with more musicians first.'**
  String get bandAddMemberEmpty;

  /// No description provided for @bandProposedVote.
  ///
  /// In en, this message translates to:
  /// **'Proposed {name}. Your bandmates will vote.'**
  String bandProposedVote(String name);

  /// No description provided for @bandProposedInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {name}.'**
  String bandProposedInvite(String name);

  /// Heading on a band's page above people proposed as new members (being voted on or invited).
  ///
  /// In en, this message translates to:
  /// **'New members'**
  String get bandWaiting;

  /// No description provided for @bandProposedBy.
  ///
  /// In en, this message translates to:
  /// **'Proposed by {name}'**
  String bandProposedBy(String name);

  /// No description provided for @bandApprovals.
  ///
  /// In en, this message translates to:
  /// **'{yes} of {total} approved'**
  String bandApprovals(int yes, int total);

  /// No description provided for @bandApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get bandApprove;

  /// No description provided for @bandReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get bandReject;

  /// No description provided for @bandYouApproved.
  ///
  /// In en, this message translates to:
  /// **'You approved'**
  String get bandYouApproved;

  /// No description provided for @bandInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited, waiting for their answer'**
  String get bandInvited;

  /// No description provided for @bandRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}?'**
  String bandRejectTitle(String name);

  /// No description provided for @bandRejectBody.
  ///
  /// In en, this message translates to:
  /// **'One no is enough: they won\'t be invited, and they won\'t be told.'**
  String get bandRejectBody;

  /// No description provided for @bandLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave band'**
  String get bandLeave;

  /// No description provided for @bandLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {band}?'**
  String bandLeaveTitle(String band);

  /// No description provided for @bandLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop seeing its members and votes. If you\'re the last member, the band is deleted.'**
  String get bandLeaveBody;

  /// No description provided for @errBandLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your bands. Check your connection.'**
  String get errBandLoad;

  /// No description provided for @errBandAction.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Check your connection and try again.'**
  String get errBandAction;

  /// No description provided for @errBandNotMatched.
  ///
  /// In en, this message translates to:
  /// **'You can only propose people you\'ve matched with.'**
  String get errBandNotMatched;

  /// No description provided for @errBandAlreadyIn.
  ///
  /// In en, this message translates to:
  /// **'They\'re already in the band.'**
  String get errBandAlreadyIn;

  /// No description provided for @errBandAlreadyProposed.
  ///
  /// In en, this message translates to:
  /// **'They\'ve already been proposed.'**
  String get errBandAlreadyProposed;

  /// No description provided for @errBandFull.
  ///
  /// In en, this message translates to:
  /// **'A band can have at most 12 members.'**
  String get errBandFull;

  /// No description provided for @errBandTooMany.
  ///
  /// In en, this message translates to:
  /// **'You can be in at most 10 bands.'**
  String get errBandTooMany;

  /// No description provided for @errBandAgeRule.
  ///
  /// In en, this message translates to:
  /// **'A band needs at least 2 members before someone from another age group can join.'**
  String get errBandAgeRule;

  /// No description provided for @errBandUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This person isn\'t available.'**
  String get errBandUnavailable;

  /// No description provided for @errBandVoteOver.
  ///
  /// In en, this message translates to:
  /// **'The vote on this person is already over.'**
  String get errBandVoteOver;

  /// No description provided for @errBandInviteClosed.
  ///
  /// In en, this message translates to:
  /// **'This invite is no longer open.'**
  String get errBandInviteClosed;

  /// No description provided for @errBandNotMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in this band anymore.'**
  String get errBandNotMember;

  /// No description provided for @errBandNeedsProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile first.'**
  String get errBandNeedsProfile;

  /// No description provided for @bandCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get bandCancelRequest;

  /// No description provided for @bandCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the request for {name}?'**
  String bandCancelTitle(String name);

  /// No description provided for @bandCancelBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be told. You can propose them again later.'**
  String get bandCancelBody;

  /// No description provided for @bandCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get bandCancelKeep;

  /// No description provided for @bandCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request for {name} cancelled.'**
  String bandCancelled(String name);

  /// No description provided for @errBandCancelNotYours.
  ///
  /// In en, this message translates to:
  /// **'Only the person who proposed them can cancel.'**
  String get errBandCancelNotYours;

  /// No description provided for @bandChatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open band chat'**
  String get bandChatOpen;

  /// No description provided for @bandChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi to the band!'**
  String get bandChatEmpty;

  /// No description provided for @bandChatClosedAlone.
  ///
  /// In en, this message translates to:
  /// **'Add a member to start the band chat.'**
  String get bandChatClosedAlone;

  /// No description provided for @bandChatClosedAges.
  ///
  /// In en, this message translates to:
  /// **'The chat is paused: a band with teens and adults needs at least 3 members. It opens again when someone else joins.'**
  String get bandChatClosedAges;

  /// No description provided for @bandSeenBy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Seen by 1} other{Seen by {count}}}'**
  String bandSeenBy(int count);

  /// No description provided for @bandSeenByAll.
  ///
  /// In en, this message translates to:
  /// **'Seen by everyone'**
  String get bandSeenByAll;

  /// No description provided for @bandMembersButton.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get bandMembersButton;

  /// No description provided for @bandMessagePreview.
  ///
  /// In en, this message translates to:
  /// **'{name}: {message}'**
  String bandMessagePreview(String name, String message);

  /// No description provided for @errBandSendClosed.
  ///
  /// In en, this message translates to:
  /// **'The band chat is closed right now.'**
  String get errBandSendClosed;

  /// In the pop-up about a bandmate: their role, e.g. 'Drums in Riot'.
  ///
  /// In en, this message translates to:
  /// **'{instrument} in {band}'**
  String bandMemberRole(String instrument, String band);

  /// No description provided for @reportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report this message'**
  String get reportMessage;

  /// No description provided for @errBandProfile.
  ///
  /// In en, this message translates to:
  /// **'Some of those genres or roles aren\'t on the list.'**
  String get errBandProfile;

  /// No description provided for @bandEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit band'**
  String get bandEditTitle;

  /// No description provided for @bandEditHint.
  ///
  /// In en, this message translates to:
  /// **'This is what musicians see on your band\'s card in their feed.'**
  String get bandEditHint;

  /// No description provided for @bandDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'About the band'**
  String get bandDescriptionLabel;

  /// No description provided for @bandDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What you play, what you\'re aiming for, how often you rehearse…'**
  String get bandDescriptionHint;

  /// No description provided for @bandOpenRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get bandOpenRolesLabel;

  /// No description provided for @bandOpenRolesHint.
  ///
  /// In en, this message translates to:
  /// **'The instruments you\'d like to add. Musicians who play them see your band first.'**
  String get bandOpenRolesHint;

  /// No description provided for @bandProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Band profile'**
  String get bandProfileTitle;

  /// No description provided for @bandProfileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a description, genres and the roles you\'re looking for, so musicians know what you\'re about.'**
  String get bandProfileEmpty;

  /// No description provided for @bandLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for: {roles}'**
  String bandLookingFor(String roles);

  /// No description provided for @bandClipPlay.
  ///
  /// In en, this message translates to:
  /// **'Play the band clip'**
  String get bandClipPlay;

  /// No description provided for @bandClipStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the band clip'**
  String get bandClipStop;

  /// No description provided for @bandClipNone.
  ///
  /// In en, this message translates to:
  /// **'No band clip yet'**
  String get bandClipNone;

  /// No description provided for @bandClipLength.
  ///
  /// In en, this message translates to:
  /// **'Band clip · {length}'**
  String bandClipLength(String length);

  /// No description provided for @bandClipAdd.
  ///
  /// In en, this message translates to:
  /// **'Record or upload a band clip'**
  String get bandClipAdd;

  /// No description provided for @bandClipReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace the band clip'**
  String get bandClipReplace;

  /// No description provided for @bandClipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the band clip'**
  String get bandClipRemove;

  /// No description provided for @bandClipSave.
  ///
  /// In en, this message translates to:
  /// **'Use as band clip'**
  String get bandClipSave;

  /// No description provided for @bandClipSaved.
  ///
  /// In en, this message translates to:
  /// **'Band clip saved.'**
  String get bandClipSaved;

  /// No description provided for @bandClipRemoved.
  ///
  /// In en, this message translates to:
  /// **'Band clip removed.'**
  String get bandClipRemoved;

  /// No description provided for @bandProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Band profile saved.'**
  String get bandProfileSaved;

  /// No description provided for @errBandRemoveSelf.
  ///
  /// In en, this message translates to:
  /// **'To leave, use Leave band.'**
  String get errBandRemoveSelf;

  /// No description provided for @errBandNotInBand.
  ///
  /// In en, this message translates to:
  /// **'They\'re not in the band anymore.'**
  String get errBandNotInBand;

  /// No description provided for @errBandRemovalExists.
  ///
  /// In en, this message translates to:
  /// **'There\'s already a vote on removing them.'**
  String get errBandRemovalExists;

  /// No description provided for @bandMemberOptions.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String bandMemberOptions(String name);

  /// No description provided for @bandRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove from band'**
  String get bandRemoveMember;

  /// No description provided for @bandRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from {band}?'**
  String bandRemoveTitle(String name, String band);

  /// No description provided for @bandRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This starts a vote: a majority of the other members has to agree. {name} won\'t see the vote.'**
  String bandRemoveBody(String name);

  /// No description provided for @bandRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start the vote'**
  String get bandRemoveConfirm;

  /// No description provided for @bandRemoveStarted.
  ///
  /// In en, this message translates to:
  /// **'Vote started on removing {name}.'**
  String bandRemoveStarted(String name);

  /// No description provided for @bandRemovedNow.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed from the band.'**
  String bandRemovedNow(String name);

  /// No description provided for @bandRemovalsHeading.
  ///
  /// In en, this message translates to:
  /// **'Removing members'**
  String get bandRemovalsHeading;

  /// No description provided for @bandRemovalCount.
  ///
  /// In en, this message translates to:
  /// **'{yes} of {needed} needed'**
  String bandRemovalCount(int yes, int needed);

  /// No description provided for @bandRemovalYes.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get bandRemovalYes;

  /// No description provided for @bandRemovalNo.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get bandRemovalNo;

  /// No description provided for @bandYouAgreed.
  ///
  /// In en, this message translates to:
  /// **'You agreed'**
  String get bandYouAgreed;

  /// No description provided for @bandYouDisagreed.
  ///
  /// In en, this message translates to:
  /// **'You said keep'**
  String get bandYouDisagreed;

  /// No description provided for @bandRemovalCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel vote'**
  String get bandRemovalCancel;

  /// No description provided for @bandRemovalCancelled.
  ///
  /// In en, this message translates to:
  /// **'Vote cancelled.'**
  String get bandRemovalCancelled;

  /// No description provided for @bandCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Band: {name}'**
  String bandCardSemantics(String name);

  /// No description provided for @bandCardStamp.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get bandCardStamp;

  /// No description provided for @bandCardNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs your instrument'**
  String get bandCardNeedsYou;

  /// No description provided for @bandAskedToJoin.
  ///
  /// In en, this message translates to:
  /// **'Asked to join {band}. Its members will vote.'**
  String bandAskedToJoin(String band);

  /// No description provided for @bandPassedOn.
  ///
  /// In en, this message translates to:
  /// **'Passed on {band}.'**
  String bandPassedOn(String band);

  /// No description provided for @bandNoOpenRoles.
  ///
  /// In en, this message translates to:
  /// **'Not looking for specific roles yet'**
  String get bandNoOpenRoles;

  /// No description provided for @bandSlotFilled.
  ///
  /// In en, this message translates to:
  /// **'In the band'**
  String get bandSlotFilled;

  /// No description provided for @bandRequestsHeading.
  ///
  /// In en, this message translates to:
  /// **'Asked to join'**
  String get bandRequestsHeading;

  /// No description provided for @bandAskedToJoinLabel.
  ///
  /// In en, this message translates to:
  /// **'Asked to join'**
  String get bandAskedToJoinLabel;

  /// No description provided for @bandMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined the band!'**
  String bandMemberJoined(String name);

  /// No description provided for @bandRequestWaiting.
  ///
  /// In en, this message translates to:
  /// **'Asked to join · waiting for the band\'s vote'**
  String get bandRequestWaiting;

  /// No description provided for @bandWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get bandWithdraw;

  /// No description provided for @bandWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn.'**
  String get bandWithdrawn;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'🎤 Voice message'**
  String get voiceMessage;

  /// No description provided for @voiceRecord.
  ///
  /// In en, this message translates to:
  /// **'Record a voice message'**
  String get voiceRecord;

  /// No description provided for @voiceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get voiceCancel;

  /// No description provided for @voiceSend.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get voiceSend;

  /// No description provided for @voiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording… {time}'**
  String voiceRecording(String time);

  /// No description provided for @voicePlay.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get voicePlay;

  /// No description provided for @voiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop voice message'**
  String get voiceStop;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @editMessageHint.
  ///
  /// In en, this message translates to:
  /// **'You can edit a message for 15 minutes after sending it.'**
  String get editMessageHint;

  /// No description provided for @editSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editSave;

  /// No description provided for @editedAt.
  ///
  /// In en, this message translates to:
  /// **'edited · {time}'**
  String editedAt(String time);

  /// No description provided for @errEditTooLate.
  ///
  /// In en, this message translates to:
  /// **'Messages can only be edited for 15 minutes.'**
  String get errEditTooLate;

  /// No description provided for @errEdit.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t edit the message. Try again.'**
  String get errEdit;

  /// No description provided for @rehearsalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rehearsals'**
  String get rehearsalsTitle;

  /// No description provided for @rehearsalAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get rehearsalAdd;

  /// No description provided for @rehearsalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rehearsals planned. Add one, and everyone can say if they\'re coming.'**
  String get rehearsalsEmpty;

  /// No description provided for @rehearsalsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get rehearsalsShowAll;

  /// No description provided for @rehearsalsShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get rehearsalsShowLess;

  /// No description provided for @rehearsalGoing.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get rehearsalGoing;

  /// No description provided for @rehearsalCant.
  ///
  /// In en, this message translates to:
  /// **'Can\'t'**
  String get rehearsalCant;

  /// No description provided for @rehearsalNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get rehearsalNoAnswer;

  /// No description provided for @rehearsalCounts.
  ///
  /// In en, this message translates to:
  /// **'{going} going · {cant} can\'t'**
  String rehearsalCounts(int going, int cant);

  /// No description provided for @rehearsalCancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Called off'**
  String get rehearsalCancelledLabel;

  /// No description provided for @rehearsalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit rehearsal'**
  String get rehearsalEdit;

  /// No description provided for @rehearsalCallOff.
  ///
  /// In en, this message translates to:
  /// **'Call off this date'**
  String get rehearsalCallOff;

  /// No description provided for @rehearsalRestore.
  ///
  /// In en, this message translates to:
  /// **'Put this date back'**
  String get rehearsalRestore;

  /// No description provided for @rehearsalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete rehearsal'**
  String get rehearsalDelete;

  /// No description provided for @rehearsalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this rehearsal?'**
  String get rehearsalDeleteTitle;

  /// No description provided for @rehearsalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears for everyone in the band.'**
  String get rehearsalDeleteBody;

  /// No description provided for @rehearsalDeleteWeeklyBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes every week of it, for everyone in the band. To skip one week, call off that date instead.'**
  String get rehearsalDeleteWeeklyBody;

  /// No description provided for @rehearsalAdded.
  ///
  /// In en, this message translates to:
  /// **'Rehearsal added.'**
  String get rehearsalAdded;

  /// No description provided for @rehearsalSaved.
  ///
  /// In en, this message translates to:
  /// **'Rehearsal saved.'**
  String get rehearsalSaved;

  /// No description provided for @rehearsalCalledOff.
  ///
  /// In en, this message translates to:
  /// **'That date is called off.'**
  String get rehearsalCalledOff;

  /// No description provided for @rehearsalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Rehearsal deleted.'**
  String get rehearsalDeleted;

  /// No description provided for @rehearsalAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add rehearsal'**
  String get rehearsalAddTitle;

  /// No description provided for @rehearsalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit rehearsal'**
  String get rehearsalEditTitle;

  /// No description provided for @rehearsalDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get rehearsalDay;

  /// No description provided for @rehearsalStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get rehearsalStart;

  /// No description provided for @rehearsalLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get rehearsalLength;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @rehearsalPlace.
  ///
  /// In en, this message translates to:
  /// **'Place (optional)'**
  String get rehearsalPlace;

  /// No description provided for @rehearsalPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Studio 4, Rustaveli 12'**
  String get rehearsalPlaceHint;

  /// No description provided for @rehearsalNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get rehearsalNotes;

  /// No description provided for @rehearsalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'What to bring, what to practise…'**
  String get rehearsalNotesHint;

  /// No description provided for @rehearsalWeekly.
  ///
  /// In en, this message translates to:
  /// **'Repeat every week'**
  String get rehearsalWeekly;

  /// No description provided for @rehearsalWeeklyHint.
  ///
  /// In en, this message translates to:
  /// **'Every {weekday}, same time'**
  String rehearsalWeeklyHint(String weekday);

  /// No description provided for @rehearsalUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get rehearsalUntil;

  /// No description provided for @rehearsalNoEnd.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get rehearsalNoEnd;

  /// No description provided for @rehearsalClearEnd.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get rehearsalClearEnd;

  /// No description provided for @rehearsalReminder.
  ///
  /// In en, this message translates to:
  /// **'{band}: rehearsal at {time}'**
  String rehearsalReminder(String band, String time);

  /// No description provided for @rehearsalReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Starts soon. Tap to see who\'s coming.'**
  String get rehearsalReminderBody;

  /// No description provided for @errRehearsalsLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load rehearsals. Check your connection.'**
  String get errRehearsalsLoad;

  /// No description provided for @errRehearsalSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the rehearsal. Try again.'**
  String get errRehearsalSave;

  /// No description provided for @rehearsalsNoneThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the next 7 days.'**
  String get rehearsalsNoneThisWeek;

  /// No description provided for @recordLimitAt.
  ///
  /// In en, this message translates to:
  /// **'Recording stops by itself at {time}.'**
  String recordLimitAt(String time);

  /// No description provided for @songsTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songsTitle;

  /// No description provided for @songsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No songs yet. Add the ones you play or want to learn.'**
  String get songsEmpty;

  /// No description provided for @songsShowAll.
  ///
  /// In en, this message translates to:
  /// **'All {count} songs'**
  String songsShowAll(int count);

  /// No description provided for @songReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get songReady;

  /// No description provided for @songLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get songLearning;

  /// No description provided for @songIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get songIdea;

  /// No description provided for @songBpm.
  ///
  /// In en, this message translates to:
  /// **'{bpm} BPM'**
  String songBpm(int bpm);

  /// No description provided for @songPlay.
  ///
  /// In en, this message translates to:
  /// **'Play the recording'**
  String get songPlay;

  /// No description provided for @songAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a song'**
  String get songAddTitle;

  /// No description provided for @songTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get songTitleLabel;

  /// No description provided for @songTitleError.
  ///
  /// In en, this message translates to:
  /// **'Give the song a title.'**
  String get songTitleError;

  /// No description provided for @songTempoError.
  ///
  /// In en, this message translates to:
  /// **'Tempo should be a number between 20 and 320.'**
  String get songTempoError;

  /// No description provided for @songPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get songPageTitle;

  /// No description provided for @songKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get songKeyLabel;

  /// No description provided for @songKeyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. E minor'**
  String get songKeyHint;

  /// No description provided for @songTempoLabel.
  ///
  /// In en, this message translates to:
  /// **'Tempo (BPM)'**
  String get songTempoLabel;

  /// No description provided for @songNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get songNotesLabel;

  /// No description provided for @songNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Structure, capo, who sings what…'**
  String get songNotesHint;

  /// No description provided for @songLinksLabel.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get songLinksLabel;

  /// No description provided for @songLinkHint.
  ///
  /// In en, this message translates to:
  /// **'YouTube, Spotify, chords or lyrics link'**
  String get songLinkHint;

  /// No description provided for @songAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get songAddLink;

  /// No description provided for @songRemoveLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get songRemoveLink;

  /// No description provided for @songRecordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get songRecordingLabel;

  /// No description provided for @songNoRecording.
  ///
  /// In en, this message translates to:
  /// **'No recording yet'**
  String get songNoRecording;

  /// No description provided for @songAddRecording.
  ///
  /// In en, this message translates to:
  /// **'Record or upload'**
  String get songAddRecording;

  /// No description provided for @songReplaceRecording.
  ///
  /// In en, this message translates to:
  /// **'Replace the recording'**
  String get songReplaceRecording;

  /// No description provided for @songRemoveRecording.
  ///
  /// In en, this message translates to:
  /// **'Remove the recording'**
  String get songRemoveRecording;

  /// No description provided for @songUseRecording.
  ///
  /// In en, this message translates to:
  /// **'Use for this song'**
  String get songUseRecording;

  /// No description provided for @songRecordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved.'**
  String get songRecordingSaved;

  /// No description provided for @songSaved.
  ///
  /// In en, this message translates to:
  /// **'Song saved.'**
  String get songSaved;

  /// No description provided for @songDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete song'**
  String get songDelete;

  /// No description provided for @songDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String songDeleteTitle(String title);

  /// No description provided for @songDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It and its recording disappear for everyone in the band.'**
  String get songDeleteBody;

  /// No description provided for @errSongsLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the songs. Check your connection.'**
  String get errSongsLoad;

  /// No description provided for @errSongSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the song. Try again.'**
  String get errSongSave;

  /// No description provided for @errSongTooLong.
  ///
  /// In en, this message translates to:
  /// **'Song recordings can be up to 10 minutes. This one is {length}.'**
  String errSongTooLong(String length);

  /// No description provided for @setlistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setlists'**
  String get setlistsTitle;

  /// No description provided for @setlistsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No setlists yet. Make one for your next gig or rehearsal.'**
  String get setlistsEmpty;

  /// No description provided for @setlistAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New setlist'**
  String get setlistAddTitle;

  /// No description provided for @setlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Setlist name'**
  String get setlistNameLabel;

  /// No description provided for @setlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Friday gig'**
  String get setlistNameHint;

  /// No description provided for @setlistPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Setlist'**
  String get setlistPageTitle;

  /// No description provided for @setlistSongCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String setlistSongCount(int count);

  /// No description provided for @setlistNoLength.
  ///
  /// In en, this message translates to:
  /// **'{count} without a recording'**
  String setlistNoLength(int count);

  /// No description provided for @setlistEmptySongs.
  ///
  /// In en, this message translates to:
  /// **'No songs in this setlist yet. Add some from the band\'s songs.'**
  String get setlistEmptySongs;

  /// No description provided for @setlistAddSongs.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get setlistAddSongs;

  /// No description provided for @setlistAddSongsButton.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String setlistAddSongsButton(int count);

  /// No description provided for @setlistAllAdded.
  ///
  /// In en, this message translates to:
  /// **'Every song is already in this setlist.'**
  String get setlistAllAdded;

  /// No description provided for @setlistNoBandSongs.
  ///
  /// In en, this message translates to:
  /// **'The band has no songs yet. Add them under Songs first.'**
  String get setlistNoBandSongs;

  /// No description provided for @setlistRemoveSong.
  ///
  /// In en, this message translates to:
  /// **'Remove from setlist'**
  String get setlistRemoveSong;

  /// No description provided for @setlistDragHint.
  ///
  /// In en, this message translates to:
  /// **'Hold a song and drag it to change the order.'**
  String get setlistDragHint;

  /// No description provided for @setlistRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get setlistRename;

  /// No description provided for @setlistDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete setlist'**
  String get setlistDelete;

  /// No description provided for @setlistDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String setlistDeleteTitle(String name);

  /// No description provided for @setlistDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The songs stay in the band; only this list goes. Rehearsals that used it keep their other details.'**
  String get setlistDeleteBody;

  /// No description provided for @setlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Setlist deleted.'**
  String get setlistDeleted;

  /// No description provided for @errSetlistsLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the setlists. Check your connection.'**
  String get errSetlistsLoad;

  /// No description provided for @errSetlistSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the setlist. Try again.'**
  String get errSetlistSave;

  /// No description provided for @rehearsalSetlist.
  ///
  /// In en, this message translates to:
  /// **'Setlist to practise'**
  String get rehearsalSetlist;

  /// No description provided for @rehearsalNoSetlist.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get rehearsalNoSetlist;

  /// No description provided for @rehearsalPractise.
  ///
  /// In en, this message translates to:
  /// **'Practise: {name}'**
  String rehearsalPractise(String name);

  /// No description provided for @publicPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Public page'**
  String get publicPageTitle;

  /// No description provided for @publicPageOffHint.
  ///
  /// In en, this message translates to:
  /// **'Off: only band members can see the band\'s page.'**
  String get publicPageOffHint;

  /// No description provided for @publicPageOnHint.
  ///
  /// In en, this message translates to:
  /// **'On: anyone with the link can see the name, profile, clip, members and ready songs. Members aged 16–17 show only as their instrument.'**
  String get publicPageOnHint;

  /// No description provided for @publicPageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get publicPageCopy;

  /// No description provided for @publicPageCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get publicPageCopied;

  /// No description provided for @publicPageView.
  ///
  /// In en, this message translates to:
  /// **'View page'**
  String get publicPageView;

  /// No description provided for @publicPageTurnedOn.
  ///
  /// In en, this message translates to:
  /// **'The band\'s public page is on.'**
  String get publicPageTurnedOn;

  /// No description provided for @publicPageTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'The public page is off.'**
  String get publicPageTurnedOff;

  /// No description provided for @publicBandSongs.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get publicBandSongs;

  /// No description provided for @publicBandNotFound.
  ///
  /// In en, this message translates to:
  /// **'This band page isn\'t available. The band may have made it private.'**
  String get publicBandNotFound;

  /// No description provided for @publicBandJoin.
  ///
  /// In en, this message translates to:
  /// **'Join OCTAVA'**
  String get publicBandJoin;

  /// No description provided for @publicBandJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Musicians find each other and form bands on OCTAVA.'**
  String get publicBandJoinHint;

  /// No description provided for @errPublicBandLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this band. Check your connection.'**
  String get errPublicBandLoad;

  /// No description provided for @kmDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String kmDistance(String distance);

  /// No description provided for @profileGroup.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileGroup;

  /// No description provided for @settingsGroup.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsGroup;

  /// No description provided for @summaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get summaryEmpty;

  /// No description provided for @clipsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No clips yet} =1{1 clip} other{{count} clips}}'**
  String clipsCount(int count);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, clips, avatar, matches, messages and band memberships. It can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @errDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Check your connection and try again.'**
  String get errDeleteAccount;

  /// No description provided for @modGroup.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get modGroup;

  /// No description provided for @modReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get modReports;

  /// No description provided for @modOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No open reports} =1{1 open report} other{{count} open reports}}'**
  String modOpenCount(int count);

  /// No description provided for @modEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open reports. All clear.'**
  String get modEmpty;

  /// No description provided for @modReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by {name} · {when}'**
  String modReportedBy(String name, String when);

  /// No description provided for @modAgainstCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open report against them} other{{count} open reports against them}}'**
  String modAgainstCount(int count);

  /// No description provided for @modHiddenFromFeed.
  ///
  /// In en, this message translates to:
  /// **'Hidden from the feed until reviewed'**
  String get modHiddenFromFeed;

  /// No description provided for @modSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get modSuspended;

  /// No description provided for @modMessageGone.
  ///
  /// In en, this message translates to:
  /// **'The message was already deleted.'**
  String get modMessageGone;

  /// No description provided for @modDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get modDismiss;

  /// No description provided for @modRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove message'**
  String get modRemoveMessage;

  /// No description provided for @modSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get modSuspend;

  /// No description provided for @modUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Lift suspension'**
  String get modUnsuspend;

  /// No description provided for @modSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}?'**
  String modSuspendTitle(String name);

  /// No description provided for @modSuspendBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be hidden from the feed, signed out and unable to sign in. All their open reports will close.'**
  String get modSuspendBody;

  /// No description provided for @modDismissed.
  ///
  /// In en, this message translates to:
  /// **'Report dismissed.'**
  String get modDismissed;

  /// No description provided for @modMessageRemoved.
  ///
  /// In en, this message translates to:
  /// **'Message removed.'**
  String get modMessageRemoved;

  /// No description provided for @modSuspendedDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is suspended.'**
  String modSuspendedDone(String name);

  /// No description provided for @modUnsuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspension lifted.'**
  String get modUnsuspended;

  /// No description provided for @errModeration.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load or update the reports. Try again.'**
  String get errModeration;

  /// No description provided for @legalAgree.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the'**
  String get legalAgree;

  /// No description provided for @legalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalTerms;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legalPrivacy;

  /// No description provided for @legalTermsRow.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalTermsRow;

  /// No description provided for @legalPrivacyRow.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legalPrivacyRow;

  /// No description provided for @modViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get modViewProfile;

  /// No description provided for @modEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Their last message to {name}} other{Their last {count} messages to {name}}}'**
  String modEvidenceTitle(int count, String name);

  /// No description provided for @modEvidenceNote.
  ///
  /// In en, this message translates to:
  /// **'Copied when the report was filed; it stays even if they delete the chat.'**
  String get modEvidenceNote;

  /// No description provided for @modJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String modJoined(String date);

  /// No description provided for @modProfileGone.
  ///
  /// In en, this message translates to:
  /// **'This account no longer exists.'**
  String get modProfileGone;

  /// No description provided for @modModerators.
  ///
  /// In en, this message translates to:
  /// **'Moderators'**
  String get modModerators;

  /// No description provided for @modModeratorCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 moderator} other{{count} moderators}}'**
  String modModeratorCount(int count);

  /// No description provided for @modSearchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search people by name'**
  String get modSearchPeople;

  /// No description provided for @modSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters to find someone.'**
  String get modSearchHint;

  /// No description provided for @modNoOneFound.
  ///
  /// In en, this message translates to:
  /// **'No one by that name.'**
  String get modNoOneFound;

  /// No description provided for @modMakeModerator.
  ///
  /// In en, this message translates to:
  /// **'Make moderator'**
  String get modMakeModerator;

  /// No description provided for @modIsModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get modIsModerator;

  /// No description provided for @modAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get modAdmin;

  /// No description provided for @modRemoveModerator.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get modRemoveModerator;

  /// No description provided for @modRemoveModeratorTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} as a moderator?'**
  String modRemoveModeratorTitle(String name);

  /// No description provided for @modRemoveModeratorBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll stop seeing reports. You can add them again later.'**
  String get modRemoveModeratorBody;

  /// No description provided for @modMakeModeratorTitle.
  ///
  /// In en, this message translates to:
  /// **'Make {name} a moderator?'**
  String modMakeModeratorTitle(String name);

  /// No description provided for @modMakeModeratorBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll see every report, the reported messages and people\'s profiles, and can suspend accounts.'**
  String get modMakeModeratorBody;

  /// No description provided for @modMadeModerator.
  ///
  /// In en, this message translates to:
  /// **'{name} is now a moderator.'**
  String modMadeModerator(String name);

  /// No description provided for @modRemovedModerator.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer a moderator.'**
  String modRemovedModerator(String name);

  /// No description provided for @errModSuspendedCant.
  ///
  /// In en, this message translates to:
  /// **'A suspended account can\'t be a moderator.'**
  String get errModSuspendedCant;

  /// No description provided for @errModAdminStays.
  ///
  /// In en, this message translates to:
  /// **'An admin always stays a moderator.'**
  String get errModAdminStays;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgot;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If there\'s an account for {email}, we\'ve sent it a link to choose a new password. Check your inbox and spam folder.'**
  String authResetSent(String email);

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use it to sign in on every device.'**
  String get resetBody;

  /// No description provided for @resetNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetNew;

  /// No description provided for @resetRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password'**
  String get resetRepeat;

  /// No description provided for @resetMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get resetMismatch;

  /// No description provided for @resetSave.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get resetSave;

  /// No description provided for @resetNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get resetNotNow;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get resetDone;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Type the email you signed up with and we\'ll send you a link to choose a new password.'**
  String get forgotBody;

  /// No description provided for @forgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get forgotSend;

  /// No description provided for @forgotSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotSentTitle;

  /// No description provided for @forgotHint.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Look in your spam folder, or send it again.'**
  String get forgotHint;

  /// No description provided for @forgotResend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get forgotResend;

  /// No description provided for @forgotResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds} s'**
  String forgotResendIn(int seconds);

  /// No description provided for @errResetWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait a minute before asking for another link.'**
  String get errResetWait;

  /// No description provided for @resetBack.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get resetBack;

  /// No description provided for @errResetLink.
  ///
  /// In en, this message translates to:
  /// **'This link has expired or was already used. Ask for a new one on the sign-in screen.'**
  String get errResetLink;

  /// No description provided for @errSamePassword.
  ///
  /// In en, this message translates to:
  /// **'That\'s your current password. Pick a different one.'**
  String get errSamePassword;

  /// No description provided for @inviteGroup.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get inviteGroup;

  /// No description provided for @inviteMusicians.
  ///
  /// In en, this message translates to:
  /// **'Invite musicians'**
  String get inviteMusicians;

  /// No description provided for @inviteSummary.
  ///
  /// In en, this message translates to:
  /// **'Bring your bandmates and friends'**
  String get inviteSummary;

  /// No description provided for @inviteSubject.
  ///
  /// In en, this message translates to:
  /// **'Join me on OCTAVA'**
  String get inviteSubject;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m on OCTAVA, an app where musicians hear each other play and form bands. Join me: {link}'**
  String inviteMessage(String link);

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied. Paste it in a chat.'**
  String get inviteCopied;

  /// No description provided for @heardSection.
  ///
  /// In en, this message translates to:
  /// **'One last thing'**
  String get heardSection;

  /// No description provided for @heardQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where did you hear about OCTAVA? (optional)'**
  String get heardQuestion;

  /// No description provided for @heardTiktok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get heardTiktok;

  /// No description provided for @heardInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get heardInstagram;

  /// No description provided for @heardFriend.
  ///
  /// In en, this message translates to:
  /// **'A friend'**
  String get heardFriend;

  /// No description provided for @heardPoster.
  ///
  /// In en, this message translates to:
  /// **'Poster or flyer'**
  String get heardPoster;

  /// No description provided for @heardJamNight.
  ///
  /// In en, this message translates to:
  /// **'Jam night'**
  String get heardJamNight;

  /// No description provided for @heardSearch.
  ///
  /// In en, this message translates to:
  /// **'Search or app store'**
  String get heardSearch;

  /// No description provided for @heardOther.
  ///
  /// In en, this message translates to:
  /// **'Somewhere else'**
  String get heardOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ka'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ka':
      return AppLocalizationsKa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
