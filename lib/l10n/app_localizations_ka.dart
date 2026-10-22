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
  String get fieldArea => 'უბანი ან ქალაქი (არასავალდებულო)';

  @override
  String get fieldAreaHint => 'სად ცხოვრობ ან სად აკეთებ რეპეტიციას';

  @override
  String instrumentMain(String instrument) {
    return '$instrument (მთავარი)';
  }

  @override
  String get pickInstrumentError => 'აირჩიე ერთი ინსტრუმენტი მაინც';

  @override
  String get fieldGenres => 'ჟანრები';

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
  String get genresChoose => 'აირჩიე ჟანრები';

  @override
  String get genresChange => 'ჟანრების შეცვლა';

  @override
  String get genresSearch => 'ჟანრის ძებნა';

  @override
  String get genresDone => 'მზადაა';

  @override
  String get genresMax => 'შეგიძლია აირჩიო 10 ჟანრამდე.';

  @override
  String get genresNoResults => 'ასეთი ჟანრი არ მოიძებნა.';

  @override
  String get noClipsTitle => 'ფიდში არ ჩანხარ';

  @override
  String get noClipsBody =>
      'მუსიკოსები, რომლებსაც აუდიოჩანაწერი არ აქვთ, სხვებს არ უჩნდებათ. დაამატე ერთი მაინც, რომ მოგისმინონ.';

  @override
  String get noClipsAction => 'ჩანაწერის გაკეთება';

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
  String get stampJam => 'არ მეყო';

  @override
  String get stampPass => 'მეყო';

  @override
  String swipeHint(String jam, String pass) {
    return 'მარჯვნივ გასწიე — $jam, მარცხნივ — $pass';
  }

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
      'ჯერჯერობით ესაა ყველა. მოიწვიე ნაცნობი მუსიკოსები ან გააფართოვე ფილტრები.';

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
  String get navAdd => 'ჩანაწერის გაკეთება';

  @override
  String get recordTitle => 'ახალი ჩანაწერი';

  @override
  String get recordStarting => 'მიკროფონი ირთვება…';

  @override
  String get recordRecording => 'მიმდინარეობს ჩაწერა';

  @override
  String get recordStop => 'გაჩერება';

  @override
  String recordDone(String length) {
    return 'ჩაიწერა: $length';
  }

  @override
  String get recordSave => 'პროფილში დამატება';

  @override
  String get recordListen => 'მოსმენა';

  @override
  String get recordStopListening => 'მოსმენის შეწყვეტა';

  @override
  String get recordAgain => 'თავიდან ჩაწერა';

  @override
  String get recordUploadFile => 'ან ატვირთე ფაილი';

  @override
  String get errMicDenied =>
      'OCTAVA-ს არ აქვს მიკროფონის გამოყენების ნებართვა. დაუშვი ის ბრაუზერის ან ტელეფონის პარამეტრებში და სცადე თავიდან.';

  @override
  String get errRecord => 'ჩაწერა ვერ მოხერხდა. სცადე თავიდან.';

  @override
  String get errRecordShort => 'ძალიან მოკლეა. ჩაწერე მინიმუმ ერთი წამი.';

  @override
  String get clipsInfo =>
      '5-მდე ჩანაწერი, თითო 2 წუთამდე. ვარსკვლავით მონიშნე ის, რომელიც შენს ბარათზე უნდა ჟღერდეს; თორემ პირველი ჩანაწერი ჟღერს.';

  @override
  String get clipMakeSong => 'გახადე ბარათის სიმღერა';

  @override
  String get clipIsSong => 'შენი ბარათის სიმღერა';

  @override
  String get errClipSong =>
      'ბარათის სიმღერის შეცვლა ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

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
    return 'ჩანაწერი მაქსიმუმ 2 წუთი შეიძლება იყოს. ეს არის $length.';
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

  @override
  String get genreRock => 'როკი';

  @override
  String get genrePop => 'პოპი';

  @override
  String get genreIndie => 'ინდი';

  @override
  String get genreAltRock => 'ალტერნატიული როკი';

  @override
  String get genrePunk => 'პანკი';

  @override
  String get genrePostPunk => 'პოსტ-პანკი';

  @override
  String get genreHardcore => 'ჰარდკორი';

  @override
  String get genreMetal => 'მეტალი';

  @override
  String get genreGrunge => 'გრანჯი';

  @override
  String get genreMathRock => 'მეთ-როკი';

  @override
  String get genrePostRock => 'პოსტ-როკი';

  @override
  String get genreShoegaze => 'შუგეიზი';

  @override
  String get genreDreamPop => 'დრიმ-პოპი';

  @override
  String get genreSynthPop => 'სინთ-პოპი';

  @override
  String get genreCityPop => 'სითი-პოპი';

  @override
  String get genreDisco => 'დისკო';

  @override
  String get genreFunk => 'ფანკი';

  @override
  String get genreSoul => 'სოული';

  @override
  String get genreNeoSoul => 'ნეო-სოული';

  @override
  String get genreRAndB => 'R&B';

  @override
  String get genreHipHop => 'ჰიპ-ჰოპი';

  @override
  String get genreRap => 'რეპი';

  @override
  String get genreJazz => 'ჯაზი';

  @override
  String get genreBlues => 'ბლუზი';

  @override
  String get genreGospel => 'გოსპელი';

  @override
  String get genreElectronic => 'ელექტრონული';

  @override
  String get genreTechno => 'ტექნო';

  @override
  String get genreHouse => 'ჰაუსი';

  @override
  String get genreAmbient => 'ემბიენტი';

  @override
  String get genreLoFi => 'ლო-ფაი';

  @override
  String get genreExperimental => 'ექსპერიმენტული';

  @override
  String get genreFolk => 'ფოლკი';

  @override
  String get genreIndieFolk => 'ინდი-ფოლკი';

  @override
  String get genreGeorgianFolk => 'ქართული ხალხური';

  @override
  String get genreSingerSongwriter => 'ავტორ-შემსრულებელი';

  @override
  String get genreCountry => 'ქანთრი';

  @override
  String get genreReggae => 'რეგი';

  @override
  String get genreSka => 'სკა';

  @override
  String get genreLatin => 'ლათინო';

  @override
  String get genreWorld => 'მსოფლიო მუსიკა';

  @override
  String get genreClassical => 'კლასიკური';

  @override
  String get genreSoundtrack => 'საუნდტრეკი';

  @override
  String get bandEdit => 'რედაქტირება';

  @override
  String get bandRolesTitle => 'ვინ სჭირდება შენს ბენდს?';

  @override
  String bandRolesHint(int max) {
    return 'შენს გარდა მაქსიმუმ $max ადგილი.';
  }

  @override
  String bandRolesCount(int count, int max) {
    return '$count / $max';
  }

  @override
  String get bandRolesEmpty => 'აირჩიე ერთი როლი მაინც.';

  @override
  String get bandRolesSave => 'შენახვა';

  @override
  String get roleMore => 'კიდევ ერთი';

  @override
  String get roleFewer => 'ერთით ნაკლები';

  @override
  String roleCount(String instrument, int count) {
    return '$instrument ×$count';
  }

  @override
  String get sectionBand => 'ვინ სჭირდება ბენდს';

  @override
  String get bandChange => 'როლების შეცვლა';

  @override
  String get bandDefaultNote =>
      'ჯერ არ აგირჩევია, ამიტომ ეს ჩვეულებრივი როლებია.';

  @override
  String matchNoSlot(String instrument) {
    return 'შენს ბენდს ახლა ადგილი „$instrument“ არ სჭირდება, მაგრამ მაინც შეგიძლია მიესალმო.';
  }

  @override
  String get errSaveBand =>
      'ბენდის როლები ვერ შევინახე. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get bannerNewMatch => 'ორივეს ერთად დაკვრა გინდათ. შეეხე და მიესალმე.';

  @override
  String get seen => 'ნანახია';

  @override
  String get today => 'დღეს';

  @override
  String get chatMore => 'მეტი';

  @override
  String get seeTheirCard => 'ბარათის ნახვა';

  @override
  String get openChat => 'ჩატის გახსნა';

  @override
  String get matchCardGone => 'ეს ბარათი აღარ არის ხელმისაწვდომი.';

  @override
  String get errMatchCard =>
      'ბარათი ვერ ჩაიტვირთა. შეამოწმე კავშირი და სცადე თავიდან.';

  @override
  String get unmatch => 'დაკავშირების გაუქმება';

  @override
  String unmatchTitle(String name) {
    return 'გააუქმო კავშირი $name-თან?';
  }

  @override
  String get unmatchBody =>
      'ეს ჩატი ორივესთვის გაქრება. ამის დაბრუნება შეუძლებელია.';

  @override
  String unmatchDone(String name) {
    return '$name-თან კავშირი გაუქმდა.';
  }

  @override
  String get errUnmatch =>
      'კავშირი ვერ გაუქმდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get undo => 'დაბრუნება';

  @override
  String get errUndo =>
      'ბარათი ვერ დავაბრუნე. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get authHeadline => 'მოუსმინე. დაუკარი. შექმენი ბენდი.';

  @override
  String get authAgeTitle => 'მხოლოდ 16+ მუსიკოსები';

  @override
  String get authAgeBody =>
      'რეგისტრაციით ადასტურებ, რომ 16 წლის ან უფროსი ხარ.';

  @override
  String bandFilled(int filled, int total) {
    return '$filled / $total შევსებულია';
  }

  @override
  String get sectionTheme => 'თემა';

  @override
  String get themeLight => 'ნათელი';

  @override
  String get themeDark => 'მუქი';

  @override
  String get themeColours => 'ფერები';

  @override
  String get paletteOctava => 'OCTAVA';

  @override
  String get paletteSunset => 'მზის ჩასვლა';

  @override
  String get paletteGarage => 'გარაჟი';

  @override
  String get paletteSynthwave => 'სინთვეივი';

  @override
  String get paletteMono => 'მონო';

  @override
  String get themeInfo =>
      '„მოწყობილობის“ ნიშნავს ტელეფონის ან ბრაუზერის პარამეტრს.';

  @override
  String get themeToDark => 'მუქ რეჟიმზე გადართვა';

  @override
  String get themeToLight => 'ნათელ რეჟიმზე გადართვა';

  @override
  String cardAlsoPlays(String instruments) {
    return 'ასევე: $instruments';
  }

  @override
  String get instrumentMakeMain => 'გახადე მთავარ ინსტრუმენტად';

  @override
  String get instrumentIsMain => 'შენი მთავარი ინსტრუმენტი';

  @override
  String get errEmailBusy =>
      'ახლა რეგისტრაცია გადატვირთულია. სცადე თავიდან ერთ საათში.';

  @override
  String get clipPosition => 'პოზიცია ჩანაწერში';

  @override
  String get bandsTitle => 'ბენდები';

  @override
  String get bandCreate => 'ბენდის შექმნა';

  @override
  String get bandCreateTitle => 'დაარქვი სახელი ბენდს';

  @override
  String get bandNameLabel => 'ბენდის სახელი';

  @override
  String get bandNameError => 'ბენდს სახელი სჭირდება';

  @override
  String get bandCreateConfirm => 'შექმნა';

  @override
  String bandInviteTitle(String band) {
    return '$band გეპატიჟება';
  }

  @override
  String get bandAccept => 'მიღება';

  @override
  String get bandDecline => 'უარი';

  @override
  String bandJoined(String band) {
    return 'შეუერთდი ბენდს $band!';
  }

  @override
  String bandMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count წევრი',
      one: '1 წევრი',
    );
    return '$_temp0';
  }

  @override
  String bandVotesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count კენჭისყრა გელოდება',
      one: '1 კენჭისყრა გელოდება',
    );
    return '$_temp0';
  }

  @override
  String get bandMembers => 'წევრები';

  @override
  String get bandYou => 'შენ';

  @override
  String get bandAddMember => 'წევრის დამატება';

  @override
  String get bandAddMemberTitle => 'შესთავაზე ვინმე შენი მეჩებიდან';

  @override
  String get bandAddMemberEmpty =>
      'შესათავაზებელი აღარავინაა. ჯერ მეტ მუსიკოსთან დაამეჩდი.';

  @override
  String bandProposedVote(String name) {
    return 'შესთავაზე $name. ბენდის წევრები ხმას მისცემენ.';
  }

  @override
  String bandProposedInvite(String name) {
    return 'მოწვევა გაეგზავნა: $name.';
  }

  @override
  String get bandWaiting => 'ახალი წევრები';

  @override
  String bandProposedBy(String name) {
    return 'შესთავაზა: $name';
  }

  @override
  String bandApprovals(int yes, int total) {
    return '$yes / $total დაეთანხმა';
  }

  @override
  String get bandApprove => 'თანხმობა';

  @override
  String get bandReject => 'უარყოფა';

  @override
  String get bandYouApproved => 'შენ დაეთანხმე';

  @override
  String get bandInvited => 'მოწვეულია, პასუხს ველოდებით';

  @override
  String bandRejectTitle(String name) {
    return 'უარვყოთ $name?';
  }

  @override
  String get bandRejectBody =>
      'ერთი უარიც საკმარისია: ის არ მიიღებს მოწვევას და ამის შესახებ არ ეცოდინება.';

  @override
  String get bandLeave => 'ბენდიდან წასვლა';

  @override
  String bandLeaveTitle(String band) {
    return 'ტოვებ ბენდს $band?';
  }

  @override
  String get bandLeaveBody =>
      'ვეღარ ნახავ მის წევრებს და კენჭისყრებს. თუ ბოლო წევრი ხარ, ბენდი წაიშლება.';

  @override
  String get errBandLoad => 'ბენდები ვერ ჩაიტვირთა. შეამოწმე ინტერნეტი.';

  @override
  String get errBandAction =>
      'ვერ მოხერხდა. შეამოწმე ინტერნეტი და სცადე თავიდან.';

  @override
  String get errBandNotMatched =>
      'შეგიძლია შესთავაზო მხოლოდ ის, ვისთანაც დამეჩდი.';

  @override
  String get errBandAlreadyIn => 'ის უკვე ბენდშია.';

  @override
  String get errBandAlreadyProposed => 'ის უკვე შეთავაზებულია.';

  @override
  String get errBandFull => 'ბენდში მაქსიმუმ 12 წევრი შეიძლება იყოს.';

  @override
  String get errBandTooMany => 'შეგიძლია იყო მაქსიმუმ 10 ბენდში.';

  @override
  String get errBandAgeRule =>
      'სხვა ასაკობრივი ჯგუფის წევრის მისაღებად ბენდში უკვე მინიმუმ 2 წევრი უნდა იყოს.';

  @override
  String get errBandUnavailable => 'ეს ადამიანი ხელმისაწვდომი არაა.';

  @override
  String get errBandVoteOver => 'ამ ადამიანზე კენჭისყრა უკვე დასრულდა.';

  @override
  String get errBandInviteClosed => 'ეს მოწვევა აღარ მოქმედებს.';

  @override
  String get errBandNotMember => 'შენ აღარ ხარ ამ ბენდში.';

  @override
  String get errBandNeedsProfile => 'ჯერ შექმენი პროფილი.';

  @override
  String get bandCancelRequest => 'მოთხოვნის გაუქმება';

  @override
  String bandCancelTitle(String name) {
    return 'გავაუქმოთ მოთხოვნა: $name?';
  }

  @override
  String get bandCancelBody =>
      'მას ამის შესახებ არ ეცოდინება. შეგიძლია მოგვიანებით ისევ შესთავაზო.';

  @override
  String get bandCancelKeep => 'დატოვება';

  @override
  String bandCancelled(String name) {
    return 'მოთხოვნა გაუქმდა: $name.';
  }

  @override
  String get errBandCancelNotYours =>
      'გაუქმება მხოლოდ იმას შეუძლია, ვინც შესთავაზა.';

  @override
  String get bandChatOpen => 'ბენდის ჩატის გახსნა';

  @override
  String get bandChatEmpty => 'შეტყობინებები ჯერ არაა. მიესალმე ბენდს!';

  @override
  String get bandChatClosedAlone => 'ბენდის ჩატის დასაწყებად დაამატე წევრი.';

  @override
  String get bandChatClosedAges =>
      'ჩატი შეჩერებულია: ბენდს, სადაც მოზარდები და ზრდასრულები არიან, მინიმუმ 3 წევრი სჭირდება. ჩატი ხელახლა გაიხსნება, როცა ვინმე შემოუერთდება.';

  @override
  String bandSeenBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ნახა $count-მა',
      one: 'ნახა 1-მა',
    );
    return '$_temp0';
  }

  @override
  String get bandSeenByAll => 'ყველამ ნახა';

  @override
  String get bandMembersButton => 'წევრები';

  @override
  String bandMessagePreview(String name, String message) {
    return '$name: $message';
  }

  @override
  String get errBandSendClosed => 'ბენდის ჩატი ახლა დახურულია.';

  @override
  String bandMemberRole(String instrument, String band) {
    return '$instrument · $band';
  }

  @override
  String get reportMessage => 'საჩივარი ამ შეტყობინებაზე';

  @override
  String get errBandProfile => 'ზოგიერთი ჟანრი ან როლი სიაში არაა.';

  @override
  String get bandEditTitle => 'ბენდის რედაქტირება';

  @override
  String get bandEditHint => 'ამას ხედავენ მუსიკოსები შენი ბენდის ბარათზე.';

  @override
  String get bandDescriptionLabel => 'ბენდის შესახებ';

  @override
  String get bandDescriptionHint =>
      'რას უკრავთ, რისკენ მიისწრაფვით, რამდენად ხშირად გაქვთ რეპეტიცია…';

  @override
  String get bandOpenRolesLabel => 'ვეძებთ';

  @override
  String get bandOpenRolesHint =>
      'ინსტრუმენტები, რომლებიც გინდა დაამატო. ვინც მათზე უკრავს, შენს ბენდს პირველს ნახავს.';

  @override
  String get bandProfileTitle => 'ბენდის პროფილი';

  @override
  String get bandProfileEmpty =>
      'დაამატე აღწერა, ჟანრები და როლები, რომლებსაც ეძებთ, რომ მუსიკოსებმა იცოდნენ, ვინ ხართ.';

  @override
  String bandLookingFor(String roles) {
    return 'ვეძებთ: $roles';
  }

  @override
  String get bandClipPlay => 'ბენდის ჩანაწერის მოსმენა';

  @override
  String get bandClipStop => 'ბენდის ჩანაწერის გაჩერება';

  @override
  String get bandClipNone => 'ბენდის ჩანაწერი ჯერ არაა';

  @override
  String bandClipLength(String length) {
    return 'ბენდის ჩანაწერი · $length';
  }

  @override
  String get bandClipAdd => 'ბენდის ჩანაწერის ჩაწერა ან ატვირთვა';

  @override
  String get bandClipReplace => 'ბენდის ჩანაწერის შეცვლა';

  @override
  String get bandClipRemove => 'ბენდის ჩანაწერის წაშლა';

  @override
  String get bandClipSave => 'ბენდის ჩანაწერად გამოყენება';

  @override
  String get bandClipSaved => 'ბენდის ჩანაწერი შენახულია.';

  @override
  String get bandClipRemoved => 'ბენდის ჩანაწერი წაიშალა.';

  @override
  String get bandProfileSaved => 'ბენდის პროფილი შენახულია.';

  @override
  String get errBandRemoveSelf => 'წასასვლელად გამოიყენე „ბენდიდან წასვლა“.';

  @override
  String get errBandNotInBand => 'ის ბენდში აღარ არის.';

  @override
  String get errBandRemovalExists =>
      'მის გარიცხვაზე კენჭისყრა უკვე მიმდინარეობს.';

  @override
  String bandMemberOptions(String name) {
    return 'პარამეტრები: $name';
  }

  @override
  String get bandRemoveMember => 'ბენდიდან გარიცხვა';

  @override
  String bandRemoveTitle(String name, String band) {
    return 'გავრიცხოთ $name ბენდიდან $band?';
  }

  @override
  String bandRemoveBody(String name) {
    return 'ეს იწყებს კენჭისყრას: დანარჩენი წევრების უმრავლესობა უნდა დაეთანხმოს. $name კენჭისყრას ვერ დაინახავს.';
  }

  @override
  String get bandRemoveConfirm => 'კენჭისყრის დაწყება';

  @override
  String bandRemoveStarted(String name) {
    return 'დაიწყო კენჭისყრა გარიცხვაზე: $name.';
  }

  @override
  String bandRemovedNow(String name) {
    return '$name ბენდიდან გაირიცხა.';
  }

  @override
  String get bandRemovalsHeading => 'წევრების გარიცხვა';

  @override
  String bandRemovalCount(int yes, int needed) {
    return '$yes / $needed საჭირო';
  }

  @override
  String get bandRemovalYes => 'გარიცხვა';

  @override
  String get bandRemovalNo => 'დატოვება';

  @override
  String get bandYouAgreed => 'შენ დაეთანხმე';

  @override
  String get bandYouDisagreed => 'შენ დატოვება აირჩიე';

  @override
  String get bandRemovalCancel => 'კენჭისყრის გაუქმება';

  @override
  String get bandRemovalCancelled => 'კენჭისყრა გაუქმდა.';

  @override
  String bandCardSemantics(String name) {
    return 'ბენდი: $name';
  }

  @override
  String get bandCardStamp => 'ბენდი';

  @override
  String get bandCardNeedsYou => 'შენი ინსტრუმენტი სჭირდებათ';

  @override
  String bandAskedToJoin(String band) {
    return 'მოთხოვნა გაეგზავნა ბენდს $band. წევრები ხმას მისცემენ.';
  }

  @override
  String bandPassedOn(String band) {
    return 'გამოტოვე ბენდი $band.';
  }

  @override
  String get bandNoOpenRoles => 'კონკრეტულ როლებს ჯერ არ ეძებენ';

  @override
  String get bandSlotFilled => 'ბენდშია';

  @override
  String get bandRequestsHeading => 'გაწევრიანება სურთ';

  @override
  String get bandAskedToJoinLabel => 'გაწევრიანება სურს';

  @override
  String bandMemberJoined(String name) {
    return '$name შემოუერთდა ბენდს!';
  }

  @override
  String get bandRequestWaiting =>
      'მოთხოვნა გაგზავნილია · ველოდებით ბენდის კენჭისყრას';

  @override
  String get bandWithdraw => 'გაუქმება';

  @override
  String get bandWithdrawn => 'მოთხოვნა გაუქმდა.';

  @override
  String get voiceMessage => '🎤 ხმოვანი შეტყობინება';

  @override
  String get voiceRecord => 'ხმოვანი შეტყობინების ჩაწერა';

  @override
  String get voiceCancel => 'ჩაწერის გაუქმება';

  @override
  String get voiceSend => 'ხმოვანის გაგზავნა';

  @override
  String voiceRecording(String time) {
    return 'იწერება… $time';
  }

  @override
  String get voicePlay => 'ხმოვანის მოსმენა';

  @override
  String get voiceStop => 'ხმოვანის გაჩერება';

  @override
  String get editMessage => 'შეტყობინების რედაქტირება';

  @override
  String get editMessageHint =>
      'შეტყობინების შეცვლა გაგზავნიდან 15 წუთის განმავლობაში შეგიძლია.';

  @override
  String get editSave => 'შენახვა';

  @override
  String editedAt(String time) {
    return 'შეცვლილია · $time';
  }

  @override
  String get errEditTooLate =>
      'შეტყობინების შეცვლა მხოლოდ 15 წუთის განმავლობაში შეიძლება.';

  @override
  String get errEdit => 'შეტყობინება ვერ შეიცვალა. სცადე თავიდან.';

  @override
  String get rehearsalsTitle => 'რეპეტიციები';

  @override
  String get rehearsalAdd => 'დამატება';

  @override
  String get rehearsalsEmpty =>
      'რეპეტიცია დაგეგმილი არაა. დაამატე და ყველა იტყვის, მოვა თუ არა.';

  @override
  String get rehearsalsShowAll => 'ყველას ნახვა';

  @override
  String get rehearsalsShowLess => 'ნაკლების ნახვა';

  @override
  String get rehearsalGoing => 'მოვალ';

  @override
  String get rehearsalCant => 'ვერ მოვალ';

  @override
  String get rehearsalNoAnswer => 'ჯერ არ უპასუხიათ';

  @override
  String rehearsalCounts(int going, int cant) {
    return '$going მოვა · $cant ვერ მოვა';
  }

  @override
  String get rehearsalCancelledLabel => 'გაუქმებულია';

  @override
  String get rehearsalEdit => 'რეპეტიციის რედაქტირება';

  @override
  String get rehearsalCallOff => 'ამ დღის გაუქმება';

  @override
  String get rehearsalRestore => 'ამ დღის დაბრუნება';

  @override
  String get rehearsalDelete => 'რეპეტიციის წაშლა';

  @override
  String get rehearsalDeleteTitle => 'წავშალოთ რეპეტიცია?';

  @override
  String get rehearsalDeleteBody => 'ის ბენდის ყველა წევრისთვის გაქრება.';

  @override
  String get rehearsalDeleteWeeklyBody =>
      'ეს წაშლის ყველა კვირის რეპეტიციას, ბენდის ყველა წევრისთვის. ერთი კვირის გამოსატოვებლად ის დღე გააუქმე.';

  @override
  String get rehearsalAdded => 'რეპეტიცია დაემატა.';

  @override
  String get rehearsalSaved => 'რეპეტიცია შენახულია.';

  @override
  String get rehearsalCalledOff => 'ეს დღე გაუქმდა.';

  @override
  String get rehearsalDeleted => 'რეპეტიცია წაიშალა.';

  @override
  String get rehearsalAddTitle => 'რეპეტიციის დამატება';

  @override
  String get rehearsalEditTitle => 'რეპეტიციის რედაქტირება';

  @override
  String get rehearsalDay => 'დღე';

  @override
  String get rehearsalStart => 'იწყება';

  @override
  String get rehearsalLength => 'ხანგრძლივობა';

  @override
  String durationMinutes(int minutes) {
    return '$minutes წთ';
  }

  @override
  String durationHours(int hours) {
    return '$hours სთ';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours სთ $minutes წთ';
  }

  @override
  String get rehearsalPlace => 'ადგილი (არასავალდებულო)';

  @override
  String get rehearsalPlaceHint => 'სტუდია, მისამართი ან ვინმეს სახლი';

  @override
  String get rehearsalNotes => 'შენიშვნები (არასავალდებულო)';

  @override
  String get rehearsalNotesHint => 'რა წამოვიღოთ, რა ვივარჯიშოთ…';

  @override
  String get rehearsalWeekly => 'ყოველ კვირა გამეორება';

  @override
  String rehearsalWeeklyHint(String weekday) {
    return 'ყოველკვირეულად ($weekday), იმავე დროს';
  }

  @override
  String get rehearsalUntil => 'სანამდე';

  @override
  String get rehearsalNoEnd => 'დასრულების თარიღის გარეშე';

  @override
  String get rehearsalClearEnd => 'დასრულების თარიღის გარეშე';

  @override
  String rehearsalReminder(String band, String time) {
    return '$band: რეპეტიცია $time-ზე';
  }

  @override
  String get rehearsalReminderBody => 'მალე იწყება. შეეხე, რომ ნახო ვინ მოდის.';

  @override
  String get errRehearsalsLoad =>
      'რეპეტიციები ვერ ჩაიტვირთა. შეამოწმე ინტერნეტი.';

  @override
  String get errRehearsalSave => 'რეპეტიცია ვერ შეინახა. სცადე თავიდან.';

  @override
  String get rehearsalsNoneThisWeek => 'მომდევნო 7 დღეში არაფერია.';

  @override
  String recordLimitAt(String time) {
    return 'ჩაწერა თავისით შეჩერდება $time-ზე.';
  }

  @override
  String get songsTitle => 'სიმღერები';

  @override
  String get songsEmpty =>
      'სიმღერები ჯერ არაა. დაამატე ის, რასაც უკრავთ ან გინდათ ისწავლოთ.';

  @override
  String songsShowAll(int count) {
    return 'ყველა სიმღერა ($count)';
  }

  @override
  String get songReady => 'მზადაა';

  @override
  String get songLearning => 'ვსწავლობთ';

  @override
  String get songIdea => 'იდეა';

  @override
  String songBpm(int bpm) {
    return '$bpm BPM';
  }

  @override
  String get songPlay => 'ჩანაწერის მოსმენა';

  @override
  String get songAddTitle => 'სიმღერის დამატება';

  @override
  String get songTitleLabel => 'სიმღერის სახელი';

  @override
  String get songTitleError => 'სიმღერას სახელი სჭირდება.';

  @override
  String get songTempoError => 'ტემპი უნდა იყოს რიცხვი 20-დან 320-მდე.';

  @override
  String get songPageTitle => 'სიმღერა';

  @override
  String get songKeyLabel => 'ტონალობა';

  @override
  String get songKeyHint => 'მაგ. მი მინორი';

  @override
  String get songTempoLabel => 'ტემპი (BPM)';

  @override
  String get songNotesLabel => 'შენიშვნები';

  @override
  String get songNotesHint => 'სტრუქტურა, კაპო, ვინ რას მღერის…';

  @override
  String get songLinksLabel => 'ბმულები';

  @override
  String get songLinkHint => 'YouTube, Spotify, აკორდების ან ტექსტის ბმული';

  @override
  String get songAddLink => 'ბმულის დამატება';

  @override
  String get songRemoveLink => 'ბმულის წაშლა';

  @override
  String get songRecordingLabel => 'ჩანაწერი';

  @override
  String get songNoRecording => 'ჩანაწერი ჯერ არაა';

  @override
  String get songAddRecording => 'ჩაწერა ან ატვირთვა';

  @override
  String get songReplaceRecording => 'ჩანაწერის შეცვლა';

  @override
  String get songRemoveRecording => 'ჩანაწერის წაშლა';

  @override
  String get songUseRecording => 'ამ სიმღერისთვის გამოყენება';

  @override
  String get songRecordingSaved => 'ჩანაწერი შენახულია.';

  @override
  String get songSaved => 'სიმღერა შენახულია.';

  @override
  String get songDelete => 'სიმღერის წაშლა';

  @override
  String songDeleteTitle(String title) {
    return 'წავშალოთ „$title“?';
  }

  @override
  String get songDeleteBody =>
      'ის და მისი ჩანაწერი ბენდის ყველა წევრისთვის გაქრება.';

  @override
  String get errSongsLoad => 'სიმღერები ვერ ჩაიტვირთა. შეამოწმე ინტერნეტი.';

  @override
  String get errSongSave => 'სიმღერა ვერ შეინახა. სცადე თავიდან.';

  @override
  String errSongTooLong(String length) {
    return 'სიმღერის ჩანაწერი მაქსიმუმ 10 წუთი შეიძლება იყოს. ეს არის $length.';
  }

  @override
  String get setlistsTitle => 'სეტლისტები';

  @override
  String get setlistsEmpty =>
      'სეტლისტი ჯერ არ არის. შექმენი შემდეგი კონცერტისთვის ან რეპეტიციისთვის.';

  @override
  String get setlistAddTitle => 'ახალი სეტლისტი';

  @override
  String get setlistNameLabel => 'სეტლისტის სახელი';

  @override
  String get setlistNameHint => 'მაგ. პარასკევის კონცერტი';

  @override
  String get setlistPageTitle => 'სეტლისტი';

  @override
  String setlistSongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count სიმღერა',
      one: '1 სიმღერა',
      zero: 'სიმღერების გარეშე',
    );
    return '$_temp0';
  }

  @override
  String setlistNoLength(int count) {
    return '$count ჩანაწერის გარეშე';
  }

  @override
  String get setlistEmptySongs =>
      'ამ სეტლისტში სიმღერები ჯერ არ არის. დაამატე ბენდის სიმღერებიდან.';

  @override
  String get setlistAddSongs => 'სიმღერების დამატება';

  @override
  String setlistAddSongsButton(int count) {
    return 'დამატება ($count)';
  }

  @override
  String get setlistAllAdded => 'ყველა სიმღერა უკვე ამ სეტლისტშია.';

  @override
  String get setlistNoBandSongs =>
      'ბენდს სიმღერები ჯერ არ აქვს. ჯერ დაამატე ისინი „სიმღერებში“.';

  @override
  String get setlistRemoveSong => 'სეტლისტიდან ამოღება';

  @override
  String get setlistDragHint =>
      'რიგის შესაცვლელად დააჭირე სიმღერას და გადაათრიე.';

  @override
  String get setlistRename => 'სახელის შეცვლა';

  @override
  String get setlistDelete => 'სეტლისტის წაშლა';

  @override
  String setlistDeleteTitle(String name) {
    return 'წავშალო „$name“?';
  }

  @override
  String get setlistDeleteBody =>
      'სიმღერები ბენდში რჩება; იშლება მხოლოდ ეს სია. რეპეტიციებს, რომლებიც მას იყენებდნენ, დანარჩენი დეტალები შეუნარჩუნდებათ.';

  @override
  String get setlistDeleted => 'სეტლისტი წაიშალა.';

  @override
  String get errSetlistsLoad => 'სეტლისტები ვერ ჩაიტვირთა. შეამოწმე კავშირი.';

  @override
  String get errSetlistSave => 'სეტლისტი ვერ შეინახა. სცადე თავიდან.';

  @override
  String get rehearsalSetlist => 'სავარჯიშო სეტლისტი';

  @override
  String get rehearsalNoSetlist => 'არცერთი';

  @override
  String rehearsalPractise(String name) {
    return 'ვარჯიში: $name';
  }

  @override
  String get publicPageTitle => 'საჯარო გვერდი';

  @override
  String get publicPageOffHint =>
      'გამორთულია: ბენდის გვერდს მხოლოდ მისი წევრები ხედავენ.';

  @override
  String get publicPageOnHint =>
      'ჩართულია: ბმულის მქონე ნებისმიერი ადამიანი ხედავს სახელს, პროფილს, ჩანაწერს, წევრებს და მზა სიმღერებს. 16–17 წლის წევრები მხოლოდ ინსტრუმენტით ჩანან.';

  @override
  String get publicPageCopy => 'ბმულის კოპირება';

  @override
  String get publicPageCopied => 'ბმული დაკოპირდა.';

  @override
  String get publicPageView => 'გვერდის ნახვა';

  @override
  String get publicPageTurnedOn => 'ბენდის საჯარო გვერდი ჩაირთო.';

  @override
  String get publicPageTurnedOff => 'საჯარო გვერდი გამოირთო.';

  @override
  String get publicBandSongs => 'მზადაა დასაკრავად';

  @override
  String get publicBandNotFound =>
      'ბენდის ეს გვერდი მიუწვდომელია. შესაძლოა, ბენდმა ის დამალა.';

  @override
  String get publicBandJoin => 'შემოუერთდი OCTAVA-ს';

  @override
  String get publicBandJoinHint =>
      'OCTAVA-ზე მუსიკოსები ერთმანეთს პოულობენ და ბენდებს ქმნიან.';

  @override
  String get errPublicBandLoad => 'ბენდი ვერ ჩაიტვირთა. შეამოწმე კავშირი.';

  @override
  String get profileGroup => 'პროფილი';

  @override
  String get settingsGroup => 'პარამეტრები';

  @override
  String get summaryEmpty => 'ჯერ არ არის';

  @override
  String clipsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ჩანაწერი',
      one: '1 ჩანაწერი',
      zero: 'ჩანაწერები ჯერ არ არის',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccount => 'ანგარიშის წაშლა';

  @override
  String get deleteAccountTitle => 'წავშალო შენი ანგარიში?';

  @override
  String get deleteAccountBody =>
      'სამუდამოდ წაიშლება შენი პროფილი, ჩანაწერები, ავატარი, მეჩები, შეტყობინებები და ბენდებში წევრობა. ამის გაუქმება შეუძლებელია.';

  @override
  String get deleteAccountConfirm => 'წაშალე ჩემი ანგარიში';

  @override
  String get accountDeleted => 'შენი ანგარიში წაიშალა.';

  @override
  String get errDeleteAccount =>
      'ანგარიში ვერ წაიშალა. შეამოწმე კავშირი და სცადე თავიდან.';

  @override
  String get modGroup => 'მოდერაცია';

  @override
  String get modReports => 'საჩივრები';

  @override
  String modOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ღია საჩივარი',
      one: '1 ღია საჩივარი',
      zero: 'ღია საჩივრები არ არის',
    );
    return '$_temp0';
  }

  @override
  String get modEmpty => 'ღია საჩივრები არ არის. ყველაფერი რიგზეა.';

  @override
  String modReportedBy(String name, String when) {
    return 'საჩივარი: $name · $when';
  }

  @override
  String modAgainstCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'მის წინააღმდეგ $count ღია საჩივარია',
      one: 'მის წინააღმდეგ 1 ღია საჩივარია',
    );
    return '$_temp0';
  }

  @override
  String get modHiddenFromFeed => 'დამალულია ლენტიდან განხილვამდე';

  @override
  String get modSuspended => 'შეჩერებულია';

  @override
  String get modMessageGone => 'შეტყობინება უკვე წაშლილია.';

  @override
  String get modDismiss => 'უარყოფა';

  @override
  String get modRemoveMessage => 'შეტყობინების წაშლა';

  @override
  String get modSuspend => 'შეჩერება';

  @override
  String get modUnsuspend => 'შეჩერების მოხსნა';

  @override
  String modSuspendTitle(String name) {
    return 'შევაჩერო $name?';
  }

  @override
  String get modSuspendBody =>
      'ის დაიმალება ლენტიდან, გავა ანგარიშიდან და ვეღარ შევა. მისი ყველა ღია საჩივარი დაიხურება.';

  @override
  String get modDismissed => 'საჩივარი უარყოფილია.';

  @override
  String get modMessageRemoved => 'შეტყობინება წაიშალა.';

  @override
  String modSuspendedDone(String name) {
    return '$name შეჩერებულია.';
  }

  @override
  String get modUnsuspended => 'შეჩერება მოხსნილია.';

  @override
  String get errModeration =>
      'საჩივრები ვერ ჩაიტვირთა ან ვერ განახლდა. სცადე თავიდან.';

  @override
  String get legalAgree => 'ანგარიშის შექმნით ეთანხმები:';

  @override
  String get legalTerms => 'გამოყენების წესებს';

  @override
  String get legalPrivacy => 'კონფიდენციალურობის პოლიტიკას';

  @override
  String get legalTermsRow => 'გამოყენების წესები';

  @override
  String get legalPrivacyRow => 'კონფიდენციალურობის პოლიტიკა';

  @override
  String get modViewProfile => 'პროფილის ნახვა';

  @override
  String modEvidenceTitle(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'მისი ბოლო $count შეტყობინება $name-სთვის',
      one: 'მისი ბოლო შეტყობინება $name-სთვის',
    );
    return '$_temp0';
  }

  @override
  String get modEvidenceNote =>
      'დაკოპირდა საჩივრის გაგზავნისას; რჩება მაშინაც, თუ ჩატს წაშლიან.';

  @override
  String modJoined(String date) {
    return 'შემოუერთდა $date';
  }

  @override
  String get modProfileGone => 'ეს ანგარიში აღარ არსებობს.';

  @override
  String get modModerators => 'მოდერატორები';

  @override
  String modModeratorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count მოდერატორი',
      one: '1 მოდერატორი',
    );
    return '$_temp0';
  }

  @override
  String get modSearchPeople => 'მოძებნე სახელით';

  @override
  String get modSearchHint => 'ჩაწერე მინიმუმ 2 ასო.';

  @override
  String get modNoOneFound => 'ამ სახელით ვერავინ მოიძებნა.';

  @override
  String get modMakeModerator => 'მოდერატორად დანიშვნა';

  @override
  String get modIsModerator => 'მოდერატორი';

  @override
  String get modAdmin => 'ადმინი';

  @override
  String get modRemoveModerator => 'მოხსნა';

  @override
  String modRemoveModeratorTitle(String name) {
    return 'მოვხსნათ $name მოდერატორობიდან?';
  }

  @override
  String get modRemoveModeratorBody =>
      'საჩივრებს ვეღარ ნახავს. შემდეგ ისევ შეგიძლია დაამატო.';

  @override
  String modMakeModeratorTitle(String name) {
    return 'დავნიშნოთ $name მოდერატორად?';
  }

  @override
  String get modMakeModeratorBody =>
      'ნახავს ყველა საჩივარს, დარეპორტებულ შეტყობინებებს და პროფილებს, და შეეძლება ანგარიშების შეჩერება.';

  @override
  String modMadeModerator(String name) {
    return '$name ახლა მოდერატორია.';
  }

  @override
  String modRemovedModerator(String name) {
    return '$name აღარ არის მოდერატორი.';
  }

  @override
  String get errModSuspendedCant =>
      'შეჩერებული ანგარიში ვერ იქნება მოდერატორი.';

  @override
  String get errModAdminStays => 'ადმინი ყოველთვის მოდერატორად რჩება.';

  @override
  String get authForgot => 'დაგავიწყდა პაროლი?';

  @override
  String authResetSent(String email) {
    return 'თუ $email-ზე ანგარიში არსებობს, გამოვუგზავნეთ ბმული ახალი პაროლის ასარჩევად. შეამოწმე შემოსულები და სპამი.';
  }

  @override
  String get resetTitle => 'აირჩიე ახალი პაროლი';

  @override
  String get resetBody => 'მას ყველა მოწყობილობაზე შესასვლელად გამოიყენებ.';

  @override
  String get resetNew => 'ახალი პაროლი';

  @override
  String get resetRepeat => 'გაიმეორე პაროლი';

  @override
  String get resetMismatch => 'პაროლები არ ემთხვევა.';

  @override
  String get resetSave => 'პაროლის შენახვა';

  @override
  String get resetNotNow => 'ახლა არა';

  @override
  String get resetDone => 'პაროლი შეიცვალა.';

  @override
  String get forgotTitle => 'დაგავიწყდა პაროლი?';

  @override
  String get forgotBody =>
      'ჩაწერე ელფოსტა, რომლითაც დარეგისტრირდი, და გამოგიგზავნით ბმულს ახალი პაროლის ასარჩევად.';

  @override
  String get forgotSend => 'ბმულის გაგზავნა';

  @override
  String get forgotSentTitle => 'შეამოწმე ელფოსტა';

  @override
  String get forgotHint => 'არ მოგივიდა? შეამოწმე სპამი ან გაგზავნე თავიდან.';

  @override
  String get forgotResend => 'თავიდან გაგზავნა';

  @override
  String forgotResendIn(int seconds) {
    return 'თავიდან გაგზავნა $seconds წამში';
  }

  @override
  String get errResetWait => 'ახალი ბმულის მოთხოვნამდე ერთი წუთი დაიცადე.';

  @override
  String get resetBack => 'შესვლაზე დაბრუნება';

  @override
  String get errResetLink =>
      'ბმულს ვადა გაუვიდა ან უკვე გამოყენებულია. ახალი მოითხოვე შესვლის გვერდზე.';

  @override
  String get errSamePassword => 'ეს შენი ამჟამინდელი პაროლია. აირჩიე სხვა.';

  @override
  String get inviteGroup => 'მეგობრები';

  @override
  String get inviteMusicians => 'მუსიკოსების მოწვევა';

  @override
  String get inviteSummary => 'მოიწვიე ბენდის წევრები და მეგობრები';

  @override
  String get inviteSubject => 'შემომიერთდი OCTAVA-ზე';

  @override
  String inviteMessage(String link) {
    return 'OCTAVA-ზე ვარ: აპი, სადაც მუსიკოსები ერთმანეთის დაკვრას უსმენენ და ბენდებს ქმნიან. შემომიერთდი: $link';
  }

  @override
  String get inviteCopied => 'მოწვევის ბმული დაკოპირდა. ჩასვი ჩატში.';

  @override
  String get heardSection => 'ბოლო კითხვა';

  @override
  String get heardQuestion => 'საიდან გაიგე OCTAVA-ს შესახებ? (არასავალდებულო)';

  @override
  String get heardTiktok => 'TikTok';

  @override
  String get heardInstagram => 'Instagram';

  @override
  String get heardFriend => 'მეგობრისგან';

  @override
  String get heardPoster => 'პოსტერი ან ფლაერი';

  @override
  String get heardJamNight => 'ჯემ-საღამო';

  @override
  String get heardSearch => 'ძიება ან აპების მაღაზია';

  @override
  String get heardOther => 'სხვაგან';
}
