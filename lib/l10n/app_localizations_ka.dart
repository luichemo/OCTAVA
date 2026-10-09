// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Georgian (`ka`).
class AppLocalizationsKa extends AppLocalizations {
  AppLocalizationsKa([String locale = 'ka']) : super(locale);

  @override
  String get tryAgain => 'სცადე თავიდან';

  @override
  String get cancel => 'გაუქმება';

  @override
  String get delete => 'წაშლა';

  @override
  String get add => 'დამატება';

  @override
  String get signOut => 'გასვლა';

  @override
  String get navProfile => 'პროფილი';

  @override
  String get navMatches => 'მეჩები';

  @override
  String get errOffline =>
      'OCTAVA-სთან დაკავშირება ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get authTagline => 'იპოვე ადამიანები, ვისთანაც მუსიკას შექმნი.';

  @override
  String get authEmail => 'ელფოსტა';

  @override
  String get authEmailError => 'შეიყვანე ელფოსტის მისამართი';

  @override
  String get authPassword => 'პაროლი';

  @override
  String get authPasswordHelper => 'მინიმუმ 8 სიმბოლო';

  @override
  String get authPasswordEmpty => 'შეიყვანე პაროლი';

  @override
  String get authPasswordShort => 'გამოიყენე მინიმუმ 8 სიმბოლო';

  @override
  String get authCreateAccount => 'ანგარიშის შექმნა';

  @override
  String get authSignIn => 'შესვლა';

  @override
  String get authHaveAccount => 'უკვე მაქვს ანგარიში';

  @override
  String get authNewAccount => 'ახალი ანგარიშის შექმნა';

  @override
  String get authCheckEmail =>
      'შეამოწმე ელფოსტა: გამოგიგზავნეთ ბმული ანგარიშის დასადასტურებლად. გახსენი ის და შემდეგ აქ შედი.';

  @override
  String get errEmailTaken =>
      'ამ ელფოსტით ანგარიში უკვე არსებობს. სცადე შესვლა.';

  @override
  String get errBadLogin => 'ეს ელფოსტა და პაროლი არცერთ ანგარიშს არ ემთხვევა.';

  @override
  String get errEmailNotConfirmed =>
      'ჯერ დაადასტურე ელფოსტა: გახსენი გამოგზავნილი ბმული და შემდეგ შედი.';

  @override
  String get errWeakPassword =>
      'აირჩიე უფრო ძლიერი პაროლი: მინიმუმ 8 სიმბოლო, ასოები და ციფრები ერთად.';

  @override
  String get errEmailInvalid => 'შეიყვანე სწორი ელფოსტის მისამართი.';

  @override
  String get errTooManyAttempts =>
      'ძალიან ბევრი მცდელობაა. დაიცადე ერთი წუთი და სცადე თავიდან.';

  @override
  String get profileSetUpTitle => 'შექმენი პროფილი';

  @override
  String get profileTitle => 'შენი პროფილი';

  @override
  String get profileSubtitle =>
      'ამას ხედავენ სხვა მუსიკოსები, როცა ბარათებს ფურცლავენ.';

  @override
  String get seeYourCard => 'ნახე შენი ბარათი';

  @override
  String get sectionAvatar => 'ავატარი';

  @override
  String get sectionAbout => 'შენ შესახებ';

  @override
  String get sectionLocation => 'მდებარეობა';

  @override
  String get sectionPlay => 'რაზე უკრავ';

  @override
  String get sectionWant => 'რა გინდა';

  @override
  String get sectionLinks => 'ბმულები';

  @override
  String get sectionClips => 'აუდიოჩანაწერები';

  @override
  String get sectionLanguage => 'ენა';

  @override
  String get fieldName => 'სახელი';

  @override
  String get fieldNameError => 'შეიყვანე სახელი, რომელსაც სხვები დაინახავენ';

  @override
  String get fieldBirthDate => 'დაბადების თარიღი';

  @override
  String get fieldBirthDateHelper =>
      'OCTAVA განკუთვნილია 16 წლიდან. სხვები მხოლოდ შენს ასაკს ხედავენ.';

