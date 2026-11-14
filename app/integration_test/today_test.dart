// Today and the calendar with the full Yokohama bundle from the CDN, with
// screenshots saved to build/screenshots/:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/today_test.dart -d <device>

import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/language_controller.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/reminders/reminder_notifications.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;
  setUp(() => surfaceConverted = false);

  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('SCREENSHOTS', defaultValue: true)) return;
    if (Platform.isAndroid && !surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
      await tester.pumpAndSettle();
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    await binding.takeScreenshot('${platform}_$name');
  }

  for (final locale in const [Locale('en'), Locale('ja')]) {
    testWidgets('Today and calendar for 青葉台一丁目 (${locale.languageCode})', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final ja = locale.languageCode == 'ja';

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final sync = SyncController(
        db: db,
        sync: BundleSync(db: db, client: http.Client()),
      );
      final services = AppServices(
        db: db,
        sync: sync,
        area: AreaController(db: db),
        language: LanguageController(db: db),
        reminders: ReminderService(
          db: db,
          notifications: LocalReminderNotifications(),
        ),
        syncOnLaunch: false,
      );
      await sync.refresh(force: true);
      expect(sync.bundle, isNotNull);
      await db.setSetting(areaSettingKey, '14117-100001');
      await services.area.load();

      await tester.pumpWidget(BinPalApp(services: services));
      await tester.pumpAndSettle();
      expect(
        find.text(ja ? '青葉区青葉台一丁目' : 'Aobadai 1-chome, Aoba Ward'),
        findsWidgets,
      );
      await screenshot(tester, '${locale.languageCode}_today');

      final viewCalendar = find.text(ja ? 'カレンダーを見る' : 'View calendar');
      await tester.scrollUntilVisible(viewCalendar, 200);
      // Bring it clear of the tab bar before tapping.
      await tester.ensureVisible(viewCalendar);
      await tester.pumpAndSettle();
      await tester.tap(viewCalendar);
      await tester.pumpAndSettle();
      expect(find.text(ja ? 'カレンダー' : 'Calendar'), findsOneWidget);
      await screenshot(tester, '${locale.languageCode}_calendar');
    });
  }
}
