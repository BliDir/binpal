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
      'Choose your area to see which garbage goes out today and tomorrow.';

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
      'Garbage sorting and collection days in Japan, in plain English.';

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
  String get todayAreaBody =>
      'Today\'s and tomorrow\'s collections for your area will show here.';

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
  String get todayNoData => 'Your area\'s data hasn\'t downloaded yet.';

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
}
