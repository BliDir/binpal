import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/bulky/bulky_guide.dart';
import 'package:binpal/features/bulky/bulky_guide_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/services.dart';

Map<String, dynamic> _example() => jsonDecode(
  File('../data/schema/examples/bundles/14100/1.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  group('which guide', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Area> area(String id) =>
        (db.select(db.areas)..where((a) => a.id.equals(id))).getSingle();

    test('a ward guide wins over the municipality guide', () async {
      final bundle = _example();
      final wide =
          (bundle['bulky_guides'] as List).single as Map<String, dynamic>;
      bundle['bulky_guides'] = [
        wide,
        {
          ...wide,
          'id': 'naka',
          'ward_ids': ['14104'],
          'summary': {'ja': '中区の粗大ごみ', 'en': 'Bulky waste in Naka'},
        },
      ];
      await db.importBundle(bundle, sha256: 'x');

      final aoba = await bulkyGuideFor(db, await area('14117-001001'));
      expect(aoba!.summary.en, startsWith('Metal items 30 cm'));
      final naka = await bulkyGuideFor(db, await area('14104-002000'));
      expect(naka!.summary.en, 'Bulky waste in Naka');
    });

    test('reads the guide, skipping link kinds it does not know', () async {
      final bundle = _example();
      final guide = (bundle['bulky_guides'] as List).single as Map;
      (guide['links'] as List).add({
        'kind': 'chat',
        'label': {'ja': 'チャット', 'en': 'Chat'},
        'url': 'https://city.example/chat',
      });
      await db.importBundle(bundle, sha256: 'x');

      final read = (await bulkyGuideFor(db, await area('14117-001001')))!;
      expect(read.steps.map((s) => s.title.en), [
        'Check the size',
        'Book',
        'Pay the fee',
        'Label it and put it out',
      ]);
      expect(read.contacts.single.phone, '0570-200-530');
      expect(read.booking!.url, endsWith('/top.html'));
      expect(read.links.map((l) => l.kind), [
        GuideLinkKind.booking,
        GuideLinkKind.fees,
      ]);
      expect(read.verifiedAt, '2026-11-15');
    });

    test(
      'none when the bundle has no guide, and gone with the bundle',
      () async {
        final bundle = _example()..remove('bulky_guides');
        await db.importBundle(bundle, sha256: 'x');
        expect(await bulkyGuideFor(db, await area('14117-001001')), isNull);
        expect(await db.select(db.bulkyGuides).get(), isEmpty);
      },
    );
  });

  group('screen', () {
    late AppDatabase db;
    late AppServices services;

    Future<void> start(
      WidgetTester tester, {
      Locale? locale,
      bool withGuide = true,
    }) async {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      services = testServices(db: db);
      await tester.runAsync(() async {
        final bundle = _example();
        if (!withGuide) bundle.remove('bulky_guides');
        await db.importBundle(bundle, sha256: 'x');
        services.sync.bundle = await db.bundleFor('14100');
        await db.setSetting(areaSettingKey, '14117-001001');
        await services.area.load();
        if (locale != null) await services.language.choose(locale);
      });
      await tester.pumpWidget(BinPalApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search).last);
      await tester.pumpAndSettle();
    }

    Future<void> openGuide(WidgetTester tester, String card) async {
      await tester.tap(find.text(card));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();
      }
    }

    testWidgets('from Search: the steps in order, booking and phone', (
      tester,
    ) async {
      await start(tester);
      await openGuide(tester, 'Bulky item guide');

      expect(find.byType(BulkyGuideScreen), findsOneWidget);
      expect(find.text('粗大ごみ'), findsOneWidget);
      expect(find.textContaining('Metal items 30 cm'), findsOneWidget);
      for (final step in ['Check the size', 'Book', 'Pay the fee']) {
        expect(find.text(step), findsOneWidget);
      }
      final list = find
          .descendant(
            of: find.byType(BulkyGuideScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Book online'),
        150,
        scrollable: list,
      );
      expect(
        find.textContaining("BinPal doesn't book for you"),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Call 0570-200-530'),
        150,
        scrollable: list,
      );
      await tester.scrollUntilVisible(
        find.textContaining('Checked against the official pages'),
        150,
        scrollable: list,
      );
      expect(find.text('Fee for each item'), findsOneWidget);
    });

    testWidgets('in Japanese', (tester) async {
      await start(tester, locale: const Locale('ja'));
      await openGuide(tester, '粗大ごみの出し方');
      expect(find.text('粗大ごみの出し方'), findsOneWidget);
      expect(find.text('大きさを確かめる'), findsOneWidget);
      expect(find.textContaining('Check the size'), findsNothing);
    });

    testWidgets('from a bulky item', (tester) async {
      await start(tester);
      await tester.enterText(find.byType(TextField), 'sofa');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sofa'));
      await tester.pumpAndSettle();
      await openGuide(tester, 'How to put out bulky items');
      expect(find.text('Check the size'), findsOneWidget);
    });

    testWidgets('says so when the area has no guide', (tester) async {
      await start(tester, withGuide: false);
      await openGuide(tester, 'Bulky item guide');
      expect(
        find.textContaining("There's no bulky item guide for your area yet"),
        findsOneWidget,
      );
    });
  });
}
