import 'dart:async';
import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/schedule_repository.dart';
import '../data/area_controller.dart';
import '../l10n/app_localizations.dart';
import 'reminder_notifications.dart';
import 'reminder_planner.dart';
import 'reminder_preferences.dart';

/// Keeps the scheduled notifications in step with the user's area, the
/// stored bundle and their reminder preferences.
///
/// [reschedule] replaces every pending reminder with a fresh plan for the
/// next weeks. It runs at launch, whenever the app returns to the
/// foreground, after a bundle update, and after the area or preferences
/// change, so the rolling window is topped up and schedule changes reach
/// future reminders.
class ReminderService {
  ReminderService({
    required this.db,
    required this.notifications,
    DateTime Function()? now,
    Locale Function()? locale,
  }) : _now = now ?? DateTime.now,
       _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final AppDatabase db;
  final ReminderNotifications notifications;
  final DateTime Function() _now;
  final Locale Function() _locale;

  Future<int>? _running;
  bool _again = false;

  /// How many reminders the last [reschedule] scheduled.
  int scheduled = 0;

  /// Runs one reschedule at a time. A call that arrives while one is running
  /// makes it run once more afterwards, with whatever changed in between.
  Future<int> reschedule() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final run = _rescheduleUntilSettled();
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  Future<int> _rescheduleUntilSettled() async {
    int count;
    do {
      _again = false;
      count = await _reschedule();
    } while (_again);
    return count;
  }

  Future<int> _reschedule() async {
    final preferences = await ReminderPreferences.load(db);
    final areaId = await db.setting(areaSettingKey);
    final area = areaId == null
        ? null
        : await (db.select(
            db.areas,
          )..where((a) => a.id.equals(areaId))).getSingleOrNull();

    if (!preferences.active || area == null) {
      await notifications.cancelAll();
      return scheduled = 0;
    }

    final schedule = await ScheduleRepository(db)
        .forArea(area.municipalityId, area.id);
    final planned = planReminders(
      schedule: schedule,
      preferences: preferences,
      now: _now(),
    );
    final categories = {
      for (final c in await (db.select(
        db.categories,
      )..where((c) => c.municipalityId.equals(area.municipalityId))).get())
        c.id: c,
    };

    final locale = _supported(_locale());
    // Reminders can be scheduled before any screen has loaded the locale's
    // date formats.
    await initializeDateFormatting(locale.toLanguageTag());
    final l10n = lookupAppLocalizations(locale);
    final ja = locale.languageCode == 'ja';

    await notifications.cancelAll();
    for (final reminder in planned) {
      final names = [
        for (final c in reminder.categories)
          if (categories[c.category] case final category?)
            ja ? category.nameJa : category.nameEn,
      ].join(l10n.reminderListSeparator);
      final time = reminder.putOutBy == null
          ? null
          : _formatTime(reminder.putOutBy!, locale);
      final evening = reminder.kind == ReminderKind.eveningBefore;
      final notes = [
        for (final note in reminder.day.notes)
          ?(ja ? note.noteJa : note.noteEn),
      ];
      await notifications.schedule(
        id: reminder.id,
        at: reminder.at,
        title: evening
            ? l10n.reminderEveningTitle(names)
            : l10n.reminderMorningTitle(names),
        body: [
          if (time == null)
            l10n.reminderBodyNoTime
          else if (evening)
            l10n.reminderEveningBody(time)
          else
            l10n.reminderMorningBody(time),
          ...notes,
        ].join(ja ? '' : ' '),
        channelName: l10n.reminderChannel,
      );
    }
    return scheduled = planned.length;
  }
}

Locale _supported(Locale locale) =>
    locale.languageCode == 'ja' ? const Locale('ja') : const Locale('en');

/// `08:00` as the locale shows times: 8:00 AM in English, 8:00 in Japanese.
String _formatTime(String hhmm, Locale locale) {
  final parts = hhmm.split(':');
  final time = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat.jm(locale.toLanguageTag()).format(time);
}
