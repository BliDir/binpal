// First-launch sync against the real CDN, on a simulator or device:
//   flutter test integration_test/sync_test.dart -d <device>

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/reminders/reminder_notifications.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('downloads the Yokohama bundle and works offline after', (
    tester,
  ) async {
    // A fresh in-memory database, so this is always a first launch.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final services = AppServices(
      db: db,
      sync: SyncController(
        db: db,
        sync: BundleSync(db: db, client: http.Client()),
      ),
      area: AreaController(db: db),
      reminders: ReminderService(
        db: db,
        notifications: LocalReminderNotifications(),
      ),
    );

    await tester.pumpWidget(BinPalApp(services: services));
    // The first screen is there before any data is.
    await tester.pump();
    expect(find.text('Today'), findsWidgets);

    final watch = Stopwatch()..start();
    while (services.sync.bundle == null && watch.elapsed.inSeconds < 60) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(services.sync.lastResult?.outcome, SyncOutcome.updated);
    final bundle = services.sync.bundle!;
    final rules = await db.select(db.rules).get();
    final areas = await db.select(db.areas).get();
    // ignore: avoid_print
    print(
      'synced ${bundle.nameEn} v${bundle.bundleVersion} in '
      '${watch.elapsedMilliseconds} ms: ${rules.length} rules, '
      '${areas.length} areas',
    );
    expect(rules.length, greaterThan(3000));
    expect(areas.length, greaterThanOrEqualTo(85));

    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Yokohama City · version ${bundle.bundleVersion}'),
      findsOneWidget,
    );

    // With the network gone, the stored data is still served.
    final offline = SyncController(
      db: db,
      sync: BundleSync(
        db: db,
        client: http.Client(),
        baseUrl: 'https://offline.invalid',
      ),
    );
    await offline.refresh(force: true);
    expect(offline.lastResult?.outcome, SyncOutcome.failed);
    expect(offline.bundle?.bundleVersion, bundle.bundleVersion);
  });
}
