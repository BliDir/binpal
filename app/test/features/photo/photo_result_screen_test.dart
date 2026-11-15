import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/services.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/item/item_screen.dart';
import 'package:binpal/features/photo/photo_matcher.dart';
import 'package:binpal/features/photo/photo_result_screen.dart';
import 'package:binpal/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

import '../../support/services.dart';

void main() {
  late AppDatabase db;
  late AppServices services;
  late File photo;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) api;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
    api = (_) async => http.Response('{"answer": null, "cached": false}', 200);
    services = testServices(
      db: db,
      now: () => DateTime.utc(2026, 11, 15, 3),
      apiClient: MockClient((request) {
        requests.add(request);
        return api(request);
      }),
    );
    final dir = await Directory.systemTemp.createTemp('binpal-photo');
    photo = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 1600, height: 1200)));
  });
  tearDown(() => db.close());

  /// The result screen for a photo where the phone saw [labels] and [text].
  Future<void> show(
    WidgetTester tester,
    List<(String, double)> labels, {
    String text = '',
    bool modelsMissing = false,
  }) async {
    late PhotoSignals signals;
    late PhotoMatch match;
    await tester.runAsync(() async {
      await db.importBundle(
        jsonDecode(
          File('../data/schema/examples/bundles/14100/1.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
        sha256: 'x',
      );
      services.sync.bundle = await db.bundleFor('14100');
      final area = await (db.select(
        db.areas,
      )..where((a) => a.id.equals('14117-001001'))).getSingle();
      await services.area.select(area);
      signals = PhotoSignals(
        labels: [for (final (t, c) in labels) PhotoLabel(t, c)],
        text: text,
        modelsMissing: modelsMissing,
      );
      match = await PhotoMatcher(
        db,
        clock: services.clock,
      ).match('14100', signals);
    });
    await tester.pumpWidget(
      AppServicesScope(
        services: services,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoResultScreen(
            photoPath: photo.path,
            signals: signals,
            match: match,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Lets the resize isolate and the API call finish.
  Future<void> settleAi(WidgetTester tester) async {
    for (
      var i = 0;
      i < 50 && find.text('Asking AI…').evaluate().isNotEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('a confident match shows the item and how to put it out, '
      'with no AI call', (tester) async {
    await show(tester, [('Umbrella', 0.9)]);
    await settleAi(tester);

    expect(find.text('Match result'), findsOneWidget);
    expect(find.text('Likely match'), findsOneWidget);
    expect(find.textContaining('Umbrella / '), findsOneWidget);
    expect(find.text('Small metal items / 小さな金属類'), findsOneWidget);
    expect(find.text('How to put it out'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(find.text('View sorting rule'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemScreen), findsOneWidget);
  });

  testWidgets('a recycling mark decides the category', (tester) async {
    await show(tester, [('Bottle', 0.8)], text: '1\nPET');
    expect(find.text('From the recycling mark'), findsOneWidget);
    expect(find.textContaining('PET bottle / '), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('not sure: shows the candidates at once and the AI pick when it '
      'arrives', (tester) async {
    api = (_) async => http.Response(
      jsonEncode({
        'answer': {
          'item_id': 'battery-dry-cell',
          'category': 'denchi',
          'confidence': 0.8,
        },
        'cached': false,
      }),
      200,
    );
    await show(tester, [('Umbrella', 0.55), ('Battery', 0.55)]);

    expect(find.text('Which item is this?'), findsOneWidget);
    expect(find.text('Asking AI…'), findsOneWidget);
    expect(find.textContaining('Umbrella / '), findsOneWidget);

    await settleAi(tester);
    expect(find.text('AI suggestion'), findsOneWidget);
    // Listed once, as the AI's pick, not again among the others.
    expect(find.textContaining('Battery / '), findsOneWidget);

    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['area_id'], '14117-001001');
    expect([
      for (final c in body['candidates'] as List) (c as Map)['item_id'],
    ], containsAll(['umbrella', 'battery-dry-cell']));
    expect(body['labels'], ['Umbrella', 'Battery']);
    final sent = img.decodeJpg(base64Decode(body['image'] as String))!;
    expect(sent.width, 512);
    expect(sent.height, 384);
  });

  testWidgets('choosing an item opens it and remembers it for next time', (
    tester,
  ) async {
    await show(tester, [('Umbrella', 0.6), ('Battery', 0.6)]);
    await settleAi(tester);

    await tester.tap(find.textContaining('Battery / '));
    await tester.pumpAndSettle();
    expect(find.byType(ItemScreen), findsOneWidget);

    final choices = await tester.runAsync(
      () => db.select(db.photoChoices).get(),
    );
    expect(choices!.single.itemId, 'battery-dry-cell');
    expect(choices.single.signals, 'battery|umbrella');
  });

  testWidgets('offline: says so and keeps the candidates', (tester) async {
    api = (_) async => throw http.ClientException('no network');
    await show(tester, [('Umbrella', 0.55), ('Battery', 0.55)]);
    await settleAi(tester);

    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(find.textContaining('Umbrella / '), findsOneWidget);
    expect(find.text('Search by name'), findsOneWidget);
  });

  testWidgets('AI paused for the day', (tester) async {
    api = (_) async => http.Response('{"error": "ai_paused"}', 503);
    await show(tester, [('Umbrella', 0.55), ('Battery', 0.55)]);
    await settleAi(tester);
    expect(find.textContaining('paused for today'), findsOneWidget);
  });

  testWidgets('nothing recognised: try again or search', (tester) async {
    await show(tester, [('Hand', 0.9)]);
    await settleAi(tester);
    expect(find.text("Couldn't recognise this item"), findsOneWidget);
    expect(find.text('Take another photo'), findsOneWidget);
    expect(find.text('Search by name'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('says when the models are still downloading', (tester) async {
    await show(tester, [], modelsMissing: true);
    expect(find.textContaining('still getting ready'), findsOneWidget);
  });

  testWidgets('"not right" on a confident match asks the AI', (tester) async {
    await show(tester, [('Umbrella', 0.9)]);
    await tester.tap(find.text('Not right? Choose another item'));
    await tester.pump();
    await settleAi(tester);
    expect(find.text('Which item is this?'), findsOneWidget);
    expect(requests, hasLength(1));
  });

  testWidgets('the photo is deleted when the screen closes', (tester) async {
    await show(tester, [('Umbrella', 0.9)]);
    expect(photo.existsSync(), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(photo.existsSync(), isFalse);
  });
}
