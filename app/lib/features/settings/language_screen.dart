import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../l10n/app_localizations.dart';

/// Each language's name in that language, so it can be found whatever the
/// app is showing now.
String languageName(Locale locale) =>
    lookupAppLocalizations(locale).languageName;

/// Follow the phone's language, or always show one of the app's languages.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppServices.of(context);
    final language = services.language;

    Widget option(Locale? locale, String title, {String? subtitle}) {
      final selected = language.chosen == locale;
      return ListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        selected: selected,
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: selected ? null : () => services.chooseLanguage(locale),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLanguage)),
      body: ListenableBuilder(
        listenable: language,
        builder: (context, _) => ListView(
          children: [
            option(
              null,
              l10n.languagePhone,
              subtitle: languageName(language.phone),
            ),
            const Divider(),
            for (final locale in AppLocalizations.supportedLocales)
              option(locale, languageName(locale)),
          ],
        ),
      ),
    );
  }
}
