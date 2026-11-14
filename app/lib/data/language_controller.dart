import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'database.dart';

const languageSettingKey = 'language';

/// The interface language: the phone's, or one chosen in settings.
class LanguageController extends ChangeNotifier {
  LanguageController({required this.db});

  final AppDatabase db;

  /// The language chosen in settings, or null to follow the phone.
  Locale? chosen;

  /// What the app is shown in: [chosen], or the phone's language when the
  /// app has it, otherwise English. Reminders, which are written outside any
  /// screen, use this too.
  Locale get current => chosen ?? phone;

  /// The supported language the phone's preferences pick, the same way the
  /// app does when following the phone.
  Locale get phone => basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  );

  Future<void> load() async {
    final code = await db.setting(languageSettingKey);
    final found = AppLocalizations.supportedLocales
        .where((l) => l.languageCode == code)
        .firstOrNull;
    if (found != chosen) {
      chosen = found;
      notifyListeners();
    }
  }

  /// Shows the app in [language], or follows the phone when it is null.
  Future<void> choose(Locale? language) async {
    await db.setSetting(languageSettingKey, language?.languageCode ?? 'phone');
    chosen = language;
    notifyListeners();
  }
}
