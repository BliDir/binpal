import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/reminders/reminder_preferences.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notifications.dart';

Map<String, dynamic> example() => jsonDecode(
  File('../data/schema/examples/bundles/14100/1.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late FakeReminderNotifications notifications;
  late ReminderService service;
  var locale = const Locale('en');
  // Monday 16 November 2026, 10:00 in Japan.
  final now = JapanDate(2026, 11, 16).atJapanTime(10, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    notifications = FakeReminderNotifications();
    locale = const Locale('en');
    service = ReminderService(
      db: db,
      notifications: notifications,
      now: () => now,
      locale: () => locale,
    );
    await db.importBundle(example(), sha256: 'x');
    await db.setSetting(areaSettingKey, '14117-001001');
    await const ReminderPreferences(
      enabled: true,
      categories: {'moyasu', 'plastic', 'kan-bin-pet'},
    ).save(db);
  });
  tearDown(() => db.close());

  test('schedules worded reminders for the chosen area', () async {
    final count = await service.reschedule();
    expect(count, greaterThan(20));
    expect(notifications.pending, hasLength(count));
    final first = notifications.sorted.first;
    expect(first.id, 202611171);
    expect(first.at, JapanDate(2026, 11, 16).atJapanTime(19, 0));
    expect(first.title, 'Tomorrow: Burnable');
    // intl puts a narrow no-break space before AM.
    expect(first.body, 'Put it out by 8:00\u202fAM tomorrow morning.');
    final morning = notifications.pending[202611172]!;
    expect(morning.title, 'Today: Burnable');
    expect(morning.body, 'Put it out by 8:00\u202fAM.');
    expect(
      notifications.pending[202611201]!.title,
      'Tomorrow: Cans, bottles and PET bottles',
    );
  });

  test('in Japanese', () async {
    locale = const Locale('ja', 'JP');
    await service.reschedule();
    final first = notifications.sorted.first;
    expect(first.title, '明日は燃やすごみの日');
    expect(first.body, '明日の朝8:00までに出してください。');
  });

  test('never more than 64 pending, with every category every time', () async {
    await const ReminderPreferences(
      enabled: true,
      categories: {
        'moyasu',
        'moenai',
        'spray',
        'denchi',
        'plastic',
        'kan-bin-pet',
        'kinzoku',
      },
    ).save(db);
    for (var i = 0; i < 3; i++) {
      await service.reschedule();
    }
    expect(notifications.pending.length, lessThanOrEqualTo(64));
    expect(notifications.peak, lessThanOrEqualTo(64));
  });

  test('changing the area replaces future reminders', () async {
    await service.reschedule();
    // 青葉台一丁目: burnable on Tuesday 17.
    expect(notifications.pending[202611171]!.title, 'Tomorrow: Burnable');

    // あざみ野三丁目: burnable Mon/Fri, plastic Tue, cans Thu.
    await db.setSetting(areaSettingKey, '14117-002003');
    await service.reschedule();
    expect(
      notifications.pending[202611171]!.title,
      'Tomorrow: Plastic resources',
    );
    expect(notifications.pending[202611172]!.title, 'Today: Plastic resources');
    expect(notifications.pending[202611201]!.title, 'Tomorrow: Burnable');
  });

  test('a schedule change in a new bundle reaches future reminders', () async {
    await service.reschedule();
    expect(
      notifications.pending[202611181]!.title,
      'Tomorrow: Plastic resources',
    );

    // Version 2 moves Aobadai's plastic from Wednesday to Thursday.
    final next = example()..['bundle_version'] = 2;
    final plastic = (next['calendars'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((c) => c['id'] == 'aobadai-1-2-plastic');
    plastic['pattern'] = {
      'type': 'weekly',
      'weekdays': ['thu'],
    };
    await db.importBundle(next, sha256: 'y');
    await service.reschedule();

    expect(notifications.pending.containsKey(202611181), isFalse);
    expect(
      notifications.pending[202611191]!.title,
      'Tomorrow: Plastic resources',
    );
  });

  test('turning reminders off, or having no area, cancels them all', () async {
    await service.reschedule();
    await const ReminderPreferences(categories: {'moyasu'}).save(db);
    expect(await service.reschedule(), 0);
    expect(notifications.pending, isEmpty);

    await const ReminderPreferences(
      enabled: true,
      categories: {'moyasu'},
    ).save(db);
    await service.reschedule();
    expect(notifications.pending, isNotEmpty);
    await db.setSetting(areaSettingKey, '14117-999999');
    expect(await service.reschedule(), 0);
    expect(notifications.pending, isEmpty);
  });

  test(
    'overlapping calls run one after the other and end up current',
    () async {
      final first = service.reschedule();
      await db.setSetting(areaSettingKey, '14117-002003');
      final second = service.reschedule();
      await Future.wait([first, second]);
      expect(
        notifications.pending[202611172]!.title,
        'Today: Plastic resources',
      );
    },
  );
}
