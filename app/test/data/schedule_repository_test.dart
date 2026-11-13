import 'dart:convert';
import 'dart:io';

import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/schedule_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('example bundle', () {
    late AppDatabase db;
    late ScheduleRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.importBundle(
        _load('../data/schema/examples/bundles/14100/1.json'),
        sha256: 'x',
      );
      repo = ScheduleRepository(db);
    });
    tearDown(() => db.close());

    test('only the calendars of the asked-for area', () async {
      final s = await repo.forArea('14100', '14117-001001');
      expect(s.calendars.map((c) => c.id), [
        'aobadai-1-2-moyasu',
        'aobadai-1-2-plastic',
        'aobadai-1-2-kan-bin-pet',
      ]);
      // Tuesday 17 November 2026.
      final day = s.on(JapanDate(2026, 11, 17));
      expect(day.collections.map((c) => c.category), [
        'moyasu',
        'moenai',
        'spray',
        'denchi',
      ]);
    });

    test('exceptions for every area and for other areas', () async {
      final aobadai = await repo.forArea('14100', '14117-001001');
      // Saturday 2 January 2027 is in the New Year closure for everyone.
      final closed = aobadai.on(JapanDate(2027, 1, 2));
      expect(closed.isEmpty, isTrue);
      expect(closed.cancelled, contains('moyasu'));
      // The extra collection on 4 January is only for Yamashita.
      expect(aobadai.on(JapanDate(2027, 1, 4)).isEmpty, isTrue);

      final yamashita = await repo.forArea('14100', '14104-002000');
      final extra = yamashita.on(JapanDate(2027, 1, 4));
      final moyasu = extra.collections.firstWhere(
        (c) => c.category == 'moyasu',
      );
      expect(moyasu.extra, isTrue);
      expect(extra.notes.single.noteEn, contains('moved here'));
    });

    test('an area with no calendars has an empty schedule', () async {
      final s = await repo.forArea('14100', '14117-999999');
      expect(s.calendars, isEmpty);
      expect(
        s.days(JapanDate(2026, 11, 13), 60).every((d) => d.isEmpty),
        isTrue,
      );
    });
  });

  test('the next 60 days for an Aoba-ku area, from the full bundle', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.importBundle(
      _load('../data/municipalities/14100/bundle.json'),
      sha256: 'x',
    );
    final repo = ScheduleRepository(db);

    // Warm up once, then measure what app start would do: load and expand.
    await repo.forArea('14100', '14117-100001');
    final watch = Stopwatch()..start();
    final s = await repo.forArea('14100', '14117-100001');
    final days = s.days(JapanDate(2026, 12, 1), 60);
    watch.stop();
    // ignore: avoid_print
    print('60 days for 青葉台一丁目: ${watch.elapsedMicroseconds / 1000} ms');

    // 青葉台1・2丁目: burnable Tue/Sat, plastic Wed, cans Fri, from the city's page.
    final byDate = {for (final day in days) '${day.date}': day};
    List<String> on(String date) => [
      for (final c in byDate[date]!.collections) c.category,
    ];
    expect(on('2026-12-01'), ['moyasu', 'moenai', 'spray', 'denchi']);
    expect(on('2026-12-02'), ['plastic']);
    expect(on('2026-12-04'), ['kan-bin-pet', 'kinzoku']);
    expect(on('2026-12-07'), isEmpty);
    // The New Year closure, 31 December to 3 January.
    expect(on('2026-12-31'), isEmpty);
    expect(on('2027-01-01'), isEmpty);
    expect(on('2027-01-02'), isEmpty);
    expect(on('2027-01-05'), ['moyasu', 'moenai', 'spray', 'denchi']);
    expect(byDate['2026-12-29']!.collections.first.putOutBy, '08:00');
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 200)));
  });
}
