import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/search/search_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/services.dart';

void main() {
  late AppDatabase db;
  late AppServices services;

  Future<void> withBundle(WidgetTester tester) async {
    await tester.runAsync(() async {
      final file = File('../data/schema/examples/bundles/14100/1.json');
      await db.importBundle(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        sha256: 'x',
      );
      services.sync.bundle = await db.bundleFor('14100');
    });
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.pumpWidget(BinPalApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
  }

  /// Types [query] and lets the debounce and the database query finish.
  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(SearchScreen.debounce);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    services = testServices(db: db);
  });
  tearDown(() => db.close());

  testWidgets('before any data is downloaded it says so', (tester) async {
    await openSearch(tester);
    expect(
      find.text(
        "Item search works offline once your area's data is downloaded.",
      ),
      findsOneWidget,
    );

    services.sync
      ..lastResult = const SyncResult(SyncOutcome.failed, error: 'offline')
      ..notifyListeners();
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows examples, and an example runs its search', (tester) async {
    await withBundle(tester);
    await openSearch(tester);
    expect(find.text('Search examples'), findsOneWidget);
    expect(find.text('Available offline'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, '傘'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Umbrella'), findsOneWidget);
  });

  for (final query in ['umbrella', 'かさ', 'カサ', '傘']) {
    testWidgets('"$query" lists the umbrella with its category', (
      tester,
    ) async {
      await withBundle(tester);
      await openSearch(tester);
      await type(tester, query);

      expect(find.text('1 result for “$query”'), findsOneWidget);
      expect(find.text('Umbrella'), findsOneWidget);
      expect(find.text('傘'), findsWidgets);
      expect(find.text('Small metal items / 小さな金属類'), findsOneWidget);
    });
  }

  testWidgets('a result opens the item with instructions and its source', (
    tester,
  ) async {
    await withBundle(tester);
    await openSearch(tester);
    await type(tester, 'umbrella');
    await tester.tap(find.text('Umbrella'));
    await tester.pumpAndSettle();

    expect(find.text('How to put it out'), findsOneWidget);
    expect(find.text('Put it out as it is.'), findsOneWidget);
    expect(find.text('In Japanese'), findsOneWidget);
    expect(find.text('そのまま出してください。'), findsOneWidget);
    expect(find.text('Official source'), findsOneWidget);
    expect(find.text('Yokohama City website'), findsOneWidget);
    expect(find.text('Checked against the source'), findsOneWidget);
    expect(find.text('Nov 1, 2026'), findsOneWidget);
  });

  testWidgets('in Japanese, names and instructions are Japanese only', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await withBundle(tester);
    await tester.pumpWidget(BinPalApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('検索').last);
    await tester.pumpAndSettle();
    await type(tester, 'umbrella');

    expect(find.text('「umbrella」の検索結果 1件'), findsOneWidget);
    expect(find.text('小さな金属類'), findsOneWidget);
    await tester.tap(find.text('傘'));
    await tester.pumpAndSettle();
    expect(find.text('そのまま出してください。'), findsOneWidget);
    expect(find.text('Put it out as it is.'), findsNothing);
  });

  testWidgets('a search that stays empty is counted once', (tester) async {
    await withBundle(tester);
    await openSearch(tester);
    await type(tester, 'zzzz');
    expect(find.text('No results for “zzzz”'), findsOneWidget);

    await tester.pump(SearchScreen.missedAfter);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    // Typing it again in the same session does not count it twice.
    await type(tester, 'zzz');
    await type(tester, 'zzzz');
    await tester.pump(SearchScreen.missedAfter);

    final rows = await tester.runAsync(
      () => db.select(db.missedSearches).get(),
    );
    expect(rows!.map((r) => (r.query, r.count)), [('zzzz', 1)]);
  });

  testWidgets('a search abandoned within two seconds is not counted', (
    tester,
  ) async {
    await withBundle(tester);
    await openSearch(tester);
    await type(tester, 'zzzz');
    await type(tester, 'umbrella');
    await tester.pump(SearchScreen.missedAfter);

    final rows = await tester.runAsync(
      () => db.select(db.missedSearches).get(),
    );
    expect(rows, isEmpty);
  });

  testWidgets('clear returns to the examples', (tester) async {
    await withBundle(tester);
    await openSearch(tester);
    await type(tester, 'umbrella');
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Search examples'), findsOneWidget);
  });
}
