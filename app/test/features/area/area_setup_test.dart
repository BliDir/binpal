import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/area/boundary_package.dart';
import 'package:binpal/area/location_source.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/services.dart';

AreaMatch match(String id) => AreaMatch(id: id, name: '', distanceMetres: 30);

void main() {
  late AppDatabase db;
  late AppServices services;
  late FakeLocationSource location;
  late FakeBoundaryStore boundaries;
  final now = JapanDate(2026, 11, 17).atJapanTime(10, 0);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// The example bundle on the device and, unless [area] is given, no area
  /// chosen yet: a first launch.
  Future<void> start(WidgetTester tester, {String? area}) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    location = FakeLocationSource.at(35.5434, 139.5171);
    boundaries = FakeBoundaryStore([match('14117-001001')]);
    services = testServices(
      db: db,
      now: () => now,
      location: location,
      boundaries: boundaries,
    );
    await tester.runAsync(() async {
      final file = File('../data/schema/examples/bundles/14100/1.json');
      await db.importBundle(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        sha256: 'x',
        importedAt: now,
      );
      services.sync.bundle = await db.bundleFor('14100');
      services.sync.lastChecked = now;
      if (area != null) await db.setSetting(areaSettingKey, area);
      await services.area.load();
    });
    await tester.pumpWidget(BinPalApp(services: services));
    await settle(tester);
  }

  Future<String?> savedArea(WidgetTester tester) =>
      tester.runAsync<String?>(() => db.setting(areaSettingKey));

  /// Taps [text]; a button with it when there is one, so "Confirm area" is
  /// the button rather than the screen title.
  Future<void> tap(WidgetTester tester, String text) async {
    final button = find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    final target = button.evaluate().isEmpty ? find.text(text) : button;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  testWidgets('first launch: location finds the area, the user confirms', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Set your collection area'), findsOneWidget);
    expect(find.text('Your privacy is protected'), findsOneWidget);

    await tap(tester, 'Use my location');
    expect(location.calls, 1);
    expect(find.text('Is this your area?'), findsOneWidget);
    expect(
      find.text(
        "Looks like you're in Aobadai 1-chome, Aoba Ward. "
        'Is this where you put out your rubbish?',
      ),
      findsOneWidget,
    );
    expect(find.text('Aoba Ward, Yokohama City'), findsOneWidget);
    expect(find.text('Also near you'), findsNothing);

    await tap(tester, 'Confirm area');
    expect(await savedArea(tester), '14117-001001');
    expect(find.text('Aobadai 1-chome, Aoba Ward'), findsOneWidget); // Today
    expect(find.text('Set your collection area'), findsNothing);
  });

  testWidgets('near a boundary: both areas, and the user picks the other', (
    tester,
  ) async {
    await start(tester);
    boundaries.areas = [match('14117-001001'), match('14117-001002')];

    await tap(tester, 'Use my location');
    expect(find.text('Also near you'), findsOneWidget);
    expect(find.text('Aobadai 1-chome'), findsOneWidget);
    expect(find.text('Aobadai 2-chome'), findsOneWidget);

    await tap(tester, 'Aobadai 2-chome');
    await tap(tester, 'Confirm area');
    expect(await savedArea(tester), '14117-001002');
  });

  testWidgets('permission denied: explains, and the list still works', (
    tester,
  ) async {
    await start(tester);
    location.result = const LocationResult.problem(LocationProblem.denied);

    await tap(tester, 'Use my location');
    expect(find.textContaining("Location access wasn't allowed"), findsOne);
    expect(find.text('Open Settings'), findsNothing);
    expect(boundaries.positions, isEmpty);

    await tap(tester, 'Choose manually');
    await tap(tester, 'Naka Ward');
    await tap(tester, 'Yamashitacho');
    expect(await savedArea(tester), '14104-002000');
    expect(find.text('Yamashitacho, Naka Ward'), findsOneWidget); // Today
  });

  testWidgets('permission denied for good: offers the app settings', (
    tester,
  ) async {
    await start(tester);
    location.result = const LocationResult.problem(
      LocationProblem.deniedForever,
    );

    await tap(tester, 'Use my location');
    expect(find.textContaining('Location access is off'), findsOneWidget);
    await tap(tester, 'Open Settings');
    expect(location.openedSettings, [LocationProblem.deniedForever]);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a place BinPal does not cover yet is named', (tester) async {
    await start(tester);
    boundaries
      ..areas = [match('14131-001001')]
      ..municipalities['14131'] = '川崎市川崎区';

    await tap(tester, 'Use my location');
    expect(
      find.text("BinPal doesn't have collection days for 川崎市川崎区 yet."),
      findsOneWidget,
    );
  });

  testWidgets('"Choose another area" goes to the list', (tester) async {
    await start(tester);
    await tap(tester, 'Use my location');
    await tap(tester, 'Choose another area');
    expect(find.text('Choose your ward'), findsOneWidget);

    await tap(tester, 'Aoba Ward');
    await tap(tester, 'Azamino');
    expect(await savedArea(tester), '14117-002003');
    expect(find.text('Azamino 3-chome, Aoba Ward'), findsOneWidget); // Today
  });

  testWidgets('settings: changing the area returns to settings', (
    tester,
  ) async {
    await start(tester, area: '14117-001001');
    await tester.tap(find.byTooltip('Settings').first);
    await settle(tester);
    await tap(tester, 'Area');
    expect(find.text('Set your collection area'), findsOneWidget);

    boundaries.areas = [match('14117-001002')];
    await tap(tester, 'Use my location');
    await tap(tester, 'Confirm area');
    expect(await savedArea(tester), '14117-001002');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Aobadai 2-chome, Aoba Ward'), findsOneWidget);
  });

  testWidgets('in Japanese', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await start(tester);
    expect(find.text('収集地域を設定'), findsOneWidget);

    await tap(tester, '現在地を使う');
    expect(find.text('現在地は青葉区青葉台一丁目のようです。ここにごみを出していますか?'), findsOne);
    expect(find.text('横浜市青葉区'), findsOneWidget);
  });
}