  @override
  String get fieldBirthDateError => 'შეიყვანე დაბადების თარიღი';

  @override
  String get birthDatePickerTitle => 'შენი დაბადების თარიღი';

  @override
  String get confirmBirthDateTitle => 'დაბადების თარიღი სწორია?';

  @override
  String confirmBirthDateBody(String date) {
    return '$date. მოგვიანებით მას ვეღარ შეცვლი, რადგან ის განსაზღვრავს, ვის შეხვდები OCTAVA-ზე.';
  }

  @override
  String get confirmBirthDateNo => 'შეცვლა';

  @override
  String get confirmBirthDateYes => 'დიახ, სწორია';

  @override
  String get fieldArea => 'უბანი (არასავალდებულო)';

  @override
  String get fieldAreaHint => 'მაგ. ვაკე, თბილისი';

  @override
  String instrumentMain(String instrument) {
    return '$instrument (მთავარი)';
  }

  @override
  String get pickInstrumentError => 'აირჩიე ერთი ინსტრუმენტი მაინც';

  @override
  String get fieldGenres => 'ჟანრები';

  @override
  String get fieldGenresHint => 'ჩაწერე ჟანრი და დააჭირე Enter-ს';

  @override
  String get rehearseQuestion => 'რამდენად ხშირად შეგიძლია რეპეტიცია?';

  @override
  String get gearQuestion => 'რა გაქვს?';

  @override
  String get fieldLookingFor => 'რას ეძებ? (არასავალდებულო)';

  @override
  String get fieldLookingForHint =>
      'მაგ. ბენდი, რომელიც ყოველკვირა გადის რეპეტიციას და კონცერტებს მართავს';

  @override
  String get linksLabel => 'YouTube, TikTok, SoundCloud, Spotify…';

  @override
  String get linksHint => 'ჩასვი ბმული და დააჭირე Enter-ს';

  @override
  String get addLink => 'ბმულის დამატება';

  @override
  String get removeLink => 'ბმულის წაშლა';

  @override
  String get linkInvalid =>
      'ჩასვი სრული ვებმისამართი, მაგ. youtube.com/watch?v=…';

  @override
  String get linkMax => 'შეგიძლია დაამატო 6 ბმულამდე.';

  @override
  String get linkCheckError => 'შეამოწმე ბმული: ეს ვებმისამართი არ გამოდგება.';

  @override
  String get answersMissing =>
      'ზოგი პასუხი აკლია. შეამოწმე ზემოთ წითლად მონიშნული ველები.';

  @override
  String get saveChanges => 'ცვლილებების შენახვა';

  @override
  String get createProfile => 'პროფილის შექმნა';

  @override
  String get profileSaved => 'პროფილი შენახულია.';

  @override
  String get errSaveProfile =>
      'პროფილის შენახვა ვერ მოხერხდა. ცოტა ხანში სცადე თავიდან.';

  @override
  String get errUnder16 =>
      'OCTAVA განკუთვნილია 16 წლის და უფროსი ასაკის ადამიანებისთვის.';

  @override
  String get errBirthDateInvalid => 'შეიყვანე რეალური დაბადების თარიღი.';

  @override
  String get tagMax => 'შეგიძლია დაამატო 10-მდე';

  @override
  String get deckEverywhere => 'ყველგან';

  @override
  String deckWithin(int km) {
    return '$km კმ-ის რადიუსში';
  }

  @override
  String deckWithFilters(String where, int count) {
    return '$where, $count ფილტრი';
  }

  @override
  String get swipeHint => 'მარჯვნივ — არ მეყო, მარცხნივ — მეყო';

  @override
  String get swipeHintWeb => 'მარჯვნივ — არ მეყო, მარცხნივ — მეყო (ან ისრები)';

  @override
  String get stampJam => 'არ მეყო';

  @override
  String get stampPass => 'მეყო';

  @override
  String get actionJam => 'არ მეყო';

  @override
  String get actionPass => 'მეყო';

  @override
  String passedOn(String name) {
    return '$name გამოტოვებულია.';
  }

  @override
  String askedToJam(String name) {
    return '$name-ს ჯემი შესთავაზე';
  }

