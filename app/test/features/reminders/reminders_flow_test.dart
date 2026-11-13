import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/reminders/reminder_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notifications.dart';
import '../../support/services.dart';

void main() {
  late AppDatabase db;
  late FakeReminderNotifications notifications;
  late AppServices services;
  final now = JapanDate(2026, 11, 16).atJapanTime(10, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notifications = FakeReminderNotifications();
    services = testServices(
      db: db,
      notifications: notifications,
      now: () => now,
    );
  });
  tearDown(() => db.close());

  Future<void> withBundle(WidgetTester tester) => tester.runAsync(() async {
    final file = File('../data/schema/examples/bundles/14100/1.json');
    await db.importBundle(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      sha256: 'x',
    );
    services.sync.bundle = await db.bundleFor('14100');
  });

  /// Lets database work started by a tap finish, then settles the UI.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(BinPalApp(services: services));
    await settle(tester);
    await tester.tap(find.byTooltip('Settings').first);
    await settle(tester);
  }

  testWidgets('choose an area: ward, town, chōme', (tester) async {
    await withBundle(tester);
    await openSettings(tester);
    expect(find.text('Not set'), findsOneWidget);

    await tester.tap(find.text('Area'));
    await settle(tester);
    // The example has two wards.
    expect(find.text('Choose your ward'), findsOneWidget);
    await tester.tap(find.text('Aoba Ward'));
    await settle(tester);
    expect(find.text('Choose your town'), findsOneWidget);
    expect(find.text('Aobadai'), findsOneWidget);
    expect(find.text('Azamino'), findsOneWidget);
    await tester.tap(find.text('Aobadai'));
    await settle(tester);
    expect(find.text('Choose your chōme'), findsOneWidget);

    // Back goes up a step, not out of the picker.
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Choose your town'), findsOneWidget);
    await tester.tap(find.text('Aobadai'));
    await settle(tester);

    await tester.tap(find.text('Aobadai 2-chome'));
    await settle(tester);
    expect(find.text('Aobadai 2-chome, Aoba Ward'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('area_id')), '14117-001002');
  });

  testWidgets('a town without chōme is chosen in one tap', (tester) async {
    await withBundle(tester);
    await openSettings(tester);
    await tester.tap(find.text('Area'));
    await settle(tester);
    await tester.tap(find.text('Naka Ward'));
    await settle(tester);
    await tester.tap(find.text('Yamashitacho'));
    await settle(tester);
    expect(find.text('Yamashitacho, Naka Ward'), findsOneWidget);
  });

  testWidgets('reminders ask for an area first', (tester) async {
    await withBundle(tester);
    await openSettings(tester);
    await tester.tap(find.text('Reminders'));
    await settle(tester);
    expect(find.text('Choose your collection area first.'), findsOneWidget);
  });

  testWidgets('turning reminders on asks permission and schedules them', (
    tester,
  ) async {
    await withBundle(tester);
    await tester.runAsync(() async {
      await db.setSetting('area_id', '14117-001001');
      await services.area.load();
    });
    await openSettings(tester);
    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.text('Reminders'));
    await settle(tester);

    await tester.tap(find.text('Remind me'));
    await settle(tester);
    expect(notifications.permissionRequests, 1);
    // Every category the area collects starts ticked.
    expect(find.text('Burnable / 燃やすごみ'), findsOneWidget);
    expect(find.text('Plastic resources / プラスチック資源'), findsOneWidget);
    final checked = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .where((c) => c.value!)
        .length;
    expect(checked, 7);
    expect(notifications.pending, isNotEmpty);
    expect(notifications.pending.length, lessThanOrEqualTo(64));
    expect(find.textContaining('reminders scheduled'), findsOneWidget);

    // Untick everything but plastic: only Wednesdays remain.
    for (final label in [
      'Burnable / 燃やすごみ',
      'Non-burnable / 燃えないごみ',
      'Spray cans / スプレー缶',
      'Batteries / 電池類',
      'Cans, bottles and PET bottles / 缶・びん・ペットボトル',
      'Small metal items / 小さな金属類',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await settle(tester);
    }
    expect(notifications.pending, isNotEmpty);
    expect(
      notifications.pending.values.every(
        (n) => n.title.contains('Plastic resources'),
      ),
      isTrue,
    );

    await tester.pageBack();
    await settle(tester);
    expect(find.textContaining('Evening before'), findsOneWidget);
    expect(find.textContaining('Morning of'), findsOneWidget);
  });

  testWidgets('denied permission leaves reminders off and says why', (
    tester,
  ) async {
    notifications.permission = false;
    await withBundle(tester);
    await tester.runAsync(() async {
      await db.setSetting('area_id', '14117-001001');
      await services.area.load();
    });
    await openSettings(tester);
    await tester.tap(find.text('Reminders'));
    await settle(tester);
    await tester.tap(find.text('Remind me'));
    await settle(tester);

    expect(
      find.textContaining('Notifications are off for BinPal'),
      findsOneWidget,
    );
    final prefs = await tester.runAsync(() => ReminderPreferences.load(db));
    expect(prefs!.enabled, isFalse);
    expect(notifications.pending, isEmpty);
  });

  testWidgets('a morning reminder after the put-out time is flagged', (
    tester,
  ) async {
    await withBundle(tester);
    await tester.runAsync(() async {
      await db.setSetting('area_id', '14117-001001');
      await services.area.load();
      await const ReminderPreferences(
        enabled: true,
        categories: {'moyasu'},
        morningTime: ReminderTime(8, 30),
      ).save(db);
    });
    await openSettings(tester);
    await tester.tap(find.text('Reminders'));
    await settle(tester);
    // The warning is below the fold of the test screen.
    await tester.scrollUntilVisible(
      find.textContaining('A reminder after that is too late'),
      200,
    );
    expect(
      find.textContaining('A reminder after that is too late'),
      findsOneWidget,
    );
  });
}
