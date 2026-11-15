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
  /// **'Choose your area to see which rubbish goes out today and tomorrow.'**
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
  /// **'Rubbish sorting and collection days in Japan, in plain English.'**
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

  /// No description provided for @todayPutOutBy.
  ///
  /// In en, this message translates to:
  /// **'Put out by {time}'**
  String todayPutOutBy(String time);

  /// No description provided for @todayAlso.
  ///
  /// In en, this message translates to:
  /// **'Also: {categories}'**
  String todayAlso(String categories);

  /// No description provided for @todayNoCollection.
  ///
  /// In en, this message translates to:
  /// **'No collection today'**
  String get todayNoCollection;

  /// No description provided for @todayNoCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'There is no rubbish collection in your area today.'**
  String get todayNoCollectionBody;

  /// No description provided for @todayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow · {date}'**
  String todayTomorrow(String date);

  /// No description provided for @todayNoCollectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'No collection tomorrow'**
  String get todayNoCollectionTomorrow;

  /// No description provided for @todaySearchHint.
  ///
  /// In en, this message translates to:
  /// **'How do I sort this item?'**
  String get todaySearchHint;

  /// No description provided for @todayReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get todayReminders;

  /// No description provided for @todayViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View calendar'**
  String get todayViewCalendar;

  /// No description provided for @todayStaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule may be out of date'**
  String get todayStaleTitle;

  /// No description provided for @todayStaleBody.
  ///
  /// In en, this message translates to:
  /// **'BinPal hasn\'t been able to check for updates since {date}. Collection days can change for holidays or ward updates.'**
  String todayStaleBody(String date);

  /// No description provided for @todayStaleLink.
  ///
  /// In en, this message translates to:
  /// **'Check ward information'**
  String get todayStaleLink;

  /// No description provided for @todayChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked {date} · {source}'**
  String todayChecked(String date, String source);

  /// No description provided for @todayOffline.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get todayOffline;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarDetails.
  ///
  /// In en, this message translates to:
  /// **'Collection details: {date}'**
  String calendarDetails(String date);

  /// No description provided for @calendarNone.
  ///
  /// In en, this message translates to:
  /// **'No collection'**
  String get calendarNone;

  /// No description provided for @calendarArea.
  ///
  /// In en, this message translates to:
  /// **'Area: {area}'**
  String calendarArea(String area);

  /// No description provided for @calendarSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String calendarSource(String source);

  /// No description provided for @calendarPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPrevious;

  /// No description provided for @calendarNext.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNext;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your collection area'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your area to see the right collection days and sorting rules.'**
  String get setupBody;

  /// No description provided for @setupUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get setupUseLocation;

  /// No description provided for @setupChooseManually.
  ///
  /// In en, this message translates to:
  /// **'Choose manually'**
  String get setupChooseManually;

  /// No description provided for @setupPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is protected'**
  String get setupPrivacyTitle;

  /// No description provided for @setupPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your location is used once, on this phone, to find your collection area. It is not saved or sent anywhere.'**
  String get setupPrivacyBody;

  /// No description provided for @setupLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your area…'**
  String get setupLocating;

  /// No description provided for @setupDownloadingMap.
  ///
  /// In en, this message translates to:
  /// **'Downloading the area map (under 1 MB, only the first time)…'**
  String get setupDownloadingMap;

  /// No description provided for @setupDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access wasn\'t allowed. You can choose your area from the list instead.'**
  String get setupDenied;

  /// No description provided for @setupDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is off for BinPal. Turn it on in Settings, or choose your area from the list.'**
  String get setupDeniedForever;

  /// No description provided for @setupServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off on this phone. Turn them on, or choose your area from the list.'**
  String get setupServiceOff;

  /// No description provided for @setupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again near a window or outside, or choose your area from the list.'**
  String get setupUnavailable;

  /// No description provided for @setupMapFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the area map. Check your connection and try again, or choose your area from the list.'**
  String get setupMapFailed;

  /// No description provided for @setupDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Your area\'s data hasn\'t downloaded yet. Check your connection and try again.'**
  String get setupDataFailed;

  /// No description provided for @setupNotCovered.
  ///
  /// In en, this message translates to:
  /// **'BinPal doesn\'t have collection days for {place} yet.'**
  String setupNotCovered(String place);

  /// No description provided for @setupOutside.
  ///
  /// In en, this message translates to:
  /// **'BinPal doesn\'t cover where you are yet.'**
  String get setupOutside;

  /// No description provided for @setupOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get setupOpenSettings;

  /// No description provided for @setupTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get setupTryAgain;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm area'**
  String get confirmTitle;

  /// No description provided for @confirmHeading.
  ///
  /// In en, this message translates to:
  /// **'Is this your area?'**
  String get confirmHeading;

  /// No description provided for @confirmBody.
  ///
  /// In en, this message translates to:
  /// **'Looks like you\'re in {area}. Is this where you put out your rubbish?'**
  String confirmBody(String area);

  /// No description provided for @confirmWardCity.
  ///
  /// In en, this message translates to:
  /// **'{ward}, {city}'**
  String confirmWardCity(String ward, String city);

  /// No description provided for @confirmNearby.
  ///
  /// In en, this message translates to:
  /// **'Also near you'**
  String get confirmNearby;

  /// No description provided for @confirmNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'You\'re close to a boundary, so check which side you\'re on.'**
  String get confirmNearbyHint;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm area'**
  String get confirmButton;

  /// No description provided for @confirmOther.
  ///
  /// In en, this message translates to:
  /// **'Choose another area'**
  String get confirmOther;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languagePhone.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get languagePhone;

  /// No description provided for @languagePhoneSummary.
  ///
  /// In en, this message translates to:
  /// **'Same as phone ({language})'**
  String languagePhoneSummary(String language);

  /// This language's own name, written in this language. Shown in the language list whatever the interface language is.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @searchPhotoCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo check'**
  String get searchPhotoCheckTitle;

  /// No description provided for @searchPhotoCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo to find an item\'s rubbish category.'**
  String get searchPhotoCheckBody;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo check'**
  String get photoTitle;

  /// No description provided for @photoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the item to check how to sort it.'**
  String get photoSubtitle;

  /// No description provided for @photoGalleryHint.
  ///
  /// In en, this message translates to:
  /// **'You can also choose a photo from your device.'**
  String get photoGalleryHint;

  /// No description provided for @photoCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get photoCancel;

  /// No description provided for @photoTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoTake;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get photoGallery;

  /// No description provided for @photoRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get photoRetake;

  /// No description provided for @photoUse.
  ///
  /// In en, this message translates to:
  /// **'Use this photo'**
  String get photoUse;

  /// No description provided for @photoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The photo is checked on your phone first. Only if it\'s unsure is it sent to BinPal\'s server to identify, and it isn\'t kept.'**
  String get photoPrivacy;

  /// No description provided for @photoCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Turn it on for BinPal in Settings, or choose a photo instead.'**
  String get photoCameraDenied;

  /// No description provided for @photoCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available. You can choose a photo instead.'**
  String get photoCameraUnavailable;

  /// No description provided for @photoChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the photo…'**
  String get photoChecking;

  /// No description provided for @photoCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this photo. Try another one.'**
  String get photoCheckFailed;

  /// No description provided for @photoResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Match result'**
  String get photoResultTitle;

  /// No description provided for @photoLikelyMatch.
  ///
  /// In en, this message translates to:
  /// **'Likely match'**
  String get photoLikelyMatch;

  /// No description provided for @photoFromMark.
  ///
  /// In en, this message translates to:
  /// **'From the recycling mark'**
  String get photoFromMark;

  /// No description provided for @photoRemembered.
  ///
  /// In en, this message translates to:
  /// **'You chose this before'**
  String get photoRemembered;

  /// No description provided for @photoAiMatch.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get photoAiMatch;

  /// No description provided for @photoGuidance.
  ///
  /// In en, this message translates to:
  /// **'How to put it out'**
  String get photoGuidance;

  /// No description provided for @photoViewRule.
  ///
  /// In en, this message translates to:
  /// **'View sorting rule'**
  String get photoViewRule;

  /// No description provided for @photoNotRight.
  ///
  /// In en, this message translates to:
  /// **'Not right? Choose another item'**
  String get photoNotRight;

  /// No description provided for @photoWhichTitle.
  ///
  /// In en, this message translates to:
  /// **'Which item is this?'**
  String get photoWhichTitle;

  /// No description provided for @photoWhichBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re not very sure from the photo. Please choose the item that best matches.'**
  String get photoWhichBody;

  /// No description provided for @photoWhichInCategory.
  ///
  /// In en, this message translates to:
  /// **'Which item is it?'**
  String get photoWhichInCategory;

  /// No description provided for @photoAsking.
  ///
  /// In en, this message translates to:
  /// **'Asking AI…'**
  String get photoAsking;

  /// No description provided for @photoAiOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline, so AI can\'t check this photo. Choose below or search by name.'**
  String get photoAiOffline;

  /// No description provided for @photoAiPaused.
  ///
  /// In en, this message translates to:
  /// **'AI checks are paused for today. Choose below or search by name.'**
  String get photoAiPaused;

  /// No description provided for @photoAiFailed.
  ///
  /// In en, this message translates to:
  /// **'AI couldn\'t check this photo right now. Choose below or search by name.'**
  String get photoAiFailed;

  /// No description provided for @photoAiNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'AI couldn\'t tell either. Choose below or search by name.'**
  String get photoAiNoAnswer;

  /// No description provided for @photoNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t recognise this item'**
  String get photoNothingTitle;

  /// No description provided for @photoNothingBody.
  ///
  /// In en, this message translates to:
  /// **'Try another photo, closer and in good light, or search by name.'**
  String get photoNothingBody;

  /// No description provided for @photoSearchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get photoSearchByName;

  /// No description provided for @photoTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Take another photo'**
  String get photoTryAgain;

  /// No description provided for @photoCategoryOnly.
  ///
  /// In en, this message translates to:
  /// **'This goes in {category}.'**
  String photoCategoryOnly(String category);

  /// No description provided for @photoModelsMissing.
  ///
  /// In en, this message translates to:
  /// **'Photo check is still getting ready on this phone. Try again in a minute, or search by name.'**
  String get photoModelsMissing;

  /// No description provided for @reportLink.
  ///
  /// In en, this message translates to:
  /// **'This looks wrong'**
  String get reportLink;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'This looks wrong'**
  String get reportTitle;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem with the collection day, category or rules.'**
  String get reportSubtitle;

  /// No description provided for @reportClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get reportClose;

  /// No description provided for @reportArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get reportArea;

  /// No description provided for @reportItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get reportItem;

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Collection date'**
  String get reportDate;

  /// No description provided for @reportWhatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get reportWhatsWrong;

  /// No description provided for @reportKindCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportKindCategory;

  /// No description provided for @reportKindInstructions.
  ///
  /// In en, this message translates to:
  /// **'How to put it out'**
  String get reportKindInstructions;

  /// No description provided for @reportKindOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportKindOther;

  /// No description provided for @reportComment.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get reportComment;

  /// No description provided for @reportCommentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The category seems incorrect.'**
  String get reportCommentHint;

  /// No description provided for @reportMissingLabel.
  ///
  /// In en, this message translates to:
  /// **'What were you looking for?'**
  String get reportMissingLabel;

  /// No description provided for @reportMissingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Clothes hanger'**
  String get reportMissingHint;

  /// No description provided for @reportPublic.
  ///
  /// In en, this message translates to:
  /// **'Reports are checked in BinPal\'s public review queue, where comments are shown. Please don\'t include personal details.'**
  String get reportPublic;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We\'ll check it against the city\'s information.'**
  String get reportSent;

  /// No description provided for @reportOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect and try again.'**
  String get reportOffline;

  /// No description provided for @reportLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent a lot of reports today. Please try again tomorrow.'**
  String get reportLimited;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report. Please try again.'**
  String get reportFailed;

  /// No description provided for @searchReportMissing.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Tell us'**
  String get searchReportMissing;

  /// No description provided for @searchReportFooter.
  ///
  /// In en, this message translates to:
  /// **'Something wrong or missing? Tell us'**
  String get searchReportFooter;

  /// No description provided for @bulkyTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulky item guide'**
  String get bulkyTitle;

  /// No description provided for @bulkySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulky item guide'**
  String get bulkySearchTitle;

  /// No description provided for @bulkySearchBody.
  ///
  /// In en, this message translates to:
  /// **'How to put out large items, such as furniture and bedding.'**
  String get bulkySearchBody;

  /// No description provided for @bulkyPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get bulkyPhone;

  /// No description provided for @bulkyCall.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String bulkyCall(String number);

  /// No description provided for @bulkyOtherLinks.
  ///
  /// In en, this message translates to:
  /// **'More from the city'**
  String get bulkyOtherLinks;

  /// No description provided for @bulkyNoBooking.
  ///
  /// In en, this message translates to:
  /// **'BinPal doesn\'t book for you: booking and payment happen on the city\'s own pages.'**
  String get bulkyNoBooking;

  /// No description provided for @bulkyChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked against the official pages on {date}'**
  String bulkyChecked(String date);

  /// No description provided for @bulkyNone.
  ///
  /// In en, this message translates to:
  /// **'There\'s no bulky item guide for your area yet. Check your city\'s website.'**
  String get bulkyNone;

  /// No description provided for @itemBulkyGuide.
  ///
  /// In en, this message translates to:
  /// **'How to put out bulky items'**
  String get itemBulkyGuide;

  /// No description provided for @moveTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you move?'**
  String get moveTitle;

  /// No description provided for @moveBody.
  ///
  /// In en, this message translates to:
  /// **'If you\'ve moved, update your area so BinPal shows the right collection days and rules.'**
  String get moveBody;

  /// No description provided for @moveSaved.
  ///
  /// In en, this message translates to:
  /// **'Currently saved area'**
  String get moveSaved;

  /// No description provided for @moveUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update area'**
  String get moveUpdate;

  /// No description provided for @moveNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get moveNotNow;

  /// No description provided for @movePrivacy.
  ///
  /// In en, this message translates to:
  /// **'BinPal checked on your phone that you seem to be away from this area. Your location isn\'t stored or sent.'**
  String get movePrivacy;

  /// No description provided for @askEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askEntryTitle;

  /// No description provided for @askEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Ask in plain English.'**
  String get askEntryBody;

  /// No description provided for @askTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askTitle;

  /// No description provided for @askSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not sure how to put something out? Ask in plain English.'**
  String get askSubtitle;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Can I throw out a broken umbrella with a metal frame?'**
  String get askHint;

  /// No description provided for @askExamplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Example questions'**
  String get askExamplesTitle;

  /// No description provided for @askExample1.
  ///
  /// In en, this message translates to:
  /// **'Can I throw out a sofa?'**
  String get askExample1;

  /// No description provided for @askExample2.
  ///
  /// In en, this message translates to:
  /// **'How do I dispose of a frying pan?'**
  String get askExample2;

  /// No description provided for @askExample3.
  ///
  /// In en, this message translates to:
  /// **'Is plastic packaging recyclable?'**
  String get askExample3;

  /// No description provided for @askButton.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get askButton;

  /// No description provided for @askNote.
  ///
  /// In en, this message translates to:
  /// **'Answers come only from your area\'s rules, and show the rule they rely on.'**
  String get askNote;

  /// No description provided for @askChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your area\'s rules…'**
  String get askChecking;

  /// No description provided for @answerTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answerTitle;

  /// No description provided for @answerVerdict.
  ///
  /// In en, this message translates to:
  /// **'Put it out as {category}.'**
  String answerVerdict(String category);

  /// No description provided for @answerRule.
  ///
  /// In en, this message translates to:
  /// **'Local disposal rule'**
  String get answerRule;

  /// No description provided for @answerRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Based on these rules'**
  String get answerRulesTitle;

  /// No description provided for @answerHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to put it out'**
  String get answerHowTo;

  /// No description provided for @answerNext.
  ///
  /// In en, this message translates to:
  /// **'Next collection: {date}'**
  String answerNext(String date);

  /// No description provided for @answerNextBy.
  ///
  /// In en, this message translates to:
  /// **'Next collection: {date}, by {time}'**
  String answerNextBy(String date, String time);

  /// No description provided for @answerAiNote.
  ///
  /// In en, this message translates to:
  /// **'The summary is written by AI. The rules above are the city\'s and come first.'**
  String get answerAiNote;

  /// No description provided for @answerNotCovered.
  ///
  /// In en, this message translates to:
  /// **'We can\'t answer this reliably from your area\'s rules.'**
  String get answerNotCovered;

  /// No description provided for @answerNotCoveredBody.
  ///
  /// In en, this message translates to:
  /// **'Please check with the city\'s official contact for your ward.'**
  String get answerNotCoveredBody;

  /// No description provided for @answerOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline, so this question can\'t be checked right now.'**
  String get answerOffline;

  /// No description provided for @answerPaused.
  ///
  /// In en, this message translates to:
  /// **'Questions are paused for today. Please try again tomorrow.'**
  String get answerPaused;

  /// No description provided for @answerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get an answer right now.'**
  String get answerFailed;

  /// No description provided for @answerContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Official contact'**
  String get answerContactTitle;

  /// No description provided for @answerCall.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String answerCall(String number);

  /// No description provided for @answerContactPage.
  ///
  /// In en, this message translates to:
  /// **'Official page'**
  String get answerContactPage;

  /// No description provided for @answerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get answerSearch;

  /// No description provided for @searchAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get searchAskQuestion;
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