  @override
  String matchTitle(String name) {
    return '$name-საც სურს ჯემი';
  }

  @override
  String matchSlotFilled(String instrument) {
    return 'შენს ბენდში ადგილი „$instrument“ ახლა შევსებულია. მიესალმე და დაგეგმეთ პირველი რეპეტიცია.';
  }

  @override
  String matchSlotTaken(String holder, String instrument) {
    return 'შენს ბენდში ადგილს „$instrument“ უკვე იკავებს $holder, მაგრამ მაინც შეგიძლია მიესალმო.';
  }

  @override
  String matchSlotYours(String instrument) {
    return 'ადგილი „$instrument“ შენ გიკავია, მაგრამ მაინც შეგიძლია მიესალმო.';
  }

  @override
  String saidHi(String name) {
    return '$name-ს მიესალმე';
  }

  @override
  String get sayHi => 'მისალმება';

  @override
  String get keepSwiping => 'გაგრძელება';

  @override
  String get loadErrorTitle => 'რაღაც არასწორად წავიდა';

  @override
  String get errLoadMusiciansShort =>
      'მუსიკოსების ჩატვირთვა ვერ მოხერხდა. სცადე თავიდან.';

  @override
  String get noMatchTitle => 'შესაბამისი არავინაა';

  @override
  String get noMatchBody =>
      'ახლა შენს ფილტრებს არავინ შეესაბამება. სცადე ნაკლები ფილტრი ან უფრო დიდი მანძილი.';

  @override
  String get changeFilters => 'ფილტრების შეცვლა';

  @override
  String get heardEveryoneTitle => 'ყველა მოისმინე';

  @override
  String get heardEveryoneBody =>
      'ჯერჯერობით სულ ესაა. ახალი მუსიკოსები ყოველკვირა ემატებიან.';

  @override
  String get checkAgain => 'ხელახლა შემოწმება';

  @override
  String get locationPrompt => 'ნახე, რამდენად შორს არიან სხვები.';

  @override
  String get shareLocation => 'მდებარეობის გაზიარება';

  @override
  String get shareLocationShort => 'გაზიარება';

  @override
  String get findingYou => 'მდებარეობას ვადგენთ…';

  @override
  String get yourBand => 'შენი ბენდი';

  @override
  String get slotOpen => 'თავისუფალი';

