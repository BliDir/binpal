import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// Brand logo, a one-line description and the open-source licences.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const logoAsset = 'assets/brand/logo.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.lg),
          // The transparent wordmark is designed for light backgrounds.
          Center(
            child: Image.asset(
              logoAsset,
              height: 56,
              semanticLabel: l10n.logoLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.aboutTagline,
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.aboutLicenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
