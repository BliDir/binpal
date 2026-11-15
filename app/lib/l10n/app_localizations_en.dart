// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BinPal';

  @override
  String get tabToday => 'Today';

  @override
  String get tabSearch => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get areaNotSet => 'Set your area';

  @override
  String get todayTitle => 'Today';

  @override
  String get todayNoAreaTitle => 'No area yet';

  @override
  String get todayNoAreaBody =>
      'Choose your area to see which rubbish goes out today and tomorrow.';

  @override
  String get searchHint => 'How do I sort this item?';

  @override
  String get searchNoAreaBody =>
      'Item search works offline once your area\'s data is downloaded.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchSubtitle => 'Find how to sort and put out an item.';

  @override
  String get searchExamplesTitle => 'Search examples';

  @override
  String get searchOfflineTitle => 'Available offline';

  @override
  String get searchOfflineBody =>
      'Search and sorting rules work without internet once your area\'s data is downloaded.';

  @override
  String get searchDownloading => 'Downloading your area\'s data…';

  @override
  String get searchDownloadFailed =>
      'Couldn\'t download your area\'s data. Check your connection and try again.';

  @override
  String get searchRetry => 'Try again';

  @override
  String get searchClear => 'Clear';

  @override
  String searchResultCount(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results for “$query”',
      one: '1 result for “$query”',
    );
    return '$_temp0';
  }

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsBody =>
      'Try another word, in English or Japanese, or a more general one: “bag” rather than “handbag”.';

  @override
  String get itemHowTo => 'How to put it out';

  @override
  String get itemInJapanese => 'In Japanese';

  @override
  String get itemTranslationNote =>
      'The English is BinPal\'s translation. The Japanese is the city\'s own.';

  @override
  String itemAboutCategory(String category) {
    return 'About $category';
  }

  @override
  String get itemSource => 'Official source';

  @override
  String itemSourceSubtitle(String name) {
    return '$name website';
  }

  @override
  String get itemVerified => 'Checked against the source';

  @override
  String get itemOpenFailed => 'Couldn\'t open the link.';

  @override
  String get settingsArea => 'Area';

  @override
  String get settingsAreaNotSet => 'Not set';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsRemindersOff => 'Off';

  @override
  String get settingsData => 'Area data';

  @override
  String settingsDataVersion(String name, int version) {
    return '$name · version $version';
  }

  @override
  String get settingsDataNone => 'Not downloaded yet';

  @override
  String get settingsDataDownloading => 'Downloading…';

  @override
  String get settingsDataFailed => 'Couldn\'t download. Tap to try again.';

  @override
  String get settingsDataStale =>
      'Couldn\'t check for updates. Using the saved data.';

  @override
  String get settingsAbout => 'About BinPal';

  @override
  String get aboutTagline =>
      'Rubbish sorting and collection days in Japan, in plain English.';

  @override
  String get aboutLicenses => 'Open-source licences';

  @override
  String get logoLabel => 'BinPal logo';

  @override
  String areaLabel(String area, String ward) {
    return '$area, $ward';
  }

  @override
  String get areaPickerTitle => 'Collection area';

  @override
  String get areaPickerWard => 'Choose your ward';

  @override
  String get areaPickerTown => 'Choose your town';

  @override
  String get areaPickerChome => 'Choose your chōme';

  @override
  String get areaPickerNoData =>
      'Area data hasn\'t downloaded yet. Check your connection, then try again.';

  @override
  String get areaPickerHint => 'Pick the town where you put out your rubbish.';

  @override
  String get remindersTitle => 'Collection reminders';

  @override
  String get remindersSubtitle => 'Get a reminder before collection time.';

  @override
  String get remindersSwitch => 'Remind me';

  @override
  String get remindersNeedArea => 'Choose your collection area first.';

  @override
  String get remindersCategories => 'Rubbish types to remind';

  @override
  String get remindersCategoriesHint =>
      'Choose which types you want reminders for.';

  @override
  String get remindersTimes => 'Reminder times';

  @override
  String get remindersEvening => 'Evening before';

  @override
  String get remindersEveningHint => 'The day before collection';

  @override
  String get remindersMorning => 'Morning of';

  @override
  String get remindersMorningHint => 'On the collection day';

  @override
  String remindersMorningLate(String time) {
    return 'Rubbish has to be out by $time. A reminder after that is too late.';
  }

  @override
  String get remindersDenied =>
      'Notifications are off for BinPal. Turn them on in your phone\'s settings to get reminders.';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders scheduled',
      one: '1 reminder scheduled',
      zero: 'No reminders in the next few weeks',
    );
    return '$_temp0';
  }

  @override
  String remindersSummaryEvening(String time) {
    return 'Evening before · $time';
  }

  @override
  String remindersSummaryMorning(String time) {
    return 'Morning of · $time';
  }

  @override
  String get reminderChannel => 'Collection reminders';

  @override
  String reminderEveningTitle(String categories) {
    return 'Tomorrow: $categories';
  }

  @override
  String reminderMorningTitle(String categories) {
    return 'Today: $categories';
  }

  @override
  String reminderEveningBody(String time) {
    return 'Put it out by $time tomorrow morning.';
  }

  @override
  String reminderMorningBody(String time) {
    return 'Put it out by $time.';
  }

  @override
  String get reminderBodyNoTime => 'Check the time at your collection point.';

  @override
  String get reminderListSeparator => ', ';

  @override
  String todayPutOutBy(String time) {
    return 'Put out by $time';
  }

  @override
  String todayAlso(String categories) {
    return 'Also: $categories';
  }

  @override
  String get todayNoCollection => 'No collection today';

  @override
  String get todayNoCollectionBody =>
      'There is no rubbish collection in your area today.';

  @override
  String todayTomorrow(String date) {
    return 'Tomorrow · $date';
  }

  @override
  String get todayNoCollectionTomorrow => 'No collection tomorrow';

  @override
  String get todaySearchHint => 'How do I sort this item?';

  @override
  String get todayReminders => 'Reminders';

  @override
  String get todayViewCalendar => 'View calendar';

  @override
  String get todayStaleTitle => 'Schedule may be out of date';

  @override
  String todayStaleBody(String date) {
    return 'BinPal hasn\'t been able to check for updates since $date. Collection days can change for holidays or ward updates.';
  }

  @override
  String get todayStaleLink => 'Check ward information';

  @override
  String todayChecked(String date, String source) {
    return 'Checked $date · $source';
  }

  @override
  String get todayOffline => 'Available offline';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String calendarDetails(String date) {
    return 'Collection details: $date';
  }

  @override
  String get calendarNone => 'No collection';

  @override
  String calendarArea(String area) {
    return 'Area: $area';
  }

  @override
  String calendarSource(String source) {
    return 'Source: $source';
  }

  @override
  String get calendarPrevious => 'Previous month';

  @override
  String get calendarNext => 'Next month';

  @override
  String get setupTitle => 'Set your collection area';

  @override
  String get setupBody =>
      'Choose your area to see the right collection days and sorting rules.';

  @override
  String get setupUseLocation => 'Use my location';

  @override
  String get setupChooseManually => 'Choose manually';

  @override
  String get setupPrivacyTitle => 'Your privacy is protected';

  @override
  String get setupPrivacyBody =>
      'Your location is used once, on this phone, to find your collection area. It is not saved or sent anywhere.';

  @override
  String get setupLocating => 'Finding your area…';

  @override
  String get setupDownloadingMap =>
      'Downloading the area map (under 1 MB, only the first time)…';

  @override
  String get setupDenied =>
      'Location access wasn\'t allowed. You can choose your area from the list instead.';

  @override
  String get setupDeniedForever =>
      'Location access is off for BinPal. Turn it on in Settings, or choose your area from the list.';

  @override
  String get setupServiceOff =>
      'Location services are off on this phone. Turn them on, or choose your area from the list.';

  @override
  String get setupUnavailable =>
      'Couldn\'t get your location. Try again near a window or outside, or choose your area from the list.';

  @override
  String get setupMapFailed =>
      'Couldn\'t download the area map. Check your connection and try again, or choose your area from the list.';

  @override
  String get setupDataFailed =>
      'Your area\'s data hasn\'t downloaded yet. Check your connection and try again.';

  @override
  String setupNotCovered(String place) {
    return 'BinPal doesn\'t have collection days for $place yet.';
  }

  @override
  String get setupOutside => 'BinPal doesn\'t cover where you are yet.';

  @override
  String get setupOpenSettings => 'Open Settings';

  @override
  String get setupTryAgain => 'Try again';

  @override
  String get confirmTitle => 'Confirm area';

  @override
  String get confirmHeading => 'Is this your area?';

  @override
  String confirmBody(String area) {
    return 'Looks like you\'re in $area. Is this where you put out your rubbish?';
  }

  @override
  String confirmWardCity(String ward, String city) {
    return '$ward, $city';
  }

  @override
  String get confirmNearby => 'Also near you';

  @override
  String get confirmNearbyHint =>
      'You\'re close to a boundary, so check which side you\'re on.';

  @override
  String get confirmButton => 'Confirm area';

  @override
  String get confirmOther => 'Choose another area';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languagePhone => 'Same as phone';

  @override
  String languagePhoneSummary(String language) {
    return 'Same as phone ($language)';
  }

  @override
  String get languageName => 'English';

  @override
  String get searchPhotoCheckTitle => 'Photo check';

  @override
  String get searchPhotoCheckBody =>
      'Take a photo to find an item\'s rubbish category.';

  @override
  String get photoTitle => 'Photo check';

  @override
  String get photoSubtitle =>
      'Take a photo of the item to check how to sort it.';

  @override
  String get photoGalleryHint =>
      'You can also choose a photo from your device.';

  @override
  String get photoCancel => 'Cancel';

  @override
  String get photoTake => 'Take photo';

  @override
  String get photoGallery => 'Choose a photo';

  @override
  String get photoRetake => 'Retake';

  @override
  String get photoUse => 'Use this photo';

  @override
  String get photoPrivacy =>
      'The photo is checked on your phone first. Only if it\'s unsure is it sent to BinPal\'s server to identify, and it isn\'t kept.';

  @override
  String get photoCameraDenied =>
      'Camera access is off. Turn it on for BinPal in Settings, or choose a photo instead.';

  @override
  String get photoCameraUnavailable =>
      'The camera isn\'t available. You can choose a photo instead.';

  @override
  String get photoChecking => 'Checking the photo…';

  @override
  String get photoCheckFailed => 'Couldn\'t read this photo. Try another one.';

  @override
  String get photoResultTitle => 'Match result';

  @override
  String get photoLikelyMatch => 'Likely match';

  @override
  String get photoFromMark => 'From the recycling mark';

  @override
  String get photoRemembered => 'You chose this before';

  @override
  String get photoAiMatch => 'AI suggestion';

  @override
  String get photoGuidance => 'How to put it out';

  @override
  String get photoViewRule => 'View sorting rule';

  @override
  String get photoNotRight => 'Not right? Choose another item';

  @override
  String get photoWhichTitle => 'Which item is this?';

  @override
  String get photoWhichBody =>
      'We\'re not very sure from the photo. Please choose the item that best matches.';

  @override
  String get photoWhichInCategory => 'Which item is it?';

  @override
  String get photoAsking => 'Asking AI…';

  @override
  String get photoAiOffline =>
      'You\'re offline, so AI can\'t check this photo. Choose below or search by name.';

  @override
  String get photoAiPaused =>
      'AI checks are paused for today. Choose below or search by name.';

  @override
  String get photoAiFailed =>
      'AI couldn\'t check this photo right now. Choose below or search by name.';

  @override
  String get photoAiNoAnswer =>
      'AI couldn\'t tell either. Choose below or search by name.';

  @override
  String get photoNothingTitle => 'Couldn\'t recognise this item';

  @override
  String get photoNothingBody =>
      'Try another photo, closer and in good light, or search by name.';

  @override
  String get photoSearchByName => 'Search by name';

  @override
  String get photoTryAgain => 'Take another photo';

  @override
  String photoCategoryOnly(String category) {
    return 'This goes in $category.';
  }

  @override
  String get photoModelsMissing =>
      'Photo check is still getting ready on this phone. Try again in a minute, or search by name.';

  @override
  String get reportLink => 'This looks wrong';

  @override
  String get reportTitle => 'This looks wrong';

  @override
  String get reportSubtitle =>
      'Report a problem with the collection day, category or rules.';

  @override
  String get reportClose => 'Close';

  @override
  String get reportArea => 'Area';

  @override
  String get reportItem => 'Item';

  @override
  String get reportDate => 'Collection date';

  @override
  String get reportWhatsWrong => 'What\'s wrong?';

  @override
  String get reportKindCategory => 'Category';

  @override
  String get reportKindInstructions => 'How to put it out';

  @override
  String get reportKindOther => 'Something else';

  @override
  String get reportComment => 'Comment (optional)';

  @override
  String get reportCommentHint => 'e.g. The category seems incorrect.';

  @override
  String get reportMissingLabel => 'What were you looking for?';

  @override
  String get reportMissingHint => 'e.g. Clothes hanger';

  @override
  String get reportPublic =>
      'Reports are checked in BinPal\'s public review queue, where comments are shown. Please don\'t include personal details.';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent =>
      'Thanks. We\'ll check it against the city\'s information.';

  @override
  String get reportOffline => 'You\'re offline. Connect and try again.';

  @override
  String get reportLimited =>
      'You\'ve sent a lot of reports today. Please try again tomorrow.';

  @override
  String get reportFailed => 'Couldn\'t send the report. Please try again.';

  @override
  String get searchReportMissing => 'Can\'t find it? Tell us';

  @override
  String get searchReportFooter => 'Something wrong or missing? Tell us';

  @override
  String get bulkyTitle => 'Bulky item guide';

  @override
  String get bulkySearchTitle => 'Bulky item guide';

  @override
  String get bulkySearchBody =>
      'How to put out large items, such as furniture and bedding.';

  @override
  String get bulkyPhone => 'Phone';

  @override
  String bulkyCall(String number) {
    return 'Call $number';
  }

  @override
  String get bulkyOtherLinks => 'More from the city';

  @override
  String get bulkyNoBooking =>
      'BinPal doesn\'t book for you: booking and payment happen on the city\'s own pages.';

  @override
  String bulkyChecked(String date) {
    return 'Checked against the official pages on $date';
  }

  @override
  String get bulkyNone =>
      'There\'s no bulky item guide for your area yet. Check your city\'s website.';

  @override
  String get itemBulkyGuide => 'How to put out bulky items';
}
