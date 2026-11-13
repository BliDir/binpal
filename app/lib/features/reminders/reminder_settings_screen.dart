import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../calendar/collection_schedule.dart';
import '../../data/database.dart';
import '../../data/schedule_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../reminders/reminder_preferences.dart';
import '../area/area_picker_screen.dart';
import '../item/category_style.dart';

/// Which rubbish types to be reminded about, and when.
class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  ReminderPreferences? _preferences;

  /// Categories with a collection calendar in the user's area, in calendar
  /// order. Empty when no area is chosen.
  List<WasteCategory> _categories = const [];

  /// The earliest put-out time in the area, `HH:MM`.
  String? _putOutBy;
  bool _denied = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final services = AppServices.of(context);
    final preferences = await ReminderPreferences.load(services.db);
    final area = services.area.area;
    var categories = const <WasteCategory>[];
    String? putOutBy;
    if (area != null) {
      final schedule = await ScheduleRepository(services.db)
          .forArea(area.municipalityId, area.id);
      final all = {
        for (final c in await (services.db.select(
          services.db.categories,
        )..where((c) => c.municipalityId.equals(area.municipalityId))).get())
          c.id: c,
      };
      categories = [for (final id in _calendarCategories(schedule)) ?all[id]];
      final times = [
        for (final c in schedule.calendars)
          if (c.putOutBy != null) c.putOutBy!,
      ]..sort();
      putOutBy = times.firstOrNull;
    }
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _categories = categories;
      _putOutBy = putOutBy;
    });
  }

  static List<String> _calendarCategories(CollectionSchedule schedule) {
    final seen = <String>{};
    return [
      for (final c in schedule.calendars)
        for (final id in c.categories)
          if (seen.add(id)) id,
    ];
  }

  Future<void> _update(ReminderPreferences next) async {
    final services = AppServices.of(context);
    setState(() => _preferences = next);
    await next.save(services.db);
    await services.reminders.reschedule();
    if (mounted) setState(() {});
  }

  Future<void> _setEnabled(bool on) async {
    final services = AppServices.of(context);
    if (on && !await services.reminders.notifications.requestPermission()) {
      setState(() => _denied = true);
      return;
    }
    setState(() => _denied = false);
    var next = _preferences!.copyWith(enabled: on);
    // The first time: everything the area collects.
    if (on && next.categories.isEmpty) {
      next = next.copyWith(categories: {for (final c in _categories) c.id});
    }
    await _update(next);
  }

  Future<void> _pickTime(
    ReminderTime current,
    ValueChanged<ReminderTime> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) onPicked(ReminderTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final services = AppServices.of(context);
    final p = _preferences;

    return Scaffold(
      appBar: AppBar(),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  l10n.remindersTitle,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(l10n.remindersSubtitle, style: text.bodyLarge),
                const SizedBox(height: AppSpacing.md),
                if (services.area.area == null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.place_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(l10n.remindersNeedArea),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AreaPickerScreen(),
                          ),
                        );
                        await _load();
                      },
                    ),
                  )
                else ...[
                  Card(
                    child: SwitchListTile(
                      title: Text(l10n.remindersSwitch),
                      subtitle: p.enabled
                          ? Text(
                              l10n.remindersScheduled(
                                services.reminders.scheduled,
                              ),
                            )
                          : null,
                      value: p.enabled,
                      onChanged: _setEnabled,
                    ),
                  ),
                  if (_denied) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.remindersDenied, style: text.bodyMedium),
                  ],
                  if (p.enabled) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Group(
                      icon: Icons.notifications_outlined,
                      title: l10n.remindersCategories,
                      subtitle: l10n.remindersCategoriesHint,
                      children: [
                        for (final c in _categories)
                          CheckboxListTile(
                            value: p.categories.contains(c.id),
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: Icon(categoryStyle(c).icon),
                            title: Text(categoryLabel(context, c)),
                            onChanged: (on) => _update(
                              p.copyWith(
                                categories: on!
                                    ? {...p.categories, c.id}
                                    : ({...p.categories}..remove(c.id)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Group(
                      icon: Icons.schedule,
                      title: l10n.remindersTimes,
                      children: [
                        _TimeRow(
                          title: l10n.remindersEvening,
                          subtitle: l10n.remindersEveningHint,
                          on: p.evening,
                          time: p.eveningTime,
                          onToggle: (on) => _update(p.copyWith(evening: on)),
                          onTime: () => _pickTime(
                            p.eveningTime,
                            (t) => _update(p.copyWith(eveningTime: t)),
                          ),
                        ),
                        _TimeRow(
                          title: l10n.remindersMorning,
                          subtitle: l10n.remindersMorningHint,
                          on: p.morning,
                          time: p.morningTime,
                          onToggle: (on) => _update(p.copyWith(morning: on)),
                          onTime: () => _pickTime(
                            p.morningTime,
                            (t) => _update(p.copyWith(morningTime: t)),
                          ),
                        ),
                        if (p.morning &&
                            _putOutBy != null &&
                            p.morningTime.minutes >=
                                ReminderTime.parse(_putOutBy!).minutes)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              l10n.remindersMorningLate(
                                _formatTime(
                                  context,
                                  ReminderTime.parse(_putOutBy!),
                                ),
                              ),
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

String _formatTime(BuildContext context, ReminderTime t) =>
    TimeOfDay(hour: t.hour, minute: t.minute).format(context);

class _Group extends StatelessWidget {
  const _Group({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.lavender,
            child: ListTile(
              leading: Icon(icon, color: AppColors.primary),
              title: Text(title),
              subtitle: subtitle == null ? null : Text(subtitle!),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.title,
    required this.subtitle,
    required this.on,
    required this.time,
    required this.onToggle,
    required this.onTime,
  });

  final String title;
  final String subtitle;
  final bool on;
  final ReminderTime time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Switch(value: on, onChanged: onToggle),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ActionChip(
        label: Text(_formatTime(context, time)),
        backgroundColor: AppColors.peach,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        onPressed: on ? onTime : null,
      ),
    );
  }
}
