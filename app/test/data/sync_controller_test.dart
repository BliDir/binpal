import 'dart:convert';
import 'dart:io';

import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  var online = true;
  final requests = <String>[];

  final bundleBytes = File('../data/schema/examples/bundles/14100/1.json')
      .readAsBytesSync();
  final manifest = jsonEncode({
    'schema_version': 1,
    'generated_at': '2026-11-12T10:00:00+09:00',
    'municipalities': [
      {
        'id': '14100',
        'bundles': [
          {
            'schema_version': 1,
            'bundle_version': 1,
            'path': '/bundles/14100/1.json',
            'sha256': sha256.convert(bundleBytes).toString(),
            'size_bytes': bundleBytes.length,
          },
        ],
      },
    ],
  });

  SyncController controller() => SyncController(
    db: db,
    sync: BundleSync(
      db: db,
      client: MockClient((request) async {
        requests.add(request.url.path);
        if (!online) throw const SocketException('offline');
        return request.url.path == '/manifest.json'
            ? http.Response(manifest, 200)
            : http.Response.bytes(bundleBytes, 200);
      }),
    ),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    online = true;
    requests.clear();
  });
  tearDown(() => db.close());

  test('downloads the launch municipality and reports it', () async {
    final sync = controller();
    var notified = 0;
    sync.addListener(() => notified++);

    await sync.refresh();

    expect(sync.bundle?.municipalityId, launchMunicipalityId);
    expect(sync.bundle?.bundleVersion, 1);
    expect(sync.lastResult?.outcome, SyncOutcome.updated);
    expect(sync.syncing, isFalse);
    expect(notified, greaterThanOrEqualTo(2));
  });

  test(
    'offline with nothing stored reports the failure, then recovers',
    () async {
      final sync = controller();
      online = false;
      await sync.refresh();
      expect(sync.bundle, isNull);
      expect(sync.lastResult?.outcome, SyncOutcome.failed);

      online = true;
      await sync.refresh();
      expect(sync.bundle?.bundleVersion, 1);
    },
  );

  test('offline with data stored keeps showing that data', () async {
    await controller().refresh();
    online = false;

    final relaunched = controller();
    await relaunched.refresh(force: true);

    expect(relaunched.bundle?.bundleVersion, 1);
    expect(relaunched.lastResult?.outcome, SyncOutcome.failed);
    expect(await db.select(db.rules).get(), isNotEmpty);
  });

  test('a second launch soon after does not hit the network', () async {
    await controller().refresh();
    requests.clear();

    final relaunched = controller();
    await relaunched.refresh();

    expect(requests, isEmpty);
    expect(relaunched.bundle?.bundleVersion, 1);
    expect(relaunched.lastResult, isNull);
  });

  test('uses the municipality chosen in settings once there is one', () async {
    await db.setSetting(municipalitySettingKey, '13112');
    final sync = controller();
    await sync.refresh();
    expect(sync.lastResult?.outcome, SyncOutcome.notCovered);
    expect(sync.bundle, isNull);
    expect(requests, ['/manifest.json']);
  });
}
