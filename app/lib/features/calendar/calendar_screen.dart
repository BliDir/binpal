import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../calendar/collection_schedule.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../area/area_label.dart';
import '../item/category_style.dart';
import '../today/area_schedule.dart';
import '../today/today_screen.dart';

/// A month of collection days for the user's area, with the chosen day's
/// details below.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.data, this.now});

  final AreaSchedule data;
  final DateTime Function()? now;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final JapanDate _today = JapanDate.at((widget.now ?? DateTime.now)());
  late JapanDate _month = JapanDate(_today.year, _today.month, 1);
  late JapanDate _selected = _today;

  void _shift(int months) => setState(() {
    _month = JapanDate(_month.year, _month.month + months, 1);
    _selected = _month.year == _today.year && _month.month == _today.month
        ? _today
        : _month;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final ja = isJapanese(context);
    final data = widget.data;

    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final days = data.schedule.days(_month, daysInMonth);
    // Sunday first, as Japanese calendars are.
    final leading = _month.weekday % 7;
    // One dot per collection group: 燃やすごみ stands for the 燃えないごみ,
    // スプレー缶 and 電池類 collected with it.
    final legend = <String, WasteCategory>{
      for (final day in days)
        for (final category in _groupLeaders(data, day)) category.id: category,
    };
    final selectedDay = data.schedule.on(_selected);
    final selectedCollections = data.collectionsOn(selectedDay);
    final weekdayNames = DateFormat.E(locale)
        .dateSymbols
        .STANDALONENARROWWEEKDAYS;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.calendarTitle,
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: l10n.calendarPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      DateFormat.yMMMM(locale)
                          .format(DateTime(_month.year, _month.month)),
                      style: text.titleMedium,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.calendarNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      weekdayNames[i],
                      style: text.labelLarge?.copyWith(
                        color: i == 0
                            ? AppColors.primary
                            : i == 6
                            ? const Color(0xFF7A55A8)
                            : AppColors.secondaryInk,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (final day in days)
                _DayCell(
                  day: day,
                  categories: _groupLeaders(data, day),
                  today: day.date == _today,
                  selected: day.date == _selected,
                  onTap: () => setState(() => _selected = day.date),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in legend.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(color: categoryDot(c), size: 10),
                    const SizedBox(width: AppSpacing.xs),
                    Text(ja ? c.nameJa : c.nameEn, style: text.bodySmall),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            color: AppColors.peach.withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calendarDetails(
                      DateFormat.MMMEd(locale).format(
                        DateTime(
                          _selected.year,
                          _selected.month,
                          _selected.day,
                        ),
                      ),
                    ),
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (selectedCollections.isEmpty)
                    Text(l10n.calendarNone, style: text.bodyMedium)
                  else
                    for (final (collection, category) in selectedCollections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _Dot(
                                color: categoryDot(category),
                                size: 10,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ja ? category.nameJa : category.nameEn,
                                    style: text.bodyLarge,
                                  ),
                                  if (!ja)
                                    Text(
                                      category.nameJa,
                                      style: text.bodySmall,
                                    ),
                                  if (collection.putOutBy != null)
                                    Text(
                                      putOutLabel(
                                        context,
                                        collection.putOutBy!,
                                      ),
                                      style: text.labelLarge,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  for (final note in selectedDay.notes)
                    if ((ja ? note.noteJa : note.noteEn) case final n?)
                      Text(n, style: text.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    l10n.calendarArea(areaLabel(context, data.area, data.ward)),
                  ),
                ),
                if (data.sourceUrl != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.open_in_new,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      l10n.calendarSource(
                        data.ward == null
                            ? Uri.parse(data.sourceUrl!).host
                            : (ja ? data.ward!.nameJa : data.ward!.nameEn),
                      ),
                    ),
                    onTap: () => openSource(context, data.sourceUrl!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The first category of each calendar collecting on [day]; an extra
/// collection, which has no calendar, counts as its own group.
List<WasteCategory> _groupLeaders(AreaSchedule data, CollectionDay day) {
  final seen = <String>{};
  return [
    for (final (collection, category) in data.collectionsOn(day))
      if (seen.add(collection.calendarId ?? 'extra:${category.id}')) category,
  ];
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.categories,
    required this.today,
    required this.selected,
    required this.onTap,
  });

  final CollectionDay day;
  final List<WasteCategory> categories;
  final bool today;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dots = [for (final c in categories.take(3)) categoryDot(c)];
    final weekday = day.date.weekday;
    final color = selected
        ? AppColors.onPrimary
        : weekday == DateTime.sunday
        ? AppColors.primary
        : weekday == DateTime.saturday
        ? const Color(0xFF7A55A8)
        : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          side: BorderSide(
            color: today && !selected ? AppColors.primary : AppColors.outline,
            width: today && !selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.date.day}',
                style: text.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: today || selected ? FontWeight.w700 : null,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final dot in dots)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: _Dot(
                          color: selected ? AppColors.onPrimary : dot,
                          size: 7,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
