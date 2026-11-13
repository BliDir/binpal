import 'dart:convert';
import 'dart:io';

import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The example bundle from the schema folder, as the CDN would serve it.
Map<String, dynamic> exampleBundle({int version = 1}) {
  final file = File('../data/schema/examples/bundles/14100/1.json');
  final bundle = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return bundle..['bundle_version'] = version;
}

/// A fake CDN: a manifest and bundle files, with every request recorded.
class FakeCdn {
  final files = <String, List<int>>{};
  final requests = <String>[];
  final entries = <Map<String, dynamic>>[];
  int manifestStatus = 200;

  /// Publishes [bundle] and lists it in the manifest. [corrupt] changes the
  /// served bytes after the manifest entry is written.
  void publish(
    Map<String, dynamic> bundle, {
    List<int> Function(List<int>)? corrupt,
    int schemaVersion = 1,
    String? path,
  }) {
    final mid =
        (bundle['municipality'] as Map<String, dynamic>)['id'] as String;
    final version = bundle['bundle_version'] as int;
    final bytes = utf8.encode(jsonEncode(bundle));
    final filePath = path ?? '/bundles/$mid/$version.json';
    files[filePath] = corrupt == null ? bytes : corrupt(bytes);
    final ref = {
      'schema_version': schemaVersion,
      'bundle_version': version,
      'path': filePath,
      'sha256': sha256.convert(bytes).toString(),
      'size_bytes': bytes.length,
      'published_at': '2026-11-12T10:00:00+09:00',
    };
    final entry = entries.where((e) => e['id'] == mid).firstOrNull;
    if (entry == null) {
      entries.add({
        'id': mid,
        'names': (bundle['municipality'] as Map<String, dynamic>)['names'],
        'area_ids': [
          for (final a in bundle['areas'] as List<dynamic>)
            (a as Map<String, dynamic>)['id'],
        ],
        'bundles': [ref],
      });
    } else {
      final refs = (entry['bundles'] as List<dynamic>)
        ..removeWhere((r) => (r as Map)['schema_version'] == schemaVersion)
        ..add(ref);
      refs.sort(
        (a, b) => ((b as Map)['schema_version'] as int).compareTo(
          (a as Map)['schema_version'] as int,
        ),
      );
    }
  }

  http.Client get client => MockClient((request) async {
    requests.add(request.url.path);
    if (request.url.path == '/manifest.json') {
      final manifest = {
        'schema_version': 1,
        'generated_at': '2026-11-12T10:00:00+09:00',
        'municipalities': entries,
      };
      return http.Response.bytes(
        utf8.encode(jsonEncode(manifest)),
        manifestStatus,
      );
    }
    final bytes = files[request.url.path];
    return bytes == null
        ? http.Response('', 404)
        : http.Response.bytes(bytes, 200);
  });
}

/// A second municipality made from the example, so "only mine" can be tested.
Map<String, dynamic> otherMunicipality() {
  final bundle = exampleBundle();
  (bundle['municipality'] as Map<String, dynamic>)['id'] = '13112';
  bundle.remove('wards');
  for (final a in bundle['areas'] as List<dynamic>) {
    final area = a as Map<String, dynamic>;
    area['id'] = '13112-${(area['id'] as String).split('-')[1]}';
    area.remove('ward_id');
  }
  for (final c in bundle['calendars'] as List<dynamic>) {
    final calendar = c as Map<String, dynamic>;
    calendar['area_ids'] = [
      for (final id in calendar['area_ids'] as List<dynamic>)
        '13112-${(id as String).split('-')[1]}',
    ];
  }
  bundle['exceptions'] = <dynamic>[];
  return bundle;
}

