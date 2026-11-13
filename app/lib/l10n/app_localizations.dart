import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BinPal'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @areaNotSet.
  ///
  /// In en, this message translates to:
  /// **'Set your area'**
  String get areaNotSet;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @todayNoAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'No area yet'**
  String get todayNoAreaTitle;

  /// No description provided for @todayNoAreaBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your area to see which garbage goes out today and tomorrow.'**
  String get todayNoAreaBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'How do I sort this item?'**
  String get searchHint;

  /// No description provided for @searchNoAreaBody.
  ///
  /// In en, this message translates to:
  /// **'Item search works offline once your area\'s data is downloaded.'**
  String get searchNoAreaBody;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find how to sort and put out an item.'**
  String get searchSubtitle;

  /// No description provided for @searchExamplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search examples'**
  String get searchExamplesTitle;

  /// No description provided for @searchOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get searchOfflineTitle;

  /// No description provided for @searchOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Search and sorting rules work without internet once your area\'s data is downloaded.'**
  String get searchOfflineBody;

  /// No description provided for @searchDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading your area\'s data…'**
  String get searchDownloading;

  /// No description provided for @searchDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download your area\'s data. Check your connection and try again.'**
  String get searchDownloadFailed;

  /// No description provided for @searchRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get searchRetry;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result for “{query}”} other{{count} results for “{query}”}}'**
  String searchResultCount(int count, String query);

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchNoResults(String query);

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try another word, in English or Japanese, or a more general one: “bag” rather than “handbag”.'**
  String get searchNoResultsBody;

  /// No description provided for @itemHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to put it out'**
  String get itemHowTo;

  /// No description provided for @itemInJapanese.
  ///
  /// In en, this message translates to:
  /// **'In Japanese'**
  String get itemInJapanese;

  /// No description provided for @itemTranslationNote.
  ///
  /// In en, this message translates to:
  /// **'The English is BinPal\'s translation. The Japanese is the city\'s own.'**
  String get itemTranslationNote;

  /// No description provided for @itemAboutCategory.
  ///
  /// In en, this message translates to:
  /// **'About {category}'**
  String itemAboutCategory(String category);

  /// No description provided for @itemSource.
  ///
  /// In en, this message translates to:
  /// **'Official source'**
  String get itemSource;

  /// No description provided for @itemSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} website'**
  String itemSourceSubtitle(String name);

  /// No description provided for @itemVerified.
  ///
  /// In en, this message translates to:
  /// **'Checked against the source'**
  String get itemVerified;

  /// No description provided for @itemOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get itemOpenFailed;

  /// No description provided for @settingsArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get settingsArea;

  /// No description provided for @settingsAreaNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsAreaNotSet;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsRemindersOff;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Area data'**
  String get settingsData;

  /// No description provided for @settingsDataVersion.
  ///
  /// In en, this message translates to:
  /// **'{name} · version {version}'**
  String settingsDataVersion(String name, int version);

  /// No description provided for @settingsDataNone.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded yet'**
  String get settingsDataNone;

  /// No description provided for @settingsDataDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get settingsDataDownloading;

  /// No description provided for @settingsDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download. Tap to try again.'**
  String get settingsDataFailed;

  /// No description provided for @settingsDataStale.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Using the saved data.'**
  String get settingsDataStale;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About BinPal'**
  String get settingsAbout;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Garbage sorting and collection days in Japan, in plain English.'**
  String get aboutTagline;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicenses;

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'BinPal logo'**
  String get logoLabel;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'{area}, {ward}'**
  String areaLabel(String area, String ward);

  /// No description provided for @areaPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection area'**
  String get areaPickerTitle;

  /// No description provided for @areaPickerWard.
  ///
  /// In en, this message translates to:
  /// **'Choose your ward'**
  String get areaPickerWard;

  /// No description provided for @areaPickerTown.
  ///
  /// In en, this message translates to:
  /// **'Choose your town'**
  String get areaPickerTown;

  /// No description provided for @areaPickerChome.
  ///
  /// In en, this message translates to:
  /// **'Choose your chōme'**
  String get areaPickerChome;

  /// No description provided for @areaPickerNoData.
  ///
  /// In en, this message translates to:
  /// **'Area data hasn\'t downloaded yet. Check your connection, then try again.'**
  String get areaPickerNoData;

  /// No description provided for @areaPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the town where you put out your rubbish.'**
  String get areaPickerHint;

  /// No description provided for @todayAreaBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s and tomorrow\'s collections for your area will show here.'**
  String get todayAreaBody;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection reminders'**
  String get remindersTitle;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder before collection time.'**
  String get remindersSubtitle;

  /// No description provided for @remindersSwitch.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindersSwitch;

  /// No description provided for @remindersNeedArea.
  ///
  /// In en, this message translates to:
  /// **'Choose your collection area first.'**
  String get remindersNeedArea;

  /// No description provided for @remindersCategories.
  ///
  /// In en, this message translates to:
  /// **'Rubbish types to remind'**
  String get remindersCategories;

  /// No description provided for @remindersCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which types you want reminders for.'**
  String get remindersCategoriesHint;

  /// No description provided for @remindersTimes.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get remindersTimes;

  /// No description provided for @remindersEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening before'**
  String get remindersEvening;

  /// No description provided for @remindersEveningHint.
  ///
  /// In en, this message translates to:
  /// **'The day before collection'**
  String get remindersEveningHint;

  /// No description provided for @remindersMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning of'**
  String get remindersMorning;

  /// No description provided for @remindersMorningHint.
  ///
  /// In en, this message translates to:
  /// **'On the collection day'**
  String get remindersMorningHint;

  /// No description provided for @remindersMorningLate.
  ///
  /// In en, this message translates to:
  /// **'Rubbish has to be out by {time}. A reminder after that is too late.'**
  String remindersMorningLate(String time);

  /// No description provided for @remindersDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for BinPal. Turn them on in your phone\'s settings to get reminders.'**
  String get remindersDenied;

  /// No description provided for @remindersScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reminders in the next few weeks} =1{1 reminder scheduled} other{{count} reminders scheduled}}'**
  String remindersScheduled(int count);

  /// No description provided for @remindersSummaryEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening before · {time}'**
  String remindersSummaryEvening(String time);

  /// No description provided for @remindersSummaryMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning of · {time}'**
  String remindersSummaryMorning(String time);

  /// No description provided for @reminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Collection reminders'**
  String get reminderChannel;

  /// No description provided for @reminderEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {categories}'**
  String reminderEveningTitle(String categories);

  /// No description provided for @reminderMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Today: {categories}'**
  String reminderMorningTitle(String categories);

  /// No description provided for @reminderEveningBody.
  ///
  /// In en, this message translates to:
  /// **'Put it out by {time} tomorrow morning.'**
  String reminderEveningBody(String time);

  /// No description provided for @reminderMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Put it out by {time}.'**
  String reminderMorningBody(String time);

  /// No description provided for @reminderBodyNoTime.
  ///
  /// In en, this message translates to:
  /// **'Check the time at your collection point.'**
  String get reminderBodyNoTime;

  /// No description provided for @reminderListSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get reminderListSeparator;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
