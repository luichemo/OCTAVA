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

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get authHaveAccount;

  /// No description provided for @authNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get authNewAccount;

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
  /// **'That\'s everyone for now. New musicians join every week.'**
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

  /// No description provided for @recordLimit.
  ///
  /// In en, this message translates to:
  /// **'Recording stops by itself at 2:00.'**
  String get recordLimit;

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
  /// **'Choose the roles your band needs'**
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
