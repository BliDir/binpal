import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../app/services.dart';
import '../../app/top_bar.dart';
import '../../l10n/app_localizations.dart';
import '../area/area_label.dart';

/// Today's and tomorrow's collections. Shows an empty state until area setup
/// and the calendar engine land.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMMEEEEd(locale).format(DateTime.now());
    final areas = AppServices.of(context).area;

    return Scaffold(
      appBar: const TopBar(),
      body: ListenableBuilder(
        listenable: areas,
        builder: (context, _) {
          final area = areas.area;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.todayTitle,
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(date, style: text.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              Card(
                color: AppColors.peach,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area == null
                                  ? l10n.todayNoAreaTitle
                                  : areaLabel(context, area, areas.ward),
                              style: text.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              area == null
                                  ? l10n.todayNoAreaBody
                                  : l10n.todayAreaBody,
                              style: text.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
