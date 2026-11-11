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
  String get searchExamples => 'Try umbrella, batteries or 傘';

  @override
  String get searchNoAreaBody =>
      'Item search works offline once your area\'s data is downloaded.';

  @override
  String get settingsArea => 'Area';

  @override
  String get settingsAreaNotSet => 'Not set';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsRemindersOff => 'Off';

  @override
  String get settingsAbout => 'About BinPal';
}
