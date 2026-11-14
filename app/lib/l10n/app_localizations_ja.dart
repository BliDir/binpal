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
  String get searchRetry => 'もう一度試す';

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
  String get settingsReminders => 'お知らせ';

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

  @override
  String todayPutOutBy(String time) {
    return '$timeまでに出す';
  }

  @override
  String todayAlso(String categories) {
    return '同じ日：$categories';
  }

  @override
  String get todayNoCollection => '今日は収集がありません';

  @override
  String get todayNoCollectionBody => '今日はこの地域でごみの収集はありません。';

  @override
  String todayTomorrow(String date) {
    return '明日・$date';
  }

  @override
  String get todayNoCollectionTomorrow => '明日は収集がありません';

  @override
  String get todaySearchHint => 'この品目の分け方は？';

  @override
  String get todayReminders => 'お知らせ';

  @override
  String get todayViewCalendar => 'カレンダーを見る';

  @override
  String get todayStaleTitle => '収集日が古い可能性があります';

  @override
  String todayStaleBody(String date) {
    return '$dateから更新を確認できていません。祝日や区の変更で収集日が変わることがあります。';
  }

  @override
  String get todayStaleLink => '区の情報を確認する';

  @override
  String todayChecked(String date, String source) {
    return '$dateに確認・$source';
  }

  @override
  String get todayOffline => 'オフラインで使えます';

  @override
  String get calendarTitle => 'カレンダー';

  @override
  String calendarDetails(String date) {
    return '$dateの収集';
  }

  @override
  String get calendarNone => '収集なし';

  @override
  String calendarArea(String area) {
    return '地域：$area';
  }

  @override
  String calendarSource(String source) {
    return '情報源：$source';
  }

  @override
  String get calendarPrevious => '前の月';

  @override
  String get calendarNext => '次の月';

  @override
  String get setupTitle => '収集地域を設定';

  @override
  String get setupBody => '地域を選ぶと、その地域の収集日と分け方が表示されます。';

  @override
  String get setupUseLocation => '現在地を使う';

  @override
  String get setupChooseManually => '一覧から選ぶ';

  @override
  String get setupPrivacyTitle => 'プライバシーを守ります';

  @override
  String get setupPrivacyBody => '現在地は収集地域を探すために、この端末内で一度だけ使います。保存や送信はしません。';

  @override
  String get setupLocating => '地域を探しています…';

  @override
  String get setupDownloadingMap => '地域の地図をダウンロードしています（1MB未満、初回のみ）…';

  @override
  String get setupDenied => '位置情報の利用が許可されませんでした。一覧から地域を選べます。';

  @override
  String get setupDeniedForever =>
      'BinPalの位置情報がオフになっています。設定でオンにするか、一覧から地域を選んでください。';

  @override
  String get setupServiceOff => '端末の位置情報サービスがオフです。オンにするか、一覧から地域を選んでください。';

  @override
  String get setupUnavailable =>
      '現在地を取得できませんでした。窓の近くや屋外でもう一度試すか、一覧から地域を選んでください。';

  @override
  String get setupMapFailed =>
      '地域の地図をダウンロードできませんでした。接続を確認してもう一度試すか、一覧から地域を選んでください。';

  @override
  String get setupDataFailed => '地域のデータがまだダウンロードされていません。接続を確認して、もう一度お試しください。';

  @override
  String setupNotCovered(String place) {
    return '$placeの収集日はまだBinPalにありません。';
  }

  @override
  String get setupOutside => '現在地はまだBinPalの対象外です。';

  @override
  String get setupOpenSettings => '設定を開く';

  @override
  String get setupTryAgain => 'もう一度試す';

  @override
  String get confirmTitle => '地域の確認';

  @override
  String get confirmHeading => 'この地域でよろしいですか？';

  @override
  String confirmBody(String area) {
    return '現在地は$areaのようです。ここにごみを出していますか？';
  }

  @override
  String confirmWardCity(String ward, String city) {
    return '$city$ward';
  }

  @override
  String get confirmNearby => '近くの地域';

  @override
  String get confirmNearbyHint => '境界の近くにいるため、どちら側か確認してください。';

  @override
  String get confirmButton => 'この地域にする';

  @override
  String get confirmOther => '別の地域を選ぶ';

  @override
  String get settingsLanguage => '言語 / Language';

  @override
  String get languagePhone => '端末の設定に合わせる';

  @override
  String languagePhoneSummary(String language) {
    return '端末の設定に合わせる（$language）';
  }

  @override
  String get languageName => '日本語';
}