void main() {
  late AppDatabase db;
  late FakeCdn cdn;
  late BundleSync sync;
  var now = DateTime.utc(2026, 11, 12, 1);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cdn = FakeCdn();
    now = DateTime.utc(2026, 11, 12, 1);
    sync = BundleSync(
      db: db,
      client: cdn.client,
      baseUrl: 'https://cdn.test/',
      now: () => now,
    );
  });
  tearDown(() => db.close());

  Future<int> count(TableInfo<Table, Object?> table) async =>
      (await db.select(table).get()).length;

  Future<String> umbrellaInstructions() async {
    final rule = await (db.select(
      db.rules,
    )..where((r) => r.itemId.equals('umbrella'))).getSingle();
    return rule.instructionsEn;
  }

  test('first sync downloads, verifies and imports the bundle', () async {
    cdn.publish(exampleBundle());

    final result = await sync.sync('14100');

    expect(result.outcome, SyncOutcome.updated);
    expect(result.bundleVersion, 1);
    expect(cdn.requests, ['/manifest.json', '/bundles/14100/1.json']);

    final stored = (await db.bundleFor('14100'))!;
    expect(stored.bundleVersion, 1);
    expect(stored.nameEn, 'Yokohama City');
    expect(jsonDecode(stored.attribution), isA<List<dynamic>>());

    final bundle = exampleBundle();
    expect(await count(db.wards), (bundle['wards'] as List).length);
    expect(await count(db.areas), (bundle['areas'] as List).length);
    expect(await count(db.categories), (bundle['categories'] as List).length);
    expect(await count(db.rules), (bundle['rules'] as List).length);
    expect(await count(db.calendars), (bundle['calendars'] as List).length);
    expect(
      await count(db.collectionExceptions),
      (bundle['exceptions'] as List).length,
    );

    final area = await (db.select(
      db.areas,
    )..where((a) => a.id.equals('14117-001001'))).getSingle();
    expect(area.wardId, '14117');
    expect(area.nameEn, 'Aobadai 1-chome');
    expect(area.chome, 1);

    final umbrella = await (db.select(
      db.rules,
    )..where((r) => r.itemId.equals('umbrella'))).getSingle();
    expect(umbrella.nameJa, '傘');
    expect(umbrella.category, 'kinzoku');
    final aliases = await (db.select(
      db.aliases,
    )..where((a) => a.ruleId.equals(umbrella.id))).get();
    expect(aliases.map((a) => a.alias), containsAll(['かさ', 'parasol']));

    final calendarAreas = await (db.select(
      db.calendarAreas,
    )..where((c) => c.areaId.equals('14117-001001'))).get();
    expect(calendarAreas, hasLength(3));
    final calendar = await (db.select(
      db.calendars,
    )..where((c) => c.id.equals('aobadai-1-2-moyasu'))).getSingle();
    expect(jsonDecode(calendar.pattern), {
      'type': 'weekly',
      'weekdays': ['tue', 'sat'],
    });
    expect(calendar.putOutBy, '08:00');
  });

  test('the same version is not downloaded again', () async {
    cdn.publish(exampleBundle());
    await sync.sync('14100');
    cdn.requests.clear();

    final result = await sync.sync('14100');

    expect(result.outcome, SyncOutcome.upToDate);
    expect(cdn.requests, ['/manifest.json']);
  });

  test('a new version replaces the old data', () async {
    cdn.publish(exampleBundle());
    await sync.sync('14100');
    final rulesBefore = await count(db.rules);

    final next = exampleBundle(version: 2);
    final rules = (next['rules'] as List<dynamic>).cast<Map<String, dynamic>>();
    (rules.firstWhere((r) => r['item_id'] == 'umbrella')['instructions']
            as Map<String, dynamic>)['en'] =
        'Tie it shut first.';
    cdn.publish(next);

    final result = await sync.sync('14100');

    expect(result.outcome, SyncOutcome.updated);
    expect((await db.bundleFor('14100'))!.bundleVersion, 2);
    expect(await umbrellaInstructions(), 'Tie it shut first.');
    expect(await count(db.rules), rulesBefore);
    // No aliases left behind from the replaced rules.
    final orphans = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM aliases '
          'WHERE rule_id NOT IN (SELECT id FROM rules)',
        )
        .getSingle();
    expect(orphans.read<int>('n'), 0);
  });

  group('a bad download leaves the stored data intact:', () {
    late String before;

    setUp(() async {
      cdn.publish(exampleBundle());
      await sync.sync('14100');
      before = await umbrellaInstructions();
    });

    Future<void> expectUnchanged(SyncResult result, String reason) async {
      expect(result.outcome, SyncOutcome.failed);
      expect(result.error, contains(reason));
      expect((await db.bundleFor('14100'))!.bundleVersion, 1);
      expect(await umbrellaInstructions(), before);
      expect(await count(db.areas), 4);
    }

    test('corrupted bytes', () async {
      cdn.publish(
        exampleBundle(version: 2),
        corrupt: (bytes) => [...bytes]..[bytes.length ~/ 2] ^= 0x01,
      );
      await expectUnchanged(await sync.sync('14100'), 'checksum');
    });

    test('truncated file', () async {
      cdn.publish(
        exampleBundle(version: 2),
        corrupt: (bytes) => bytes.sublist(0, bytes.length - 100),
      );
      await expectUnchanged(await sync.sync('14100'), 'bytes');
    });

    test('bundle file missing', () async {
      cdn.publish(exampleBundle(version: 2));
      cdn.files.remove('/bundles/14100/2.json');
      await expectUnchanged(await sync.sync('14100'), 'HTTP 404');
    });

    test('manifest unavailable', () async {
      cdn.manifestStatus = 503;
      await expectUnchanged(await sync.sync('14100'), 'HTTP 503');
    });

    test('a bundle that fails half way through the import', () async {
      final broken = exampleBundle(version: 2);
      // Valid areas and categories, then a rule with no instructions: the
      // import has already deleted and re-inserted rows when it hits this.
      ((broken['rules'] as List<dynamic>).last as Map<String, dynamic>).remove(
        'instructions',
      );
      cdn.publish(broken);
      await expectUnchanged(await sync.sync('14100'), 'unexpected data');
    });

    test('a file that is a different version than the manifest says', () async {
      cdn.publish(exampleBundle(version: 3), path: '/bundles/14100/2.json');
      (cdn.entries.single['bundles'] as List<dynamic>)
              .cast<Map>()
              .single['bundle_version'] =
          2;
      await expectUnchanged(await sync.sync('14100'), 'does not match');
    });

    test('the network throwing', () async {
      final offline = BundleSync(
        db: db,
        client: MockClient((_) => throw const SocketException('offline')),
        now: () => now,
      );
      await expectUnchanged(await offline.sync('14100'), 'offline');
    });
  });

  test("only the user's municipality is downloaded", () async {
    cdn.publish(exampleBundle());
    cdn.publish(otherMunicipality());

    await sync.sync('14100');

    expect(cdn.requests, ['/manifest.json', '/bundles/14100/1.json']);
    expect(await db.bundleFor('13112'), isNull);
    final others = await (db.select(
      db.rules,
    )..where((r) => r.municipalityId.equals('13112'))).get();
    expect(others, isEmpty);
  });

  test('importing one municipality leaves another alone', () async {
    cdn.publish(exampleBundle());
    cdn.publish(otherMunicipality());
    await sync.sync('13112');
    await sync.sync('14100');
    cdn.publish(exampleBundle(version: 2));
    await sync.sync('14100');

    expect((await db.bundleFor('13112'))!.bundleVersion, 1);
    expect((await db.bundleFor('14100'))!.bundleVersion, 2);
    final rules = await db.select(db.rules).get();
    expect(rules.where((r) => r.municipalityId == '13112'), isNotEmpty);
    expect(rules.map((r) => r.id).toSet(), hasLength(rules.length));
  });

  test(
    'a municipality not in the manifest is reported as not covered',
    () async {
      cdn.publish(exampleBundle());
      final result = await sync.sync('27100');
      expect(result.outcome, SyncOutcome.notCovered);
      expect(cdn.requests, ['/manifest.json']);
    },
  );

  test('a newer schema is skipped in favour of one the app can read', () async {
    cdn.publish(exampleBundle());
    cdn.publish(
      exampleBundle(),
      schemaVersion: 2,
      path: '/bundles/14100/v2/1.json',
    );
    expect(
      (cdn.entries.single['bundles'] as List<dynamic>).cast<Map>().map(
        (r) => r['schema_version'],
      ),
      [2, 1],
    );

    final result = await sync.sync('14100');

    expect(result.outcome, SyncOutcome.updated);
    expect(cdn.requests.last, '/bundles/14100/1.json');
  });

  test('only a schema the app cannot read means not covered', () async {
    cdn.publish(
      exampleBundle(),
      schemaVersion: 2,
      path: '/bundles/14100/v2/1.json',
    );
    expect((await sync.sync('14100')).outcome, SyncOutcome.notCovered);
    expect(cdn.requests, ['/manifest.json']);
  });

  test(
    'syncIfDue checks at most every six hours once data is stored',
    () async {
      cdn.publish(exampleBundle());
      expect((await sync.syncIfDue('14100'))!.outcome, SyncOutcome.updated);

      now = now.add(const Duration(hours: 5));
      expect(await sync.syncIfDue('14100'), isNull);

      now = now.add(const Duration(hours: 2));
      expect((await sync.syncIfDue('14100'))!.outcome, SyncOutcome.upToDate);
    },
  );

  test('syncIfDue keeps trying while nothing is stored', () async {
    cdn.manifestStatus = 503;
    expect((await sync.syncIfDue('14100'))!.outcome, SyncOutcome.failed);
    cdn.manifestStatus = 200;
    cdn.publish(exampleBundle());
    expect((await sync.syncIfDue('14100'))!.outcome, SyncOutcome.updated);
  });

  test('the real Yokohama bundle imports', () async {
    final file = File('../data/municipalities/14100/bundle.json');
    final bundle = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    cdn.publish(bundle);

    final watch = Stopwatch()..start();
    final result = await sync.sync('14100');
    watch.stop();

    expect(result.outcome, SyncOutcome.updated);
    expect(await count(db.rules), (bundle['rules'] as List).length);
    expect(await count(db.areas), (bundle['areas'] as List).length);
    expect(await count(db.calendars), (bundle['calendars'] as List).length);
    expect(await count(db.aliases), greaterThan(500));
    // Generous: the point is to notice an import that became pathological.
    expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
  });
}
