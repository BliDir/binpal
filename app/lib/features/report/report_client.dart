import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/database.dart';
import '../../data/thin_api.dart';

/// What a "this looks wrong" report is about. The API files each in the
/// review queue, where reviewers check it against the official source.
enum ReportKind {
  /// An item is in the wrong category.
  wrongCategory('wrong_category'),

  /// An item's instructions are wrong.
  wrongInstructions('wrong_instructions'),

  /// The area's collections on a date are wrong.
  wrongDay('wrong_day'),

  /// Search doesn't have an item.
  missingItem('missing_item'),
  other('other');

  const ReportKind(this.code);

  /// The API's name for it.
  final String code;
}

enum ReportResult {
  sent,

  /// No connection, or no reply in time. Nothing was sent.
  offline,

  /// Too many reports from this install today.
  limited,
  failed,
}

/// Sends "this looks wrong" reports to the thin API, which files them in
/// the public review queue. A report carries the area id, the item or date,
/// the kind, the optional comment and the app version: no location, and
/// the random install id only counts the daily limit.
class ReportClient {
  ReportClient({
    required this.db,
    required this.client,
    String baseUrl = apiBaseUrl,
    Future<String?> Function()? appVersion,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       appVersion = appVersion ?? _packageVersion;

  final AppDatabase db;
  final http.Client client;
  final String baseUrl;
  final Future<String?> Function() appVersion;
  final Duration timeout;

  /// The API's limit on comments.
  static const maxNoteLength = 500;

  Future<ReportResult> send({
    required String areaId,
    required ReportKind kind,
    String? itemId,
    String? date,
    String? note,
  }) async {
    final trimmed = note?.trim();
    final version = await appVersion();
    final body = jsonEncode({
      'install_id': await installId(db),
      'area_id': areaId,
      'kind': kind.code,
      'item_id': ?itemId,
      'date': ?date,
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      'app_version': ?version,
    });
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/v1/reports'),
            headers: {'content-type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
      return switch (response.statusCode) {
        201 => ReportResult.sent,
        429 => ReportResult.limited,
        _ => ReportResult.failed,
      };
    } on TimeoutException {
      return ReportResult.offline;
    } on http.ClientException {
      return ReportResult.offline;
    }
  }
}

Future<String?> _packageVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Object {
    return null;
  }
}
