// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'BinPal';

  @override
  String get tabToday => '今日';

  @override
  String get tabSearch => '検索';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsTooltip => '設定';

  @override
  String get areaNotSet => '地域を設定';

  @override
  String get todayTitle => '今日';

  @override
  String get todayNoAreaTitle => '地域が未設定です';

  @override
  String get todayNoAreaBody => '地域を選ぶと、今日と明日に出せるごみが表示されます。';

  @override
  String get searchHint => 'この品目の分け方は？';

  @override
  String get searchExamples => '例：傘、電池、umbrella';

  @override
  String get searchNoAreaBody => '地域のデータをダウンロードすると、オフラインで品目を検索できます。';

  @override
  String get settingsArea => '地域';

  @override
  String get settingsAreaNotSet => '未設定';

  @override
  String get settingsReminders => 'リマインダー';

  @override
  String get settingsRemindersOff => 'オフ';

  @override
  String get settingsAbout => 'BinPalについて';
}
