import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../data/bundle_sync.dart' show cdnBaseUrl;
import 'boundary_package.dart';

/// Boundary package schema versions this app can read.
const supportedBoundarySchemas = {1};

/// A boundary package listed in the manifest.
class BoundaryRef {
  const BoundaryRef({
    required this.prefectureCode,
    required this.version,
    required this.path,
    required this.bbox,
    required this.sha256,
    required this.sizeBytes,
  });

  factory BoundaryRef.fromJson(Map<String, dynamic> json) => BoundaryRef(
    prefectureCode: json['prefecture_code'] as String,
    version: json['version'] as int,
    path: json['path'] as String,
    bbox: [
      for (final v in json['bbox'] as List<dynamic>) (v as num).toDouble(),
    ],
    sha256: json['sha256'] as String,
    sizeBytes: json['size_bytes'] as int,
  );

  final String prefectureCode;
  final int version;
  final String path;
  final List<double> bbox;
  final String sha256;
  final int sizeBytes;

  bool covers(double lat, double lon) =>
      bbox[0] <= lon && lon <= bbox[2] && bbox[1] <= lat && lat <= bbox[3];
}

class BoundaryException implements Exception {
  BoundaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The result of looking a position up in the downloaded boundaries.
class BoundaryLookup {
  const BoundaryLookup({required this.areas, required this.municipalities});

  /// The containing area first, then those within 50 m.
  final List<AreaMatch> areas;

  /// Japanese names of the package's municipalities and wards, by code.
  final Map<String, String> municipalities;
}

/// Downloads the boundary package for where the user is, keeps it on the
/// device, and looks positions up in it.
///
/// The manifest's list of packages is cached next to the packages, so a
/// lookup works offline once a package has been downloaded. Positions are
/// only ever passed through; nothing here stores or sends them.
class BoundaryStore {
  BoundaryStore({
    required this.client,
    required this.directory,
    String baseUrl = cdnBaseUrl,
    this.timeout = const Duration(seconds: 60),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl;

  final http.Client client;

  /// Where packages and the cached index live.
  final Future<Directory> Function() directory;
  final String baseUrl;
  final Duration timeout;

  Future<File> _indexFile() async =>
      File('${(await directory()).path}/boundaries/index.json');

  Future<File> _packageFile(BoundaryRef ref) async => File(
    '${(await directory()).path}/boundaries/${ref.prefectureCode}-${ref.version}.json',
  );

  /// The manifest's boundary packages, from the network or, offline, from
  /// the copy saved last time.
  Future<List<BoundaryRef>> _refs() async {
    final file = await _indexFile();
    List<dynamic> refs;
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/manifest.json'))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw BoundaryException(
          'manifest returned HTTP ${response.statusCode}',
        );
      }
      final manifest =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      refs = manifest['boundaries'] as List<dynamic>? ?? const [];
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(refs));
    } on Exception catch (e) {
      if (!await file.exists()) {
        throw BoundaryException('no boundary index and no network: $e');
      }
      refs = jsonDecode(await file.readAsString()) as List<dynamic>;
    }
    return [
      for (final r in refs.cast<Map<String, dynamic>>())
        if (supportedBoundarySchemas.contains(r['schema_version']))
          BoundaryRef.fromJson(r),
    ];
  }

  /// The package file for [ref], downloading and verifying it if it is not
  /// on the device yet. Older versions of the same prefecture are removed.
  Future<File> _ensure(BoundaryRef ref, void Function()? onDownload) async {
    final file = await _packageFile(ref);
    if (await file.exists() && await file.length() == ref.sizeBytes) {
      return file;
    }
    onDownload?.call();
    final response = await client
        .get(Uri.parse('$baseUrl${ref.path}'))
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw BoundaryException(
        '${ref.path} returned HTTP ${response.statusCode}',
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.length != ref.sizeBytes ||
        sha256.convert(bytes).toString() != ref.sha256) {
      throw BoundaryException('boundary package does not match the manifest');
    }
    await file.parent.create(recursive: true);
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
    await for (final old in file.parent.list()) {
      final name = old.uri.pathSegments.last;
      if (old is File &&
          name.startsWith('${ref.prefectureCode}-') &&
          old.path != file.path) {
        await old.delete();
      }
    }
    return file;
  }

  /// Looks ([lat], [lon]) up: the package covering it is downloaded if
  /// needed, then decoded and searched off the UI thread. Returns null when
  /// no published package covers the position. [onDownload] is called
  /// before a package is downloaded, so the screen can say why it waits.
  Future<BoundaryLookup?> lookup(
    double lat,
    double lon, {
    void Function()? onDownload,
  }) async {
    final refs = await _refs();
    final ref = refs.where((r) => r.covers(lat, lon)).firstOrNull;
    if (ref == null) return null;
    final file = await _ensure(ref, onDownload);
    final path = file.path;
    final (areas, municipalities) = await Isolate.run(() {
      final package = BoundaryPackage.fromJson(
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
      );
      return (package.locate(lat, lon).candidates, package.municipalities);
    });
    return BoundaryLookup(areas: areas, municipalities: municipalities);
  }
}
