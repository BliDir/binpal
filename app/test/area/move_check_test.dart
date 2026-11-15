import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/area/boundary_store.dart';
import 'package:binpal/area/location_source.dart';
import 'package:binpal/area/move_check.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/area/area_setup_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/services.dart';

/// [MoveCheck] against the published Kanagawa boundary package and Yokohama
/// bundle. Home is 青葉区 area 14117-088001.
void main() {
  final package = File('../data/boundaries/14.json').readAsBytesSync();
  final bundle = jsonDecode(
    File('../data/municipalities/14100/bundle.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final manifest = jsonEncode({
    'boundaries': [
      {
        'prefecture_code': '14',
        'schema_version': 1,
        'version': 1,
        'path': '/boundaries/14/1.json',
        'bbox': [138.915472, 35.128712, 139.796502, 35.673035],
        'sha256': sha256.convert(package).toString(),
        'size_bytes': package.length,
      },
    ],
  });
  const home = (35.553493, 139.536621);
  // Yokohama Station, about 12 km away; still inside the package.
  const away = (35.465800, 139.622300);
  // Two streets over from home, under 3 km.
  const nearHome = (35.556500, 139.541000);

  late Directory dir;
  late List<Uri> requests;
  late FakeLocationSource location;
  late AppServices services;
  late DateTime now;

  Future<void> setUpServices({bool checkMove = false}) async {
    dir = await Directory.systemTemp.createTemp('binpal-move');
    requests = [];
    location = FakeLocationSource.at(home.$1, home.$2);
    now = JapanDate(2026, 11, 16).atJapanTime(8, 0);
    final client = MockClient((request) async {
      requests.add(request.url);
      return switch (request.url.path) {
        '/manifest.json' => http.Response(manifest, 200),
        '/boundaries/14/1.json' => http.Response.bytes(package, 200),
        _ => http.Response('', 404),
      };
    });
    final db = AppDatabase(NativeDatabase.memory());
    await db.importBundle(bundle, sha256: 'x');
    services = testServices(
      db: db,
      location: location,
      now: () => now,
      checkMove: checkMove,
      boundaries: BoundaryStore(
        client: client,
        directory: () async => dir,
        baseUrl: 'https://cdn.test',
      ),
    );
    services.sync.bundle = await db.bundleFor('14100');
    final area = await (db.select(
      db.areas,
    )..where((a) => a.id.equals('14117-088001'))).getSingle();
    await services.chooseArea(area);
    // Area setup by location downloaded the package, as it would have.
    await services.boundaries.lookup(home.$1, home.$2);
    requests.clear();
  }

  Future<void> tearDownServices() async {
    await services.db.close();
    await dir.delete(recursive: true);
  }

  /// Opens the app at [position] on [day] days after the first.
  Future<bool> openAt((double, double) position, int day) {
    location.result = LocationResult.position(position.$1, position.$2);
    now = JapanDate(2026, 11, 16).addDays(day).atJapanTime(8, 0);
    return services.moveCheck.shouldAsk();
  }

  group('when to ask', () {
    setUp(setUpServices);
    tearDown(tearDownServices);

    test('never at home', () async {
      for (var day = 0; day < 5; day++) {
        expect(await openAt(home, day), isFalse);
        expect(await openAt(nearHome, day), isFalse);
      }
    });

    test('after three days away, not before', () async {
      expect(await openAt(away, 0), isFalse);
      expect(await openAt(away, 1), isFalse);
      expect(await openAt(away, 3), isTrue);
    });

    test('at most one look a day', () async {
      expect(await openAt(away, 0), isFalse);
      location.calls = 0;
      expect(await openAt(away, 0), isFalse);
      expect(await openAt(away, 0), isFalse);
      expect(location.calls, 0);
      expect(await openAt(away, 1), isFalse);
      expect(await openAt(away, 2), isTrue);
    });

    test('a day at home in between was the commute or a trip', () async {
      expect(await openAt(away, 0), isFalse);
      expect(await openAt(away, 1), isFalse);
      expect(await openAt(home, 2), isFalse);
      expect(await openAt(away, 3), isFalse);
      expect(await openAt(away, 4), isFalse);
      expect(await openAt(away, 5), isTrue);
    });

    test('days away more than two weeks ago no longer count', () async {
      expect(await openAt(away, 0), isFalse);
      expect(await openAt(away, 1), isFalse);
      expect(await openAt(away, 20), isFalse);
      expect(await openAt(away, 21), isFalse);
      expect(await openAt(away, 22), isTrue);
    });

    test('"Not now" mutes it for 30 days', () async {
      for (var day = 0; day < 3; day++) {
        await openAt(away, day);
      }
      await services.moveCheck.notNow();
      for (var day = 3; day < 32; day++) {
        expect(await openAt(away, day), isFalse, reason: 'day $day');
      }
      // Muted until day 32; then it counts afresh.
      expect(await openAt(away, 32), isFalse);
      expect(await openAt(away, 33), isFalse);
      expect(await openAt(away, 34), isTrue);
    });

    test('a new area starts the count again', () async {
      await openAt(away, 0);
      await openAt(away, 1);
      final other = await (services.db.select(
        services.db.areas,
      )..where((a) => a.id.equals('14117-068001'))).getSingle();
      await services.chooseArea(other);
      expect(await openAt(away, 2), isFalse);
    });

    test('no look without location access, and never asks for it', () async {
      location.result = const LocationResult.problem(LocationProblem.denied);
      now = JapanDate(2026, 11, 20).atJapanTime(8, 0);
      expect(await services.moveCheck.shouldAsk(), isFalse);
      expect(location.calls, 0);
    });

    test('no position kept and nothing sent', () async {
      for (var day = 0; day < 3; day++) {
        await openAt(away, day);
      }
      expect(requests, isEmpty);
      final settings = {
        for (final s in await services.db.select(services.db.settings).get())
          s.key: s.value,
      };
      for (final value in settings.values) {
        for (final digits in ['35.46', '139.62', '35.55', '139.53']) {
          expect(value, isNot(contains(digits)));
        }
      }
      expect(jsonDecode(settings['move.far']!), {
        'area': '14117-088001',
        'days': ['2026-11-16', '2026-11-17', '2026-11-18'],
      });
    });

    test('no boundaries on the phone: no look, no download', () async {
      await dir.delete(recursive: true);
      await dir.create();
      expect(await openAt(away, 0), isFalse);
      expect(await openAt(away, 1), isFalse);
      expect(await openAt(away, 2), isFalse);
      expect(requests, isEmpty);
    });
  });

  group('the prompt', () {
    Future<void> openApp(WidgetTester tester) async {
      await tester.runAsync(() async {
        await setUpServices(checkMove: true);
        // Away on the two days before; today is the third.
        await openAt(away, 0);
        await openAt(away, 1);
        location.result = LocationResult.position(away.$1, away.$2);
        now = JapanDate(2026, 11, 18).atJapanTime(8, 0);
      });
      addTearDown(() => tester.runAsync(tearDownServices));
      await tester.pumpWidget(BinPalApp(services: services));
      for (
        var i = 0;
        i < 20 && find.text('Did you move?').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('asks, shows the saved area, and "Not now" mutes it', (
      tester,
    ) async {
      await openApp(tester);
      expect(find.text('Did you move?'), findsOneWidget);
      expect(find.text('Currently saved area'), findsOneWidget);
      expect(find.textContaining('Aoba Ward'), findsWidgets);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('Did you move?'), findsNothing);
      final snoozed = await tester.runAsync(
        () => services.db.setting('move.snoozed_until'),
      );
      expect(snoozed, '2026-12-18');
      expect(services.area.area!.id, '14117-088001');
    });

    testWidgets('"Update area" opens area setup; the area is not changed', (
      tester,
    ) async {
      await openApp(tester);
      await tester.tap(find.text('Update area'));
      await tester.pumpAndSettle();
      expect(find.byType(AreaSetupScreen), findsOneWidget);
      expect(services.area.area!.id, '14117-088001');
    });
  });
}
