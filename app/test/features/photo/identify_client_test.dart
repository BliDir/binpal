import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:binpal/data/database.dart';
import 'package:binpal/data/thin_api.dart';
import 'package:binpal/features/photo/identify_client.dart';
import 'package:binpal/features/search/item_search.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  late List<SearchHit> candidates;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.importBundle(
      jsonDecode(
        File('../data/schema/examples/bundles/14100/1.json').readAsStringSync(),
      ) as Map<String, dynamic>,
      sha256: 'x',
    );
    candidates = await ItemSearch(db)
        .search('14100', 'umbrella', now: DateTime.utc(2026, 11, 15));
  });
  tearDown(() => db.close());

  IdentifyClient client(Future<http.Response> Function(http.Request) handler) =>
      IdentifyClient(
        db: db,
        client: MockClient(handler),
        baseUrl: 'https://api.test/',
      );

  test(
    'sends the photo, area, candidates and labels, and nothing else',
    () async {
      late http.Request sent;
      final result =
          await client((request) async {
            sent = request;
            return http.Response(
              jsonEncode({
                'answer': {
                  'item_id': 'umbrella',
                  'category': 'kinzoku',
                  'confidence': 0.82,
                },
                'cached': false,
              }),
              200,
            );
          }).identify(
            areaId: '14117-001001',
            jpeg: jpeg,
            candidates: candidates,
            labels: ['mark:pet', 'Umbrella'],
          );

      expect(sent.url.toString(), 'https://api.test/v1/identify');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {
        'install_id',
        'area_id',
        'image',
        'candidates',
        'labels',
      });
      expect(body['area_id'], '14117-001001');
      expect(base64Decode(body['image'] as String), jpeg);
      expect(body['candidates'], [
        {
          'item_id': 'umbrella',
          'name_ja': candidates.first.rule.nameJa,
          'name_en': 'Umbrella',
          'category': 'kinzoku',
        },
      ]);
      expect(body['labels'], ['mark:pet', 'Umbrella']);

      expect(result, isA<AiAnswer>());
      final answer = result as AiAnswer;
      expect(answer.itemId, 'umbrella');
      expect(answer.categoryId, 'kinzoku');
      expect(answer.confidence, 0.82);
      expect(answer.cached, isFalse);
    },
  );

  test('the install id is a random UUID, made once and kept', () async {
    final ids = <String>[];
    final c = client((request) async {
      ids.add((jsonDecode(request.body) as Map)['install_id'] as String);
      return http.Response('{"answer": null, "cached": false}', 200);
    });
    for (var i = 0; i < 2; i++) {
      await c.identify(
        areaId: '14117-001001',
        jpeg: jpeg,
        candidates: candidates,
        labels: const [],
      );
    }
    expect(ids[0], ids[1]);
    expect(
      ids[0],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(await db.setting(installIdSettingKey), ids[0]);
  });

  test('a category without an item', () async {
    final result =
        await client(
          (_) async => http.Response(
            '{"answer": {"item_id": null, "category": "moyasu", "confidence": 0.6}, "cached": true}',
            200,
          ),
        ).identify(
          areaId: '14117-001001',
          jpeg: jpeg,
          candidates: candidates,
          labels: const [],
        );
    expect((result as AiAnswer).itemId, isNull);
    expect(result.categoryId, 'moyasu');
    expect(result.cached, isTrue);
  });

  Future<AiProblem?> problemFor(
    Future<http.Response> Function(http.Request) handler,
  ) async {
    final result = await client(handler).identify(
      areaId: '14117-001001',
      jpeg: jpeg,
      candidates: candidates,
      labels: const [],
    );
    return result is AiUnavailable ? result.problem : null;
  }

  test('says why there is no answer', () async {
    expect(
      await problemFor((_) async => http.Response('{"answer": null}', 200)),
      AiProblem.noAnswer,
    );
    expect(
      await problemFor(
        (_) async => http.Response('{"error": "ai_paused"}', 503),
      ),
      AiProblem.paused,
    );
    expect(
      await problemFor(
        (_) async => http.Response('{"error": "daily_limit"}', 429),
      ),
      AiProblem.paused,
    );
    expect(
      await problemFor(
        (_) async => http.Response('{"error": "upstream_failed"}', 502),
      ),
      AiProblem.failed,
    );
    expect(
      await problemFor((_) async => http.Response('not json', 200)),
      AiProblem.failed,
    );
    expect(
      await problemFor((_) async => throw http.ClientException('no network')),
      AiProblem.offline,
    );
  });

  test('no request without candidates to choose from', () async {
    var called = false;
    final result =
        await client((_) async {
          called = true;
          return http.Response('', 500);
        }).identify(
          areaId: '14117-001001',
          jpeg: jpeg,
          candidates: const [],
          labels: const [],
        );
    expect(called, isFalse);
    expect((result as AiUnavailable).problem, AiProblem.noAnswer);
  });
}
