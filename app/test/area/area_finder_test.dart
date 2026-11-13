import 'dart:convert';
import 'dart:io';

import 'package:binpal/app/services.dart';
import 'package:binpal/area/area_finder.dart';
import 'package:binpal/area/boundary_store.dart';
import 'package:binpal/area/location_source.dart';
import 'package:binpal/data/database.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/services.dart';

/// [findArea] against the published Kanagawa boundary package and Yokohama
/// bundle, served by a fake CDN.
void main() {
  final package = File('../data/boundaries/14.json').readAsBytesSync();
  final bundle = jsonDecode(
    File('../data/municipalities/14100/bundle.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final manifest = jsonEncode({
    'boundaries': [
      {
        'prefecture_code': '14',
        'schema_version': 1,
        'version': 1,
        'path': '/boundaries/14/1.json',
        'bbox': [138.915472, 35.128712, 139.796502, 35.673035],
        'sha256': sha256.convert(package).toString(),
        'size_bytes': package.length,
      },
    ],
  });

  late Directory dir;
  late List<Uri> requests;
  late bool online;
  late FakeLocationSource location;
  late AppServices services;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('binpal-boundaries');
    requests = [];
    online = true;
    location = FakeLocationSource.denied();
    final client = MockClient((request) async {
      requests.add(request.url);
      if (!online) throw const SocketException('offline');
      return switch (request.url.path) {
        '/manifest.json' => http.Response(manifest, 200),
        '/boundaries/14/1.json' => http.Response.bytes(package, 200),
        _ => http.Response('', 404),
      };
    });
    final db = AppDatabase(NativeDatabase.memory());
    await db.importBundle(bundle, sha256: 'x');
    services = testServices(
      db: db,
      location: location,
      boundaries: BoundaryStore(
        client: client,
        directory: () async => dir,
        baseUrl: 'https://cdn.test',
      ),
    );
    services.sync.bundle = await db.bundleFor('14100');
  });

  tearDown(() async {
    await services.db.close();
    await dir.delete(recursive: true);
  });

  Future<FindResult> findAt(double lat, double lon) {
    location.result = LocationResult.position(lat, lon);
    return findArea(services);
  }

  List<String> ids(FindResult result) => [
    for (final a in (result as FoundAreas).areas) a.id,
  ];

  test('at home: the one area there, with its ward', () async {
    // 横浜市青葉区市ケ尾町31-4, 167 m from the nearest boundary.
    final result = await findAt(35.553493, 139.536621);
    expect(ids(result), ['14117-088001']);
    final found = result as FoundAreas;
    expect(found.areas.single.nameJa, '市ケ尾町');
    expect(found.wards['14117']?.nameEn, 'Aoba Ward');
  });

  test('near a boundary: the area there first, then the neighbour', () async {
    // あざみ野二丁目, 48 m from あざみ野一丁目.
    final result = await findAt(35.568253, 139.553345);
    expect(ids(result), ['14117-123002', '14117-123001']);
  });

  test('permission denied: no lookup at all', () async {
    location.result = const LocationResult.problem(LocationProblem.denied);
    final result = await findArea(services);
    expect(result, isA<NoLocation>());
    expect((result as NoLocation).problem, LocationProblem.denied);
    expect(requests, isEmpty);
  });

  test('a covered prefecture but no bundle there names the place', () async {
    // Kawasaki Station.
    final result = await findAt(35.530870, 139.697030);
    expect(result, isA<NotCovered>());
    expect((result as NotCovered).place, '川崎市川崎区');
  });

  test('outside every boundary package', () async {
    // Tokyo Station.
    final result = await findAt(35.681236, 139.767125);
    expect(result, isA<NotCovered>());
    expect((result as NotCovered).place, isNull);
  });

  test('works offline once the package is downloaded', () async {
    await findAt(35.553493, 139.536621);
    online = false;
    final result = await findAt(35.568253, 139.553345);
    expect(ids(result), ['14117-123002', '14117-123001']);
  });

  test('offline before any download: the map fails', () async {
    online = false;
    expect(await findAt(35.553493, 139.536621), isA<MapFailed>());
  });

  test('a download that does not match the manifest is refused', () async {
    final tampered = BoundaryStore(
      client: MockClient(
        (request) async => request.url.path == '/manifest.json'
            ? http.Response(manifest, 200)
            : http.Response.bytes([
                ...package.take(package.length - 1),
                32,
              ], 200),
      ),
      directory: () async => dir,
      baseUrl: 'https://cdn.test',
    );
    await expectLater(
      tampered.lookup(35.553493, 139.536621),
      throwsA(isA<BoundaryException>()),
    );
  });

  test('the position is never stored or sent', () async {
    const lat = 35.553493, lon = 139.536621;
    final result = await findAt(lat, lon);
    await services.chooseArea((result as FoundAreas).areas.single);

    // The network only ever sees the manifest and the package path.
    expect(
      {for (final u in requests) u.path},
      {'/manifest.json', '/boundaries/14/1.json'},
    );
    for (final u in requests) {
      expect(u.hasQuery, isFalse);
    }

    // On the device: the cached index and the package, and in settings only
    // the area and its municipality.
    final files = [
      for (final f in dir.listSync(recursive: true))
        if (f is File) f.uri.pathSegments.last,
    ]..sort();
    expect(files, ['14-1.json', 'index.json']);
    final settings = await services.db.select(services.db.settings).get();
    expect(
      {for (final s in settings) s.key: s.value},
      {'municipality_id': '14100', 'area_id': '14117-088001'},
    );
    final written = File('${dir.path}/boundaries/index.json')
        .readAsStringSync();
    for (final digits in ['35.5534', '139.5366']) {
      expect(written, isNot(contains(digits)));
    }
  });
}
