import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/reminders/reminder_planner.dart';
import 'package:binpal/reminders/reminder_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

JapanDate d(String s) => JapanDate.parse(s);

CalendarEntry weekly(
  String id,
  List<String> categories,
  List<String> days, {
  String from = '2025-04-01',
  String? to,
}) => CalendarEntry(
  id: id,
  categories: categories,
  pattern: CollectionPattern.fromJson({'type': 'weekly', 'weekdays': days}),
  validFrom: d(from),
  validTo: to == null ? null : d(to),
  putOutBy: '08:00',
);

final aobadai = CollectionSchedule(
  calendars: [
    weekly('b', ['moyasu', 'moenai', 'spray', 'denchi'], ['tue', 'sat']),
    weekly('p', ['plastic'], ['wed']),
    weekly('c', ['kan-bin-pet', 'kinzoku'], ['fri']),
  ],
  exceptions: [
    for (final date in ['2026-12-31', '2027-01-01', '2027-01-02', '2027-01-03'])
      ExceptionEntry(date: d(date), type: ExceptionType.noCollection),
  ],
);

const both = ReminderPreferences(
  enabled: true,
  categories: {'moyasu', 'plastic'},
);

/// Japan time as an instant.
DateTime jst(String date, int hour, [int minute = 0]) =>
    d(date).atJapanTime(hour, minute);

String describe(PlannedReminder r) {
  final local = r.at.toUtc().add(const Duration(hours: 9));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${r.kind == ReminderKind.eveningBefore ? 'evening' : 'morning'} '
      '${local.month}/${local.day} ${two(local.hour)}:${two(local.minute)} '
      '${r.categories.map((c) => c.category).join('+')}';
}

void main() {
  test('evening before and morning of, for chosen categories only', () {
    // Monday 16 November 2026, 10:00 in Japan.
    final plan = planReminders(
      schedule: aobadai,
      preferences: both,
      now: jst('2026-11-16', 10),
      days: 6,
    );
    expect(plan.map(describe), [
      'evening 11/16 19:00 moyasu', // for Tue 17
      'morning 11/17 07:00 moyasu',
      'evening 11/17 19:00 plastic', // for Wed 18
      'morning 11/18 07:00 plastic',
      // Fri 20 is cans only, which was not chosen.
      'evening 11/20 19:00 moyasu', // for Sat 21
      'morning 11/21 07:00 moyasu',
    ]);
    expect(plan.first.id, 202611171);
    expect(plan[1].id, 202611172);
    expect(plan.first.putOutBy, '08:00');
  });

  test("nothing in the past: tonight's reminder is gone after 19:00", () {
    final plan = planReminders(
      schedule: aobadai,
      preferences: both,
      now: jst('2026-11-16', 19, 30),
      days: 3,
    );
    expect(plan.first.kind, ReminderKind.morningOf);
    expect(describe(plan.first), 'morning 11/17 07:00 moyasu');
  });

  test('only the chosen times', () {
    final plan = planReminders(
      schedule: aobadai,
      preferences: both.copyWith(
        morning: false,
        eveningTime: const ReminderTime(21, 30),
      ),
      now: jst('2026-11-16', 10),
      days: 3,
    );
    expect(plan.map(describe), [
      'evening 11/16 21:30 moyasu',
      'evening 11/17 21:30 plastic',
    ]);
  });

  test('nothing when off, with no categories, or with no times', () {
    final now = jst('2026-11-16', 10);
    for (final p in [
      const ReminderPreferences(categories: {'moyasu'}),
      const ReminderPreferences(enabled: true),
      both.copyWith(evening: false, morning: false),
    ]) {
      expect(
        planReminders(schedule: aobadai, preferences: p, now: now),
        isEmpty,
      );
    }
  });

  test('no reminders for days the New Year closure cancels', () {
    final plan = planReminders(
      schedule: aobadai,
      preferences: both.copyWith(morning: false),
      now: jst('2026-12-27', 10),
      days: 12,
    );
    expect(plan.map(describe), [
      'evening 12/28 19:00 moyasu', // Tue 29
      'evening 12/29 19:00 plastic', // Wed 30
      // Sat 2 January is closed.
      'evening 1/4 19:00 moyasu', // Tue 5
      'evening 1/5 19:00 plastic', // Wed 6
    ]);
  });

  test('an extra collection gets a reminder', () {
    final schedule = CollectionSchedule(
      calendars: aobadai.calendars,
      exceptions: [
        ExceptionEntry(
          date: d('2026-11-19'),
          type: ExceptionType.extraCollection,
          categories: const {'moyasu'},
        ),
      ],
    );
    final plan = planReminders(
      schedule: schedule,
      preferences: both.copyWith(morning: false),
      now: jst('2026-11-18', 10),
      days: 1,
    );
    expect(plan.map(describe), ['evening 11/18 19:00 moyasu']);
  });

  test('a schedule change in the window moves the reminders with it', () {
    final schedule = CollectionSchedule(
      calendars: [
        weekly('old', ['plastic'], ['wed'], to: '2026-11-22'),
        weekly('new', ['plastic'], ['thu'], from: '2026-11-23'),
      ],
      exceptions: const [],
    );
    final plan = planReminders(
      schedule: schedule,
      preferences: both.copyWith(evening: false),
      now: jst('2026-11-16', 10),
      days: 14,
    );
    expect(plan.map(describe), [
      'morning 11/18 07:00 plastic',
      'morning 11/26 07:00 plastic',
    ]);
  });

  test('never more than the limit, soonest first', () {
    // Something every day, reminded twice a day: 120 in 60 days.
    final daily = CollectionSchedule(
      calendars: [
        weekly(
          'all',
          ['moyasu'],
          ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
        ),
      ],
      exceptions: const [],
    );
    final plan = planReminders(
      schedule: daily,
      preferences: both,
      now: jst('2026-11-16', 10),
    );
    expect(plan, hasLength(maxPendingReminders));
    expect(maxPendingReminders, lessThanOrEqualTo(64));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].at.isAfter(plan[i - 1].at), isTrue);
    }
    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
  });
}
