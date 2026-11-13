import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'category_style.dart';

/// How to put out one item: its category, the city's instructions, where
/// they come from and when they were last checked.
class ItemScreen extends StatelessWidget {
  const ItemScreen({
    super.key,
    required this.rule,
    required this.category,
    required this.municipality,
  });

  final Rule rule;
  final WasteCategory category;
  final StoredBundle? municipality;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final style = categoryStyle(category);
    final verified = DateTime.tryParse(rule.verifiedAt);
    final description = ja ? category.descriptionJa : category.descriptionEn;
    final municipalityName = municipality == null
        ? null
        : (ja ? municipality!.nameJa : municipality!.nameEn);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            color: style.color.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ja ? rule.nameJa : rule.nameEn,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!ja) Text(rule.nameJa, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  CategoryChip(category: category),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            icon: Icons.menu_book_outlined,
            title: l10n.itemHowTo,
            children: [
              Text(
                ja ? rule.instructionsJa : rule.instructionsEn,
                style: text.bodyLarge,
              ),
              if (!ja) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.itemInJapanese, style: text.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(rule.instructionsJa, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.itemTranslationNote, style: text.bodySmall),
              ],
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.md),
            _Section(
              icon: style.icon,
              title: l10n.itemAboutCategory(
                ja ? category.nameJa : category.nameEn,
              ),
              children: [Text(description, style: text.bodyMedium)],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.open_in_new, color: AppColors.primary),
              title: Text(l10n.itemSource),
              subtitle: Text(
                municipalityName == null
                    ? Uri.parse(rule.sourceUrl).host
                    : l10n.itemSourceSubtitle(municipalityName),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, rule.sourceUrl),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.event_available_outlined,
                color: AppColors.primary,
              ),
              title: Text(l10n.itemVerified),
              subtitle: Text(
                verified == null
                    ? rule.verifiedAt
                    : DateFormat.yMMMd(locale).format(verified),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).itemOpenFailed;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((Object _) => false);
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
