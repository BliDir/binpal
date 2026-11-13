import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/services.dart';

void main() {
  late AppDatabase db;
  late AppServices services;
  // The example bundle's 青葉台一丁目: burnable Tue/Sat (with non-burnable,
  // spray cans, batteries), plastic Wed, cans Fri; closed 31 Dec–3 Jan.
  var now = JapanDate(2026, 11, 17).atJapanTime(10, 0); // Tuesday

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> start(
    WidgetTester tester, {
    String? area = '14117-001001',
    Duration? checkedAgo = const Duration(hours: 1),
  }) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    services = testServices(db: db, now: () => now);
    await tester.runAsync(() async {
      final file = File('../data/schema/examples/bundles/14100/1.json');
      await db.importBundle(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        sha256: 'x',
        importedAt: now.subtract(const Duration(days: 30)),
      );
      services.sync.bundle = await db.bundleFor('14100');
      services.sync.lastChecked = checkedAgo == null
          ? null
          : now.subtract(checkedAgo);
      if (area != null) await db.setSetting(areaSettingKey, area);
      await services.area.load();
    });
    await tester.pumpWidget(BinPalApp(services: services));
    await settle(tester);
  }

  setUp(() => now = JapanDate(2026, 11, 17).atJapanTime(10, 0));

  testWidgets('no area yet: area setup comes first', (tester) async {
    await start(tester, area: null);
    expect(find.text('Set your collection area'), findsOneWidget);
    expect(find.text('No area yet'), findsNothing);
  });

  testWidgets("today's and tomorrow's collections", (tester) async {
    await start(tester);
    expect(find.text('Tuesday, November 17'), findsOneWidget);
    expect(find.text('Burnable'), findsOneWidget);
    expect(find.text('燃やすごみ'), findsOneWidget);
    expect(find.text('Put out by 8:00 AM'), findsNWidgets(2));
    expect(
      find.text('Also: Non-burnable, Spray cans, Batteries'),
      findsOneWidget,
    );
    expect(find.text('Tomorrow · Wed, Nov 18'), findsOneWidget);
    expect(find.text('Plastic resources'), findsOneWidget);
    expect(find.text('Aobadai 1-chome, Aoba Ward'), findsOneWidget);
  });

  testWidgets('a day with no collection', (tester) async {
    now = JapanDate(2026, 11, 16).atJapanTime(10, 0); // Monday
    await start(tester);
    expect(find.text('No collection today'), findsOneWidget);
    expect(
      find.text('There is no rubbish collection in your area today.'),
      findsOneWidget,
    );
    expect(find.text('Burnable'), findsOneWidget); // tomorrow
  });

  testWidgets('the New Year closure says why', (tester) async {
    now = JapanDate(2027, 1, 2).atJapanTime(10, 0); // a Saturday, closed
    await start(tester);
    expect(find.text('No collection today'), findsOneWidget);
    expect(find.text('No collection over the New Year holidays'), findsWidgets);
  });

  testWidgets('freshness line, and no stale notice when recently checked', (
    tester,
  ) async {
    await start(tester);
    await tester.scrollUntilVisible(find.text('Available offline'), 200);
    expect(find.text('Checked Nov 17, 2026 · Aoba Ward'), findsOneWidget);
    expect(find.text('Schedule may be out of date'), findsNothing);
  });

  testWidgets('a soft notice when not checked for over two weeks', (
    tester,
  ) async {
    await start(tester, checkedAgo: const Duration(days: 15));
    await tester.scrollUntilVisible(
      find.text('Schedule may be out of date'),
      200,
    );
    expect(find.textContaining('since Nov 2, 2026'), findsOneWidget);
    expect(find.text('Check ward information'), findsOneWidget);
  });

  testWidgets('never checked: the notice dates from the import', (
    tester,
  ) async {
    await start(tester, checkedAgo: null);
    await tester.scrollUntilVisible(
      find.text('Schedule may be out of date'),
      200,
    );
    expect(find.textContaining('since Oct 18, 2026'), findsOneWidget);
  });

  testWidgets('the search box opens the Search tab', (tester) async {
    await start(tester);
    await tester.tap(find.text('How do I sort this item?').first);
    await settle(tester);
    expect(find.text('Search examples'), findsOneWidget);
  });

  testWidgets('the calendar shows the month and a chosen day', (tester) async {
    // A tall screen, so the whole month and its details fit without scrolling.
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await start(tester);
    await tester.scrollUntilVisible(find.text('View calendar'), 200);
    await tester.ensureVisible(find.text('View calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View calendar'));
    await settle(tester);

    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Collection details: Tue, Nov 17'), findsOneWidget);
    // One legend entry per collection group.
    expect(find.text('Burnable'), findsNWidgets(2));
    expect(find.text('Plastic resources'), findsOneWidget);
    expect(find.text('Cans, bottles and PET bottles'), findsOneWidget);

    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text('Collection details: Wed, Nov 18'), findsOneWidget);
    expect(find.text('Plastic resources'), findsNWidgets(2));

    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    expect(find.text('No collection'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
  });

  testWidgets('in Japanese', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await start(tester);
    expect(find.text('燃やすごみ'), findsOneWidget);
    expect(find.text('Burnable'), findsNothing);
    expect(find.text('同じ日：燃えないごみ・スプレー缶・電池類'), findsOneWidget);
    expect(find.text('青葉区青葉台一丁目'), findsOneWidget);
  });
}
