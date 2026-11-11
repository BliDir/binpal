import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/top_bar.dart';
import '../../l10n/app_localizations.dart';

/// Offline item search. The search field is in place; results arrive with the
/// local database and search index.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.searchExamples, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.searchNoAreaBody,
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
