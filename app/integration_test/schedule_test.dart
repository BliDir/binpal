// Calendar speed on a real device with the full Yokohama bundle from the CDN:
//   flutter test integration_test/schedule_test.dart -d <device>

import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/schedule_repository.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('next 60 days for one area', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final result = await BundleSync(
      db: db,
      client: http.Client(),
    ).sync(launchMunicipalityId);
    expect(result.outcome, SyncOutcome.updated);

    final repo = ScheduleRepository(db);
    final timings = <double>[];
    late List<CollectionDay> days;
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      final schedule = await repo.forArea(launchMunicipalityId, '14117-100001');
      days = schedule.days(JapanDate.today(), 60);
      timings.add(watch.elapsedMicroseconds / 1000);
    }
    // ignore: avoid_print
    print(
      '60 days for 14117-100001: first ${timings.first.toStringAsFixed(1)} ms, '
      'then ${timings.skip(1).map((t) => t.toStringAsFixed(1)).join(', ')} ms',
    );
    expect(days.where((d) => !d.isEmpty).length, greaterThan(30));
    expect(timings.first, lessThan(200));
  });
}
