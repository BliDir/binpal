// Search speed on a real device with the full Yokohama bundle from the CDN:
//   flutter test integration_test/search_test.dart -d <device>

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/language_controller.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/features/search/item_search.dart';
import 'package:binpal/reminders/reminder_notifications.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search over the full Yokohama bundle', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sync = BundleSync(db: db, client: http.Client());
    final result = await sync.sync(launchMunicipalityId);
    expect(result.outcome, SyncOutcome.updated);
    final rules = await db.select(db.rules).get();
    expect(rules.length, greaterThan(3000));

    // Engine timings: every query a person types on the way to a word.
    final search = ItemSearch(db);
    const words = [
      'umbrella',
      'かさ',
      'カサ',
      'battery',
      '電池',
      'ぺっとぼとる',
      'microwave',
    ];
    final timings = <String, double>{};
    for (final word in words) {
      for (var n = 1; n <= word.length; n++) {
        final prefix = word.substring(0, n);
        final watch = Stopwatch()..start();
        await search.search(launchMunicipalityId, prefix);
        timings[prefix] = watch.elapsedMicroseconds / 1000;
      }
    }
    final sorted = timings.values.toList()..sort();
    final median = sorted[sorted.length ~/ 2];
    final worst = timings.entries.reduce((a, b) => a.value > b.value ? a : b);
    // ignore: avoid_print
    print(
      'search over ${rules.length} rules: ${timings.length} queries, '
      'median ${median.toStringAsFixed(1)} ms, '
      'slowest ${worst.value.toStringAsFixed(1)} ms ("${worst.key}")',
    );
    expect(worst.value, lessThan(100));

    final hits = await search.search(launchMunicipalityId, 'umbrella');
    expect(hits.first.rule.nameEn, startsWith('Umbrella'));
    final kana = await search.search(launchMunicipalityId, 'カサ');
    expect(kana.map((h) => h.rule.nameEn), contains(startsWith('Umbrella')));

    // Through the screen.
    final services = AppServices(
      db: db,
      sync: SyncController(db: db, sync: sync),
      area: AreaController(db: db),
      language: LanguageController(db: db),
      reminders: ReminderService(
        db: db,
        notifications: LocalReminderNotifications(),
      ),
      syncOnLaunch: false,
    );
    services.sync.bundle = await db.bundleFor(launchMunicipalityId);
    await tester.pumpWidget(BinPalApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'umbrella');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Umbrella (metal ribs)'), findsOneWidget);
    await tester.tap(find.text('Umbrella (metal ribs)'));
    await tester.pumpAndSettle();
    expect(find.text('How to put it out'), findsOneWidget);
  });
}
