import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/language_controller.dart';
import 'package:binpal/reminders/reminder_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notifications.dart';
import '../../support/services.dart';

void main() {
  late AppDatabase db;
  late AppServices services;
  late FakeReminderNotifications notifications;
  final now = JapanDate(2026, 11, 16).atJapanTime(10, 0); // Monday

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Launches the app as main.dart does, on the existing [db] when given:
  /// an area chosen, burnable reminders on.
  Future<void> launch(WidgetTester tester, {AppDatabase? existing}) async {
    db = existing ?? AppDatabase(NativeDatabase.memory());
    if (existing == null) addTearDown(db.close);
    notifications = FakeReminderNotifications();
    services = testServices(
      db: db,
      now: () => now,
      notifications: notifications,
    );
    await tester.runAsync(() async {
      if (existing == null) {
        final file = File('../data/schema/examples/bundles/14100/1.json');
        await db.importBundle(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          sha256: 'x',
          importedAt: now,
        );
        await db.setSetting(areaSettingKey, '14117-001001');
        await const ReminderPreferences(
          enabled: true,
          categories: {'moyasu'},
        ).save(db);
      }
      services.sync.bundle = await db.bundleFor('14100');
      services.sync.lastChecked = now;
      await services.area.load();
      await services.language.load();
    });
    await tester.pumpWidget(BinPalApp(services: services));
    await settle(tester);
  }

  Future<void> openLanguage(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.translate));
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await settle(tester);
  }

  testWidgets('follows the phone until a language is chosen', (tester) async {
    await launch(tester);
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
    expect(find.text('Same as phone (English)'), findsOneWidget);
  });

  testWidgets('choosing 日本語 switches the app and is kept', (tester) async {
    await launch(tester);
    await openLanguage(tester);
    expect(find.text('Same as phone'), findsOneWidget);
    expect(find.text('English'), findsWidgets);

    await tapText(tester, '日本語');
    // The language screen itself is now in Japanese.
    expect(find.text('言語 / Language'), findsOneWidget);
    expect(find.text('端末の設定に合わせる'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting(languageSettingKey)), 'ja');

    // pageBack looks for an English tooltip, so tap the button by type.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);

    // Relaunch on the same database.
    await tester.pumpWidget(const SizedBox());
    await launch(tester, existing: db);
    expect(find.text('今日'), findsWidgets);
    expect(find.text('検索'), findsOneWidget);
  });

  testWidgets('English on a Japanese phone, then back to the phone', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await launch(tester);
    expect(find.text('今日'), findsWidgets);

    await openLanguage(tester);
    expect(find.text('端末の設定に合わせる'), findsOneWidget);
    await tapText(tester, 'English');
    expect(find.text('Same as phone'), findsOneWidget);

    await tapText(tester, 'Same as phone');
    expect(find.text('端末の設定に合わせる'), findsOneWidget);
    expect(
      await tester.runAsync(() => db.setting(languageSettingKey)),
      'phone',
    );
  });

  testWidgets('reminders are rewritten in the chosen language', (tester) async {
    await launch(tester);
    await tester.runAsync(() => services.reminders.reschedule());
    expect(notifications.sorted.first.title, 'Tomorrow: Burnable');

    await openLanguage(tester);
    await tapText(tester, '日本語');
    expect(notifications.sorted.first.title, '明日は燃やすごみの日');
    expect(notifications.sorted.first.body, '明日の朝8:00までに出してください。');
  });

  test('an unknown saved value follows the phone', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    TestWidgetsFlutterBinding.ensureInitialized();
    final language = LanguageController(db: db);

    await db.setSetting(languageSettingKey, 'fr');
    await language.load();
    expect(language.chosen, isNull);

    await db.setSetting(languageSettingKey, 'ja');
    await language.load();
    expect(language.chosen, const Locale('ja'));
    expect(language.current, const Locale('ja'));
  });
}
