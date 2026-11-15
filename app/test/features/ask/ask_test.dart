import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/calendar/collection_schedule.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/ask/question_search.dart';
import 'package:binpal/features/item/item_screen.dart';
import 'package:binpal/features/search/search_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/services.dart';

void main() {
  group('search words', () {
    test('keep what names the item', () {
      expect(
        searchWords('Can I throw out a broken umbrella with a metal frame?'),
        ['umbrella', 'metal', 'frame'],
      );
      expect(searchWords('Where do batteries go?'), ['battery']);
      expect(searchWords('壊れた傘は何ごみですか'), ['壊', '傘']);
      expect(searchWords('スプレー缶の出し方は?'), ['スプレー', '缶']);
      expect(searchWords('How do I throw it out?'), isEmpty);
    });

    test(
      'find the area rules a question is about, on the Yokohama bundle',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await db.importBundle(
          jsonDecode(
            File('../data/municipalities/14100/bundle.json').readAsStringSync(),
          ) as Map<String, dynamic>,
          sha256: 'x',
        );
        Future<List<String>> names(String q) async => [
          for (final h in await QuestionSearch(
            db,
          ).candidates('14100', q, now: DateTime.utc(2026, 11, 15)))
            h.rule.nameEn,
        ];
        final umbrella = await names(
          'Can I throw out a broken umbrella with a metal frame?',
        );
        expect(umbrella, contains('Umbrella (metal ribs)'));
        expect(umbrella, hasLength(lessThanOrEqualTo(20)));
        expect((await names('Can I throw out a sofa?')).first, 'Sofa');
        expect((await names('スプレー缶の出し方は?')).first, 'Spray can');
      },
    );
  });

  group('screens', () {
    late AppDatabase db;
    late AppServices services;
    late List<Map<String, dynamic>> asked;
    late Future<http.Response> Function(Map<String, dynamic>) reply;
    // The example bundle's 青葉台一丁目 on a Tuesday; the umbrella's category
    // (小さな金属類) goes out with cans on Fridays.
    final now = JapanDate(2026, 11, 17).atJapanTime(10, 0);

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
    }

    Future<void> start(WidgetTester tester) async {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      asked = [];
      reply = (_) async => http.Response('{}', 500);
      services = testServices(
        db: db,
        now: () => now,
        apiClient: MockClient((request) async {
          if (request.url.path != '/v1/ask') return http.Response('', 404);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          asked.add(body);
          return reply(body);
        }),
      );
      await tester.runAsync(() async {
        await db.importBundle(
          jsonDecode(
            File('../data/schema/examples/bundles/14100/1.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>,
          sha256: 'x',
        );
        services.sync.bundle = await db.bundleFor('14100');
        await db.setSetting(areaSettingKey, '14117-001001');
        await services.area.load();
      });
      await tester.pumpWidget(BinPalApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search).last);
      await tester.pumpAndSettle();
    }

    http.Response answer(
      List<String> ids, {
      String? text,
      bool covered = true,
    }) => http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'answer': {'covered': covered, 'item_ids': ids, 'text': text},
          'cached': false,
        }),
      ),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

    Future<void> ask(WidgetTester tester, String question) async {
      await tester.tap(find.text('Ask a question'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, question);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Ask'));
      await settle(tester);
    }

    testWidgets('an answer: the rule says what to do, the AI summarises', (
      tester,
    ) async {
      await start(tester);
      reply = (_) async => answer(
        ['umbrella'],
        text: 'Yes. An umbrella with a metal frame goes out as Small metal items.',
      );
      await ask(
        tester,
        'Can I throw out a broken umbrella with a metal frame?',
      );

      final sent = asked.single;
      expect(sent['area_id'], '14117-001001');
      expect(sent['language'], 'en');
      expect([
        for (final c in sent['candidates'] as List) (c as Map)['item_id'],
      ], contains('umbrella'));
      expect(sent.containsKey('latitude'), isFalse);

      expect(
        find.text('Put it out as Small metal items / 小さな金属類.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('An umbrella with a metal frame'),
        findsOneWidget,
      );
      expect(find.text('Umbrella / 傘'), findsOneWidget);
      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('How to put it out'),
        100,
        scrollable: list,
      );
      expect(
        find.textContaining('Next collection: Fri, Nov 20'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('written by AI'),
        100,
        scrollable: list,
      );
      expect(find.textContaining('written by AI'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Umbrella / 傘'),
        -100,
        scrollable: list,
      );
      await tester.tap(find.text('Umbrella / 傘'));
      await tester.pumpAndSettle();
      expect(find.byType(ItemScreen), findsOneWidget);
    });

    testWidgets('a dropped sentence: the rule alone answers', (tester) async {
      await start(tester);
      reply = (_) async => answer(['umbrella']);
      await ask(tester, 'Is an umbrella burnable?');
      expect(
        find.text('Put it out as Small metal items / 小さな金属類.'),
        findsOneWidget,
      );
      expect(find.textContaining('written by AI'), findsNothing);
    });

    testWidgets('not covered: the ward office, not a guess', (tester) async {
      await start(tester);
      reply = (_) async => answer([], covered: false);
      await ask(tester, 'Can I put out an umbrella on a holiday?');
      expect(
        find.text("We can't answer this reliably from your area's rules."),
        findsOneWidget,
      );
      expect(find.text('Official contact'), findsOneWidget);
      expect(
        find.text('Aoba Office, Resources and Waste Recycling Bureau'),
        findsOneWidget,
      );
      expect(find.byTooltip('Call 045-975-0025'), findsOneWidget);
      expect(
        find.text('Put it out as Small metal items / 小さな金属類.'),
        findsNothing,
      );
    });

    testWidgets('nothing in the rules matches: no AI call at all', (
      tester,
    ) async {
      await start(tester);
      await ask(tester, 'When does the recycling centre open?');
      expect(asked, isEmpty);
      expect(find.text('Official contact'), findsOneWidget);
    });

    testWidgets('offline and paused say so, with the contact', (tester) async {
      await start(tester);
      reply = (_) async => throw http.ClientException('offline');
      await ask(tester, 'What about my umbrella?');
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.text('Official contact'), findsOneWidget);
    });

    testWidgets('from a search with no results, the words come along', (
      tester,
    ) async {
      await start(tester);
      await tester.enterText(find.byType(TextField), 'broken parasol frame');
      await tester.pump(SearchScreen.debounce);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Ask a question'));
      await tester.pumpAndSettle();
      expect(find.text('broken parasol frame'), findsOneWidget);
    });

    testWidgets('in Japanese, the answer is asked for in Japanese', (
      tester,
    ) async {
      await start(tester);
      await tester.runAsync(() => services.language.choose(const Locale('ja')));
      await tester.pumpAndSettle();
      reply = (_) async => answer(['umbrella'], text: '小さな金属類に出します。');
      await tester.tap(find.text('質問する'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '壊れた傘は何ごみですか');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '質問する'));
      await settle(tester);
      expect(asked.single['language'], 'ja');
      expect(find.text('小さな金属類に出します。'), findsWidgets);
    });
  });
}
