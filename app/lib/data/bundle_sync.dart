import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'database.dart';

/// Where the manifest and bundles are served from. Override at build time
/// with `--dart-define=CDN_BASE_URL=…`.
const cdnBaseUrl = String.fromEnvironment(
  'CDN_BASE_URL',
  defaultValue: 'https://data.blidir.fun',
);

/// Bundle schema versions this app can read.
const supportedBundleSchemas = {1};

/// When the stored bundle was last confirmed current against the CDN.
const lastCheckedSettingKey = 'sync.last_checked_at';

enum SyncOutcome {
  /// The stored bundle is already the one the manifest lists.
  upToDate,

  /// A new bundle was downloaded, verified and imported.
  updated,

  /// The manifest has no bundle this app can read for the municipality.
  notCovered,

  /// The check or the download failed. Stored data is unchanged.
  failed,
}

class SyncResult {
  const SyncResult(this.outcome, {this.bundleVersion, this.error});

  final SyncOutcome outcome;
  final int? bundleVersion;
  final String? error;

  @override
  String toString() =>
      'SyncResult(${outcome.name}, version: $bundleVersion, error: $error)';
}

class _SyncFailure implements Exception {
  _SyncFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Keeps one municipality's bundle in the local database in step with the CDN.
///
/// Only that municipality's bundle is ever downloaded. A bundle replaces the
/// stored one only after its size and SHA-256 match the manifest and it has
/// imported completely; any failure leaves the stored data as it was.
class BundleSync {
  BundleSync({
    required this.db,
    required this.client,
    String baseUrl = cdnBaseUrl,
    DateTime Function()? now,
    this.manifestTimeout = const Duration(seconds: 20),
    this.bundleTimeout = const Duration(seconds: 90),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _now = now ?? DateTime.now;

  final AppDatabase db;
  final http.Client client;
  final String baseUrl;
  final Duration manifestTimeout;
  final Duration bundleTimeout;
  final DateTime Function() _now;

  /// Checks the manifest and downloads the municipality's bundle if its
  /// version differs from the stored one. Never throws.
  Future<SyncResult> sync(String municipalityId) async {
    try {
      final result = await _sync(municipalityId);
      await db.setSetting(
        lastCheckedSettingKey,
        _now().toUtc().toIso8601String(),
      );
      return result;
    } on _SyncFailure catch (e) {
      return SyncResult(SyncOutcome.failed, error: e.message);
    } on TimeoutException {
      return const SyncResult(SyncOutcome.failed, error: 'timed out');
    } on Exception catch (e) {
      // Network errors, malformed JSON, a bundle that does not import.
      return SyncResult(SyncOutcome.failed, error: e.toString());
    } on TypeError catch (e) {
      // A manifest or bundle whose fields are not the expected types.
      return SyncResult(SyncOutcome.failed, error: 'unexpected data: $e');
    }
  }

  /// [sync], unless the last successful check was less than [every] ago.
  Future<SyncResult?> syncIfDue(
    String municipalityId, {
    Duration every = const Duration(hours: 6),
  }) async {
    final last = DateTime.tryParse(
      await db.setting(lastCheckedSettingKey) ?? '',
    );
    final stored = await db.bundleFor(municipalityId);
    if (stored != null && last != null && _now().difference(last) < every) {
      return null;
    }
    return sync(municipalityId);
  }

  Future<SyncResult> _sync(String municipalityId) async {
    final manifest = jsonDecode(
      utf8.decode(await _get('/manifest.json', manifestTimeout)),
    ) as Map<String, dynamic>;
    final entry = (manifest['municipalities'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((m) => m['id'] == municipalityId)
        .firstOrNull;
    // Bundles are listed highest schema first; take the first one we can read.
    final ref = (entry?['bundles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((b) => supportedBundleSchemas.contains(b['schema_version']))
        .firstOrNull;
    if (ref == null) return const SyncResult(SyncOutcome.notCovered);

    final version = ref['bundle_version'] as int;
    final expectedSha = ref['sha256'] as String;
    final stored = await db.bundleFor(municipalityId);
    if (stored != null &&
        stored.bundleVersion == version &&
        stored.sha256 == expectedSha) {
      return SyncResult(SyncOutcome.upToDate, bundleVersion: version);
    }

    final bytes = await _get(ref['path'] as String, bundleTimeout);
    if (bytes.length != ref['size_bytes']) {
      throw _SyncFailure(
        'bundle is ${bytes.length} bytes, manifest says ${ref['size_bytes']}',
      );
    }
    // Hashing and parsing a megabyte or two is kept off the UI thread.
    final bundle = await Isolate.run(() {
      if (sha256.convert(bytes).toString() != expectedSha) return null;
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    });
    if (bundle == null) throw _SyncFailure('bundle checksum does not match');
    if (!supportedBundleSchemas.contains(bundle['schema_version']) ||
        bundle['bundle_version'] != version ||
        (bundle['municipality'] as Map<String, dynamic>)['id'] !=
            municipalityId) {
      throw _SyncFailure('bundle does not match its manifest entry');
    }

    await db.importBundle(bundle, sha256: expectedSha, importedAt: _now());
    return SyncResult(SyncOutcome.updated, bundleVersion: version);
  }

  Future<List<int>> _get(String path, Duration timeout) async {
    final response = await client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw _SyncFailure('$path returned HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
