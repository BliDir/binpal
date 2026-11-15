import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/report/report_client.dart';
import 'package:binpal/features/search/search_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/services.dart';

void main() {
  late AppDatabase db;
  late AppServices services;
  late List<Map<String, dynamic>> sent;
  late Future<http.Response> Function() reply;
  // The example bundle's 青葉台一丁目, on a Tuesday.
  final now = JapanDate(2026, 11, 17).atJapanTime(10, 0);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> start(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    sent = [];
    reply = () async => http.Response('{"ok": true}', 201);
    services = testServices(
      db: db,
      now: () => now,
      apiClient: MockClient((request) async {
        if (request.url.path == '/v1/reports') {
          sent.add(jsonDecode(request.body) as Map<String, dynamic>);
        }
        return reply();
      }),
    );
    await tester.runAsync(() async {
      final file = File('../data/schema/examples/bundles/14100/1.json');
      await db.importBundle(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        sha256: 'x',
      );
      services.sync.bundle = await db.bundleFor('14100');
      services.sync.lastChecked = now;
      await db.setSetting(areaSettingKey, '14117-001001');
      await services.area.load();
    });
    await tester.pumpWidget(BinPalApp(services: services));
    await settle(tester);
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(SearchScreen.debounce);
    await settle(tester);
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Send report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await settle(tester);
  }

  group('client', () {
    test('sends only what the report says', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      late Map<String, dynamic> body;
      final client = ReportClient(
        db: database,
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"ok": true}', 201);
        }),
        appVersion: () async => '1.1.0',
      );
      expect(
        await client.send(
          areaId: '14117-001001',
          kind: ReportKind.wrongDay,
          date: '2026-11-17',
          note: '  ',
        ),
        ReportResult.sent,
      );
      expect(body.keys.toSet(), {
        'install_id',
        'area_id',
        'kind',
        'date',
        'app_version',
      });
      expect(body['kind'], 'wrong_day');
      expect(body['app_version'], '1.1.0');
    });

    test('says why a report was not sent', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      Future<ReportResult> result(Future<http.Response> Function() reply) =>
          ReportClient(
            db: database,
            client: MockClient((_) => reply()),
            appVersion: () async => null,
          ).send(areaId: '14117-001001', kind: ReportKind.other);
      expect(
        await result(() async => http.Response('{}', 429)),
        ReportResult.limited,
      );
      expect(
        await result(() async => http.Response('{}', 500)),
        ReportResult.failed,
      );
      expect(
        await result(() async => throw http.ClientException('offline')),
        ReportResult.offline,
      );
    });
  });

  testWidgets('from an item: choose what is wrong, comment, send', (
    tester,
  ) async {
    await start(tester);
    await search(tester, 'umbrella');
    await tester.tap(find.text('Umbrella').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('This looks wrong'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('This looks wrong'));
    await tester.pumpAndSettle();

    expect(
      find.text('Report a problem with the collection day, category or rules.'),
      findsOneWidget,
    );
    expect(find.text('Aobadai 1-chome, Aoba Ward'), findsOneWidget);
    expect(
      find.textContaining("Please don't include personal details"),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'How to put it out'));
    await tester.enterText(
      find.byType(TextField).last,
      'Metal ribs are small metal items',
    );
    await send(tester);

    expect(sent.single['kind'], 'wrong_instructions');
    expect(sent.single['item_id'], 'umbrella');
    expect(sent.single['area_id'], '14117-001001');
    expect(sent.single['note'], 'Metal ribs are small metal items');
    expect(sent.single.containsKey('date'), isFalse);
    expect(find.text('Send report'), findsNothing);
    expect(find.textContaining("We'll check it"), findsOneWidget);
  });

  testWidgets('from Today: a wrong collection day, with the date', (
    tester,
  ) async {
    await start(tester);
    await tester.scrollUntilVisible(find.text('This looks wrong'), 100);
    await tester.tap(find.text('This looks wrong'));
    await tester.pumpAndSettle();
    expect(find.text('Collection date'), findsOneWidget);
    expect(find.text('Tue, Nov 17'), findsOneWidget);

    await send(tester);
    expect(sent.single['kind'], 'wrong_day');
    expect(sent.single['date'], '2026-11-17');
    expect(sent.single.containsKey('item_id'), isFalse);
  });

  testWidgets('from search with no results: the query is the comment', (
    tester,
  ) async {
    await start(tester);
    await search(tester, 'hanger');
    await tester.tap(find.text("Can't find it? Tell us"));
    await tester.pumpAndSettle();
    expect(find.text('What were you looking for?'), findsOneWidget);

    await send(tester);
    expect(sent.single['kind'], 'missing_item');
    expect(sent.single['note'], 'hanger');
  });

  testWidgets('offline: says so and keeps the sheet open', (tester) async {
    await start(tester);
    reply = () async => throw http.ClientException('offline');
    await tester.scrollUntilVisible(find.text('This looks wrong'), 100);
    await tester.tap(find.text('This looks wrong'));
    await tester.pumpAndSettle();
    await send(tester);
    expect(find.text("You're offline. Connect and try again."), findsOneWidget);
    expect(find.text('Send report'), findsOneWidget);

    reply = () async => http.Response('{"error": "daily_limit"}', 429);
    await send(tester);
    expect(find.textContaining('try again tomorrow'), findsOneWidget);
  });
}
