import '../calendar/collection_schedule.dart';
import 'reminder_preferences.dart';

enum ReminderKind { eveningBefore, morningOf }

/// One reminder to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.kind,
    required this.day,
    required this.categories,
  });

  /// Stable for a given date and kind, so rescheduling replaces rather than
  /// duplicates: YYYYMMDD × 10, plus 1 for the evening before, 2 for the
  /// morning of.
  final int id;

  /// When to show it.
  final DateTime at;
  final ReminderKind kind;

  /// The collection day it is about.
  final CollectionDay day;

  /// The chosen categories collected that day, in calendar order.
  final List<Collection> categories;

  /// The earliest put-out time among [categories], `HH:MM`, if known.
  String? get putOutBy {
    final times = [
      for (final c in categories)
        if (c.putOutBy != null) c.putOutBy!,
    ]..sort();
    return times.firstOrNull;
  }

  @override
  String toString() =>
      '$id ${kind.name} ${at.toUtc().toIso8601String()} '
      '${categories.map((c) => c.category).join(',')}';
}

/// iOS keeps at most 64 pending local notifications per app and silently
/// drops the rest. Staying a few under leaves room for anything else.
const maxPendingReminders = 60;

/// How far ahead reminders are planned. The window is topped up every time
/// the app starts or comes back to the foreground.
const reminderHorizonDays = 60;

/// Works out which reminders to schedule from now on: for each collection
/// day in the horizon that includes a chosen category, one the evening
/// before and/or one that morning, as chosen. Nothing in the past, and at
/// most [limit], soonest first.
List<PlannedReminder> planReminders({
  required CollectionSchedule schedule,
  required ReminderPreferences preferences,
  required DateTime now,
  int days = reminderHorizonDays,
  int limit = maxPendingReminders,
}) {
  if (!preferences.active) return const [];
  final today = JapanDate.at(now);
  final planned = <PlannedReminder>[];
  // Start from today: tomorrow's collection can still get tonight's reminder.
  for (final day in schedule.days(today, days + 1)) {
    final chosen = [
      for (final c in day.collections)
        if (preferences.categories.contains(c.category)) c,
    ];
    if (chosen.isEmpty) continue;
    final id = int.parse('${day.date}'.replaceAll('-', '')) * 10;
    if (preferences.evening) {
      final t = preferences.eveningTime;
      planned.add(
        PlannedReminder(
          id: id + 1,
          at: day.date.addDays(-1).atJapanTime(t.hour, t.minute),
          kind: ReminderKind.eveningBefore,
          day: day,
          categories: chosen,
        ),
      );
    }
    if (preferences.morning) {
      final t = preferences.morningTime;
      planned.add(
        PlannedReminder(
          id: id + 2,
          at: day.date.atJapanTime(t.hour, t.minute),
          kind: ReminderKind.morningOf,
          day: day,
          categories: chosen,
        ),
      );
    }
  }
  final future = planned.where((r) => r.at.isAfter(now)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  return future.take(limit).toList();
}
