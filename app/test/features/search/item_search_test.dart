import 'dart:convert';
import 'dart:io';

import 'package:binpal/data/database.dart';
import 'package:binpal/features/search/item_search.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final now = DateTime.utc(2026, 11, 13);

  group('example bundle', () {
    late AppDatabase db;
    late ItemSearch search;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.importBundle(
        _load('../data/schema/examples/bundles/14100/1.json'),
        sha256: 'x',
      );
      search = ItemSearch(db);
    });
    tearDown(() => db.close());

    Future<List<String>> ids(String q) async => [
      for (final h in await search.search('14100', q, now: now)) h.rule.itemId,
    ];

    for (final q in [
      'umbrella',
      'UMBRELLA',
      'Umbrella',
      'かさ',
      'カサ',
      'ｶｻ',
      '傘',
      'parasol',
    ]) {
      test('"$q" finds the umbrella', () async {
        expect((await ids(q)).first, 'umbrella');
      });
    }

    test('the hit carries its category', () async {
      final hit = (await search.search('14100', '傘', now: now)).first;
      expect(hit.category.id, 'kinzoku');
      expect(hit.category.nameEn, 'Small metal items');
    });

    test('every word must match', () async {
      expect(await ids('pet bottle'), ['pet-bottle']);
      expect(await ids('pet umbrella'), isEmpty);
    });

    test('nothing for an empty query or one that matches nothing', () async {
      expect(await ids(''), isEmpty);
      expect(await ids('   '), isEmpty);
      expect(await ids('zzzz'), isEmpty);
      expect(await ids('%'), isEmpty);
    });

    test('another municipality is not searched', () async {
      expect(await search.search('13112', 'umbrella', now: now), isEmpty);
    });

    test('a rule outside its validity dates is not shown', () async {
      await (db.update(db.rules)..where((r) => r.itemId.equals('umbrella')))
          .write(const RulesCompanion(validTo: Value('2026-11-12')));
      expect(await ids('umbrella'), isEmpty);
    });

    test('missed searches are counted, normalised', () async {
      await db.recordMissedSearch('ＺＺＺ');
      await db.recordMissedSearch('zzz');
      await db.recordMissedSearch('  ');
      final rows = await db.select(db.missedSearches).get();
      expect(rows.map((r) => (r.query, r.count)), [('zzz', 2)]);
    });
  });

  group('Yokohama bundle', () {
    late AppDatabase db;
    late ItemSearch search;
    final bundle = _load('../data/municipalities/14100/bundle.json');

    setUpAll(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.importBundle(bundle, sha256: 'x');
      search = ItemSearch(db);
    });
    tearDownAll(() => db.close());

    Future<List<String>> names(String q) async => [
      for (final h in await search.search('14100', q, now: now)) h.rule.nameEn,
    ];

    test('every rule is indexed', () async {
      final indexed = await db
          .customSelect('SELECT COUNT(DISTINCT rule_id) AS n FROM search_index')
          .getSingle();
      expect(indexed.read<int>('n'), (bundle['rules'] as List).length);
    });

    for (final q in ['umbrella', 'かさ', 'カサ', '傘']) {
      test('"$q" puts the umbrellas first', () async {
        final top = (await names(q)).take(2).toSet();
        expect(top, {'Umbrella (metal ribs)', 'Umbrella (plastic ribs)'});
      });
    }

    test('short and long queries in every script', () async {
      expect(
        await names('電池'),
        contains('Dry-cell batteries (manganese, alkaline, lithium primary)'),
      );
      expect((await names('battery')).length, greaterThan(3));
      expect((await names('ペットボトル')).first, contains('PET bottle'));
      expect((await names('ﾍﾟｯﾄﾎﾞﾄﾙ')).first, contains('PET bottle'));
      expect(await names('frying pan'), contains('Frying pan'));
      expect(await names('ふらいぱん'), contains('Frying pan'));
      expect(await names('microwave'), contains('Microwave oven'));
      expect((await names('靴')).length, greaterThan(5));
    });

    test('results are ranked: exact, prefix, word start, anywhere', () async {
      final results = await names('mug');
      expect(results.first, 'Mug');
      // "pan" starts a word in "Frying pan" but is inside "Japanese".
      final pan = await names('pan');
      expect(pan, contains('Frying pan'));
      final japanese = pan.indexOf('Japanese umbrella (wagasa)');
      if (japanese >= 0) {
        expect(pan.indexOf('Frying pan'), lessThan(japanese));
      }
    });

    test('searches are fast enough to run on every keystroke', () async {
      const queries = [
        'u',
        'um',
        'umb',
        'umbrella',
        'か',
        'かさ',
        '傘',
        '電池',
        'battery',
        'ぺっと',
        'plastic bottle',
        'の',
        'e',
        'てれび',
        'microwave oven',
      ];
      for (final q in queries) {
        await search.search('14100', q, now: now); // warm up
      }
      final watch = Stopwatch()..start();
      for (var i = 0; i < 5; i++) {
        for (final q in queries) {
          await search.search('14100', q, now: now);
        }
      }
      final average = watch.elapsedMicroseconds / (5 * queries.length) / 1000;
      // ignore: avoid_print
      print('average search: ${average.toStringAsFixed(1)} ms');
      expect(average, lessThan(50));
    });
  });
}
