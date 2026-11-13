// Reminders on a real device or emulator, with the full Yokohama bundle:
//   flutter test integration_test/reminders_test.dart -d <device>
//
// With --dart-define=DELIVERY_CHECK=true it also schedules one notification
// a minute ahead, titled "BinPal delivery check", so delivery can be checked
// after the app has been closed.
//
// The delivery check needs the app to stay installed after the test:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/reminders_test.dart -d <device> \
//     --keep-app-running --dart-define=DELIVERY_CHECK=true \
//     --dart-define=SCREENSHOTS=false
// Notification permission: on Android, grant it while the test waits
// (`adb shell pm grant com.blidir.binpal android.permission.POST_NOTIFICATIONS`).
// On iOS the test asks, and someone has to tap Allow: iOS keeps no pending
// notifications for an app without permission, and the simulator cannot be
// granted it from the command line.

import 'dart:io';

import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/reminders/reminder_notifications.dart';
import 'package:binpal/reminders/reminder_preferences.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('schedules at most 64 reminders for an Aoba-ku area', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final result = await BundleSync(
      db: db,
      client: http.Client(),
    ).sync(launchMunicipalityId);
    expect(result.outcome, SyncOutcome.updated);

    await db.setSetting(areaSettingKey, '14117-100001');
    final categories = {
      for (final c in await db.select(db.categories).get()) c.id,
    };
    await ReminderPreferences(enabled: true, categories: categories).save(db);

    final notifications = LocalReminderNotifications();
    await notifications.initialize();
    if (Platform.isIOS) {
      expect(
        await notifications.requestPermission(),
        isTrue,
        reason: 'Tap Allow on the notification prompt.',
      );
    }
    final service = ReminderService(db: db, notifications: notifications);

    // Several times over, as launches and returns to the foreground would.
    for (var i = 0; i < 3; i++) {
      await service.reschedule();
    }
    final pending = await notifications.pendingIds();
    // ignore: avoid_print
    print(
      'scheduled ${service.scheduled}, pending ${pending.length}, '
      'first ${pending.reduce((a, b) => a < b ? a : b)}, '
      'last ${pending.reduce((a, b) => a > b ? a : b)}',
    );
    expect(pending.length, service.scheduled);
    expect(pending.length, lessThanOrEqualTo(64));
    expect(pending.length, greaterThan(20));

    if (const bool.fromEnvironment('DELIVERY_CHECK')) {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (var i = 0; android != null && i < 60; i++) {
        if (await android.areNotificationsEnabled() ?? false) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final at = DateTime.now().add(const Duration(minutes: 1));
      await notifications.schedule(
        id: 1,
        at: at,
        title: 'BinPal delivery check',
        body: 'Scheduled for ${JapanDate.at(at)} ${at.toUtc()} UTC',
        channelName: 'Collection reminders',
      );
      // ignore: avoid_print
      print('delivery check scheduled for ${at.toUtc()} UTC');
    }
  });
}
