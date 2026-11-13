import 'dart:convert';
import 'dart:io';

import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/today/area_schedule.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compares what Today would show for every Aoba-ku row of the city's
/// collection-day tables with the table itself. The tables are read from the
/// rule monitor's snapshots (`data/snapshots/`), the city's pages as text,
/// so this is independent of the bundle build.
void main() {
  const columns = {
    '燃やすごみ': 'moyasu',
    'プラスチック資源': 'plastic',
    '缶・びん・ペットボトル': 'kan-bin-pet',
  };
  // Monday 16 to Saturday 21 November 2026: an ordinary week.
  final monday = JapanDate(2026, 11, 16);

  late AppDatabase db;
  late List<Area> areas;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    final bundle = File('../data/municipalities/14100/bundle.json');
    await db.importBundle(
      jsonDecode(bundle.readAsStringSync()) as Map<String, dynamic>,
      sha256: 'x',
    );
    areas = await db.select(db.areas).get();
  });
  tearDownAll(() => db.close());

  /// The areas a table row covers: 青葉台1・2丁目, あざみ野南1~4丁目, 恩田町.
  List<Area> areasFor(String label) {
    final match = RegExp(r'^(.+?)(\d+(?:[・~]\d+)*)丁目$').firstMatch(label);
    if (match == null) {
      final town = label == '黒須田町' ? '黒須田' : label; // as the build aliases it
      return [
        for (final a in areas)
          if (a.townJa == town) a,
      ];
    }
    final chome = <int>{};
    for (final part in match[2]!.split('・')) {
      final [first, ...rest] = part.split('~');
      final last = rest.isEmpty ? first : rest.single;
      for (var c = int.parse(first); c <= int.parse(last); c++) {
        chome.add(c);
      }
    }
    return [
      for (final a in areas)
        if (a.townJa == match[1] && chome.contains(a.chome)) a,
    ];
  }

  final rows = <(String, List<String>)>[];
  for (final file in Directory('../data/snapshots').listSync()) {
    if (!file.path.contains('yokohama-aoba-days-') ||
        file.path.endsWith('index.txt')) {
      continue;
    }
    for (final line in File(file.path).readAsLinesSync()) {
      final cells = line.split('|').map((c) => c.trim()).toList();
      if (cells.length == 8 && cells[1] != '町名') {
        rows.add((cells[1], cells.sublist(2)));
      }
    }
  }

  test('the snapshots have every Aoba-ku row', () {
    expect(rows, hasLength(47));
  });

  for (final (label, days) in rows) {
    test('$label matches the city table', () async {
      final matched = areasFor(label);
      expect(matched, isNotEmpty, reason: 'no area for $label');
      for (final area in matched) {
        final data = await AreaSchedule.load(db, area, null);
        for (var i = 0; i < 6; i++) {
          final day = data.schedule.on(monday.addDays(i));
          final shown = {
            for (final (collection, _) in data.collectionsOn(day))
              collection.category,
          };
          final expected = columns[days[i]];
          for (final category in columns.values) {
            expect(
              shown.contains(category),
              category == expected,
              reason: '${area.nameJa} on ${day.date}: table says ${days[i]}',
            );
          }
        }
      }
    });
  }
}
