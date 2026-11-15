import 'dart:convert';
import 'dart:io';

import 'package:binpal/data/database.dart';
import 'package:binpal/features/photo/photo_matcher.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Against the full Yokohama bundle, with labels as ML Kit gives them.
void main() {
  late AppDatabase db;
  late PhotoMatcher matcher;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.importBundle(
      jsonDecode(
        File('../data/municipalities/14100/bundle.json').readAsStringSync(),
      ) as Map<String, dynamic>,
      sha256: 'x',
    );
    matcher = PhotoMatcher(db, clock: () => DateTime.utc(2026, 11, 15));
  });
  tearDown(() => db.close());

  Future<PhotoMatch> match(List<(String, double)> labels, {String text = ''}) =>
      matcher.match(
        '14100',
        PhotoSignals(
          labels: [for (final (t, c) in labels) PhotoLabel(t, c)],
          text: text,
        ),
      );

  group('confident on the phone', () {
    test('a label that is exactly one item', () async {
      final m = await match([('Mobile phone', 0.9)]);
      expect(m.answer?.source, PhotoAnswerSource.label);
      expect(m.answer?.item?.rule.nameEn, 'Mobile phone');
    });

    test('a plural label finds the singular item', () async {
      final m = await match([('Shoes', 0.8)]);
      expect(m.answer?.item?.rule.nameEn, 'Shoes');
      expect(m.answer?.category.id, 'moyasu');
    });

    test('the only likely candidate, even if not far ahead', () async {
      final m = await match([('Newspaper', 0.8)]);
      expect(m.answer?.source, PhotoAnswerSource.sharedCategory);
      expect(m.answer?.item?.rule.nameEn, 'Newspaper');
      expect(m.answer?.category.id, 'koshi');
    });

    test('a PET mark decides, and names the drinks bottle', () async {
      final m = await match([('Bottle', 0.85)], text: '1\nPET\nキャップ・ラベル プラ');
      expect(m.answer?.source, PhotoAnswerSource.mark);
      expect(m.answer?.category.id, 'kan-bin-pet');
      expect(m.answer?.item?.rule.nameEn, 'PET bottle (for drinks)');
    });

    test('a PET mark prefers the bottle the labels found', () async {
      final m = await match([('Soy sauce', 0.7)], text: 'PET');
      expect(m.answer?.item?.rule.nameEn, 'Soy sauce PET bottle');
    });

    test('a metal mark names the drink can', () async {
      final m = await match([('Tin can', 0.8)], text: 'アルミ');
      expect(m.answer?.category.id, 'kan-bin-pet');
      expect(m.answer?.item?.rule.category, 'kan-bin-pet');
    });

    test('プラ decides the category but no single item', () async {
      final m = await match([('Food', 0.7)], text: 'プラ');
      expect(m.answer?.source, PhotoAnswerSource.mark);
      expect(m.answer?.category.id, 'plastic');
      expect(m.answer?.item, isNull);
      expect(m.candidates.every((c) => c.category.id == 'plastic'), isTrue);
    });
  });

  group('not confident', () {
    test('two umbrellas in different categories', () async {
      final m = await match([('Umbrella', 0.9), ('Hand', 0.8)]);
      expect(m.answer, isNull);
      expect(m.candidates.take(2).map((c) => c.rule.nameEn), [
        'Umbrella (metal ribs)',
        'Umbrella (plastic ribs)',
      ]);
    });

    test('a spray can is not decided by its steel mark', () async {
      final m = await match([('Cosmetics', 0.6)], text: 'スチール\nスプレー');
      expect(m.answer, isNull);
    });

    test('marks that disagree', () async {
      final m = await match([], text: 'プラ\nスチール');
      expect(m.answer, isNull);
    });

    test('nothing to go on', () async {
      final m = await match([('Hand', 0.9), ('Bottle', 0.3)]);
      expect(m.answer, isNull);
      expect(m.candidates, isEmpty);
    });
  });

  test('at most 20 candidates, for the API', () async {
    final m = await match([('Bottle', 0.85)]);
    expect(m.candidates, hasLength(PhotoMatcher.maxCandidates));
  });

  group('remembered choices', () {
    test('answer the same labels and marks next time', () async {
      final signals = PhotoSignals(
        labels: const [PhotoLabel('Umbrella', 0.9), PhotoLabel('Hand', 0.8)],
      );
      expect((await matcher.match('14100', signals)).answer, isNull);
      final plastic = (await matcher.match('14100', signals)).candidates[1];
      await matcher.remember('14100', signals, plastic.rule.itemId);

      final again = await matcher.match(
        '14100',
        PhotoSignals(labels: const [PhotoLabel('Umbrella', 0.8)]),
      );
      expect(again.answer?.source, PhotoAnswerSource.remembered);
      expect(again.answer?.item?.rule.nameEn, 'Umbrella (plastic ribs)');
      expect(again.candidates.first.rule.itemId, plastic.rule.itemId);
    });

    test('not for different labels', () async {
      final signals = PhotoSignals(labels: const [PhotoLabel('Umbrella', 0.9)]);
      final first = (await matcher.match('14100', signals)).candidates.first;
      await matcher.remember('14100', signals, first.rule.itemId);
      final other = await matcher.match(
        '14100',
        PhotoSignals(
          labels: const [PhotoLabel('Umbrella', 0.9), PhotoLabel('Bag', 0.7)],
        ),
      );
      expect(other.answer?.source, isNot(PhotoAnswerSource.remembered));
    });

    test('nothing is remembered without confident labels or marks', () async {
      final signals = PhotoSignals(labels: const [PhotoLabel('Cup', 0.55)]);
      expect(signals.key, isEmpty);
      await matcher.remember('14100', signals, 'yokohama-1');
      expect(await db.select(db.photoChoices).get(), isEmpty);
    });
  });

  test('the API gets label names and marks, never the text', () {
    final signals = PhotoSignals(
      labels: const [PhotoLabel('Bottle', 0.8)],
      text: '山田太郎様\nPET',
    );
    expect(signals.logLabels, ['mark:pet', 'Bottle']);
  });
}
