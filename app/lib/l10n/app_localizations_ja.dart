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
  String get searchNoAreaBody => '地域のデータをダウンロードすると、オフラインで品目を検索できます。';

  @override
  String get searchTitle => '検索';

  @override
  String get searchSubtitle => '品目の分け方と出し方を調べます。';

  @override
  String get searchExamplesTitle => '検索の例';

  @override
  String get searchOfflineTitle => 'オフラインで使えます';

  @override
  String get searchOfflineBody => '地域のデータをダウンロードすれば、インターネットがなくても検索と分け方を確認できます。';

  @override
  String get searchDownloading => '地域のデータをダウンロード中…';

  @override
  String get searchDownloadFailed =>
      '地域のデータをダウンロードできませんでした。接続を確認して、もう一度お試しください。';

  @override
  String get searchRetry => '再試行';

  @override
  String get searchClear => 'クリア';

  @override
  String searchResultCount(int count, String query) {
    return '「$query」の検索結果 $count件';
  }

  @override
  String searchNoResults(String query) {
    return '「$query」は見つかりませんでした';
  }

  @override
  String get searchNoResultsBody =>
      '別の言葉や、より一般的な言葉（「ハンドバッグ」ではなく「かばん」など）で検索してください。';

  @override
  String get itemHowTo => '出し方';

  @override
  String get itemInJapanese => '日本語';

  @override
  String get itemTranslationNote => '英語は BinPal による翻訳です。日本語は市の原文です。';

  @override
  String itemAboutCategory(String category) {
    return '$categoryについて';
  }

  @override
  String get itemSource => '公式の情報源';

  @override
  String itemSourceSubtitle(String name) {
    return '$nameのウェブサイト';
  }

  @override
  String get itemVerified => '情報源と照合した日';

  @override
  String get itemOpenFailed => 'リンクを開けませんでした。';

  @override
  String get settingsArea => '地域';

  @override
  String get settingsAreaNotSet => '未設定';

  @override
  String get settingsReminders => 'リマインダー';

  @override
  String get settingsRemindersOff => 'オフ';

  @override
  String get settingsData => '地域のデータ';

  @override
  String settingsDataVersion(String name, int version) {
    return '$name・バージョン$version';
  }

  @override
  String get settingsDataNone => '未ダウンロード';

  @override
  String get settingsDataDownloading => 'ダウンロード中…';

  @override
  String get settingsDataFailed => 'ダウンロードできませんでした。タップして再試行。';

  @override
  String get settingsDataStale => '更新を確認できませんでした。保存済みのデータを使用します。';

  @override
  String get settingsAbout => 'BinPalについて';

  @override
  String get aboutTagline => '日本のごみの分け方と収集日を、\nわかりやすく。';

  @override
  String get aboutLicenses => 'オープンソースライセンス';

  @override
  String get logoLabel => 'BinPalのロゴ';

  @override
  String areaLabel(String area, String ward) {
    return '$ward$area';
  }

  @override
  String get areaPickerTitle => '収集地域';

  @override
  String get areaPickerWard => '区を選んでください';

  @override
  String get areaPickerTown => '町名を選んでください';

  @override
  String get areaPickerChome => '丁目を選んでください';

  @override
  String get areaPickerNoData => '地域のデータがまだダウンロードされていません。接続を確認して、もう一度お試しください。';

  @override
  String get areaPickerHint => 'ごみを出す場所の町名を選んでください。';

  @override
  String get todayAreaBody => 'この地域の今日と明日の収集がここに表示されます。';

  @override
  String get remindersTitle => '収集日のお知らせ';

  @override
  String get remindersSubtitle => '収集の前にお知らせします。';

  @override
  String get remindersSwitch => 'お知らせする';

  @override
  String get remindersNeedArea => '先に収集地域を選んでください。';

  @override
  String get remindersCategories => 'お知らせするごみの種類';

  @override
  String get remindersCategoriesHint => 'お知らせを受け取る種類を選んでください。';

  @override
  String get remindersTimes => 'お知らせの時刻';

  @override
  String get remindersEvening => '前日の夜';

  @override
  String get remindersEveningHint => '収集日の前日';

  @override
  String get remindersMorning => '当日の朝';

  @override
  String get remindersMorningHint => '収集日の当日';

  @override
  String remindersMorningLate(String time) {
    return 'ごみは$timeまでに出す必要があります。それより後のお知らせでは間に合いません。';
  }

  @override
  String get remindersDenied =>
      'BinPalの通知がオフになっています。お知らせを受け取るには、端末の設定で通知をオンにしてください。';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のお知らせを予定しています',
      zero: '今後数週間のお知らせはありません',
    );
    return '$_temp0';
  }

  @override
  String remindersSummaryEvening(String time) {
    return '前日の夜・$time';
  }

  @override
  String remindersSummaryMorning(String time) {
    return '当日の朝・$time';
  }

  @override
  String get reminderChannel => '収集日のお知らせ';

  @override
  String reminderEveningTitle(String categories) {
    return '明日は$categoriesの日';
  }

  @override
  String reminderMorningTitle(String categories) {
    return '今日は$categoriesの日';
  }

  @override
  String reminderEveningBody(String time) {
    return '明日の朝$timeまでに出してください。';
  }

  @override
  String reminderMorningBody(String time) {
    return '$timeまでに出してください。';
  }

  @override
  String get reminderBodyNoTime => '出す時刻は集積場所の表示で確認してください。';

  @override
  String get reminderListSeparator => '・';
}
