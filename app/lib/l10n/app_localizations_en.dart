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
}