  @override
  String get slotYou => 'შენ';

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
    return '$distance კმ-ში';
  }

  @override
  String fitsSlot(String instrument) {
    return 'შენს ბენდს სჭირდება: $instrument';
  }

  @override
  String plays(String genres) {
    return 'ჟანრები: $genres';
  }

  @override
  String get listAnd => 'და';

  @override
  String quoted(String text) {
    return '„$text“';
  }

  @override
  String get noClip => 'ჩანაწერი არ არის';

  @override
  String playClipOf(String name) {
    return '$name-ის ჩანაწერის მოსმენა';
  }

  @override
  String stopClipOf(String name) {
    return '$name-ის ჩანაწერის გაჩერება';
  }

  @override
  String get blockOrReport => 'დაბლოკვა ან საჩივარი';

  @override
  String get musicianFallback => 'მუსიკოსი';

  @override
  String get matchesTitle => 'მეჩები';

  @override
  String get matchesEmpty =>
      'მეჩები ჯერ არ გაქვს. როცა ვინმე, ვისაც ჯემი შესთავაზე, შენც შემოგთავაზებს, აქ გამოჩნდება.';

  @override
  String get newMatchSayHi => 'ახალი მეჩი. მიესალმე!';

  @override
  String youPrefix(String message) {
    return 'შენ: $message';
  }

  @override
  String get yesterday => 'გუშინ';

  @override
  String chatEmpty(String name) {
    return 'შენც და $name-საც ჯემი გინდათ. მიესალმე და დაგეგმეთ პირველი რეპეტიცია.';
  }

  @override
  String get messageHint => 'შეტყობინება';

  @override
  String get send => 'გაგზავნა';

  @override
  String get chatLoadError =>
      'შეტყობინებების ჩატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი, დაბრუნდი უკან და ჩატი თავიდან გახსენი.';

  @override
  String get errLoadMatches =>
      'მეჩების ჩატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errSendBlocked => 'ამ ჩატში შეტყობინებებს ვეღარ გააგზავნი.';

  @override
  String get errSend => 'შეტყობინება ვერ გაიგზავნა. სცადე თავიდან.';

  @override
  String get errSendOffline =>
      'შეტყობინება ვერ გაიგზავნა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String blockName(String name) {
    return '$name-ის დაბლოკვა';
  }

  @override
  String get blockSubtitle =>
      'ერთმანეთს ვეღარ დაინახავთ და ვეღარ მისწერთ. მას ამის შესახებ არ ეცნობება.';

  @override
  String reportName(String name) {
    return 'საჩივარი: $name';
  }

  @override
  String get reportSubtitle =>
      'შეგვატყობინე პრობლემის შესახებ. საჩივრები კონფიდენციალურია.';

  @override
  String blockedName(String name) {
    return '$name დაბლოკე.';
  }

  @override
  String reportThanksBlocked(String name) {
    return 'მადლობა საჩივრისთვის. $name ასევე დაბლოკე.';
  }

  @override
  String get reportThanks =>
      'მადლობა საჩივრისთვის. ყველა საჩივარს განვიხილავთ.';

  @override
  String blockConfirmTitle(String name) {
    return 'დაბლოკო $name?';
  }

  @override
  String blockConfirmBody(String name) {
    return 'OCTAVA-ზე ერთმანეთს ვეღარ დაინახავთ და ვერცერთი ვეღარ გაგზავნით შეტყობინებას. $name-ს ამის შესახებ არ ეცნობება.';
  }

  @override
  String get whatsWrong => 'რა მოხდა?';

  @override
  String get reportDetails => 'დეტალები (არასავალდებულო)';

  @override
  String alsoBlock(String name) {
    return '$name-ის დაბლოკვაც';
  }

  @override
  String get sendReport => 'საჩივრის გაგზავნა';

  @override
  String get reasonHarassment => 'შევიწროება ან სიძულვილის ენა';

  @override
  String get reasonInappropriate => 'შეუფერებელი შეტყობინებები ან კონტენტი';

  @override
  String get reasonSpam => 'სპამი ან თაღლითობა';

  @override
  String get reasonFake => 'ყალბი პროფილი';

  @override
  String get reasonUnderage => 'როგორც ჩანს, 16 წლამდეა';

  @override
  String get reasonOther => 'სხვა';

  @override
  String get errBlock => 'დაბლოკვა ვერ მოხერხდა. სცადე თავიდან.';

  @override
  String get errBlockOffline =>
      'დაბლოკვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errReport =>
      'საჩივარი ვერ გაიგზავნა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get clipsInfo =>
      '5-მდე ჩანაწერი, თითო 2 წუთამდე. პირველი ჩანაწერი შენს ბარათზე ჟღერს.';

  @override
  String get clipAdded => 'ჩანაწერი დაემატა პროფილს.';

  @override
  String get deleteClipTitle => 'წავშალო ჩანაწერი?';

  @override
  String deleteClipBody(String title) {
    return '„$title“ წაიშლება შენი პროფილიდან.';
  }

  @override
  String get clipFallback => 'ჩანაწერი';

  @override
  String get deleteClip => 'ჩანაწერის წაშლა';

  @override
  String get play => 'მოსმენა';

  @override
  String get stop => 'გაჩერება';

  @override
  String get uploading => 'იტვირთება…';

  @override
  String get clipsFull => 'უკვე 5 ჩანაწერი გაქვს';

  @override
  String get addClip => 'ჩანაწერის დამატება';

  @override
  String get errOpenFiles =>
      'ფაილების გახსნა ვერ მოხერხდა. გადატვირთე აპი და სცადე თავიდან.';

  @override
  String get errClipsLoad =>
      'ჩანაწერების ჩატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errClipType =>
      'გამოიყენე MP3, M4A, AAC, WAV, OGG, WEBM ან FLAC ფაილი.';

  @override
  String get errClipSize =>
      'ფაილი 10 მბ-ზე დიდია. სცადე უფრო მოკლე ან შეკუმშული ჩანაწერი.';

  @override
  String get errClipsMax =>
      'შეგიძლია გქონდეს 5-მდე ჩანაწერი. ახლის დასამატებლად ერთი წაშალე.';

  @override
  String get errClipUpload =>
      'ჩანაწერის ატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errClipUnreadable =>
      'ამ ფაილის დაკვრა ვერ მოხერხდა. სცადე მისი MP3 ან M4A ფორმატში შენახვა.';

  @override
  String errClipTooLong(String length) {
    return 'ჩანაწერი შეიძლება იყოს 2 წუთამდე. ეს არის $length.';
  }

  @override
  String get errClipSave => 'ჩანაწერის შენახვა ვერ მოხერხდა. სცადე თავიდან.';

  @override
  String get errClipDelete =>
      'ჩანაწერის წაშლა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errClipPlay =>
      'ჩანაწერის დაკვრა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get avatarPainting => 'ავატარს ვხატავთ… ამას რამდენიმე წამი სჭირდება.';

  @override
  String get avatarInfo =>
      'რიზოგრაფიული ილუსტრაცია, რომელსაც AI ქმნის შენი მთავარი ინსტრუმენტისა და ჟანრების მიხედვით.';

  @override
  String get avatarGenerate => 'ავატარის შექმნა';

  @override
  String get avatarNew => 'ახლის შექმნა';

  @override
  String avatarRemaining(int count) {
    return 'დღეს კიდევ $count';
  }

  @override
  String get errAvatarLoad =>
      'ავატარის ჩატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errAvatarGeneric =>
      'ავატარის შექმნა ახლა ვერ მოხერხდა. სცადე თავიდან.';

  @override
  String get errAvatarOffline =>
      'ავატარის შექმნა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errAvatarDaily => 'დღეს უკვე 5 ავატარი შექმენი. სცადე ხვალ.';

  @override
  String get errAvatarBusy =>
      'ახლა ძალიან ბევრი ავატარი იქმნება. სცადე მოგვიანებით.';

  @override
  String get errAvatarNotReady =>
      'ავატარების შექმნა ჯერ არ არის გამართული. სცადე მოგვიანებით.';

  @override
  String get locationSharing =>
      'შენ აზიარებ მიახლოებით მდებარეობას (დაახლოებით 1 კმ-ის სიზუსტით). სხვები ხედავენ, რამდენად შორს ხარ, მაგრამ არასდროს — სად ხარ.';

  @override
  String get locationNotSharing =>
      'მდებარეობას არ აზიარებ, ამიტომ მანძილს შენამდე ვერავინ ხედავს და მანძილის ფილტრი გამორთულია.';

  @override
  String get locationSaved => 'მდებარეობა შენახულია.';

  @override
  String get updateLocation => 'მდებარეობის განახლება';

  @override
  String get locationStopped => 'მდებარეობას აღარ აზიარებ.';

  @override
  String get stopSharing => 'გაზიარების შეწყვეტა';

  @override
  String get errLocationOff =>
      'ამ მოწყობილობაზე მდებარეობა გამორთულია. ჩართე და სცადე თავიდან.';

  @override
  String get errLocationDenied =>
      'OCTAVA-ს არ აქვს მდებარეობის გამოყენების ნებართვა. დაუშვი ის ბრაუზერის ან ტელეფონის პარამეტრებში და სცადე თავიდან.';

  @override
  String get errLocationFind =>
      'მდებარეობის დადგენა ვერ მოხერხდა. ცოტა ხანში სცადე თავიდან.';

  @override
  String get errLocationSave =>
      'მდებარეობის შენახვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errLocationRemove =>
      'მდებარეობის წაშლა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get filtersTitle => 'ფილტრები';

  @override
  String get reset => 'გასუფთავება';

  @override
  String get filterDistance => 'მანძილი';

  @override
  String get filterDistanceNoLocation =>
      'მანძილით გასაფილტრად გააზიარე მდებარეობა. მანამდე ყველას ხედავ.';

  @override
  String kmShort(int km) {
    return '$km კმ';
  }

  @override
  String get anywhere => 'ნებისმიერ ადგილას';

  @override
  String get filterInstruments => 'ინსტრუმენტები';

  @override
  String get filterInstrumentsHint =>
      'აჩვენე მხოლოდ ისინი, ვინც ამ ინსტრუმენტებზე უკრავს. ყველას სანახავად დატოვე ცარიელი.';

  @override
  String get filterSkill => 'მინიმალური დონე';

  @override
  String get filterSkillNeedsInstruments =>
      'ჯერ აირჩიე ინსტრუმენტები: დონე მათზე ვრცელდება.';

  @override
  String get any => 'ნებისმიერი';

  @override
  String skillOrBetter(String skill) {
    return '$skill ან უკეთესი';
  }

  @override
  String get filterGenresHint =>
      'აჩვენე ისინი, ვინც ამ ჟანრებიდან ერთს მაინც უკრავს.';

  @override
  String get filterGoals => 'მიზნები';

  @override
  String get filterRehearses => 'რეპეტიციები';

  @override
  String get showMusicians => 'მუსიკოსების ჩვენება';

  @override
  String get errLoadMusicians =>
      'მუსიკოსების ჩატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errSaveSwipe =>
      'შენახვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errLoadBand =>
      'ბენდის ჩატვირთვა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get yourCard => 'შენი ბარათი';

  @override
  String get cardPreviewInfo =>
      'ასე გხედავენ სხვა მუსიკოსები. მანძილი გამოჩნდება, როცა ორივე გააზიარებთ მდებარეობას.';

  @override
  String get languageDevice => 'მოწყობილობის';

  @override
  String get languageInfo =>
      '„მოწყობილობის“ ნიშნავს ტელეფონის ან ბრაუზერის ენას.';

  @override
  String get instrumentVocals => 'ვოკალი';

  @override
  String get instrumentGuitar => 'გიტარა';

  @override
  String get instrumentBass => 'ბასი';

  @override
  String get instrumentDrums => 'დასარტყამები';

  @override
  String get instrumentKeys => 'კლავიშები';

  @override
  String get instrumentPercussion => 'პერკუსია';

  @override
  String get instrumentViolin => 'ვიოლინო';

  @override
  String get instrumentCello => 'ჩელო';

  @override
  String get instrumentSaxophone => 'საქსოფონი';

  @override
  String get instrumentTrumpet => 'საყვირი';

  @override
  String get instrumentTrombone => 'ტრომბონი';

  @override
  String get instrumentFlute => 'ფლეიტა';

  @override
  String get instrumentClarinet => 'კლარნეტი';

  @override
  String get instrumentDj => 'დიჯეი';

  @override
  String get instrumentProduction => 'პროდიუსინგი';

  @override
  String get instrumentOther => 'სხვა';

  @override
  String get skillBeginner => 'დამწყები';

  @override
  String get skillIntermediate => 'საშუალო';

  @override
  String get skillAdvanced => 'გამოცდილი';

  @override
  String get skillPro => 'პროფესიონალი';

  @override
  String get goalFun => 'გასართობად';

  @override
  String get goalGigging => 'კონცერტები';

  @override
  String get goalRecording => 'ჩაწერა';

  @override
  String get goalPaid => 'ანაზღაურებადი სამუშაო';

  @override
  String get freqOccasionally => 'დროდადრო';

  @override
  String get freqMonthly => 'თვეში ერთხელ';

  @override
  String get freqWeekly => 'კვირაში ერთხელ';

  @override
  String get freqSeveralAWeek => 'კვირაში რამდენჯერმე';

  @override
  String get gearOwnGear => 'საკუთარი აღჭურვილობა';

  @override
  String get gearCar => 'მანქანა';

  @override
  String get gearRehearsalSpace => 'სარეპეტიციო სივრცე';

  @override
  String get gearHomeStudio => 'სახლის სტუდია';

  @override
  String get linkWebsite => 'ვებგვერდი';
}
