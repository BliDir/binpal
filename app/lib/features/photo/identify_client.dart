import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../data/database.dart';
import '../search/item_search.dart';

/// Where the thin API is served. Override at build time with
/// `--dart-define=API_BASE_URL=…`.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.blidir.fun',
);

/// A random id made on first use, so the API can count per-install limits.
/// It identifies nothing else: no account, device or location.
const installIdSettingKey = 'install_id';

/// What the AI said about a photo.
sealed class AiResult {
  const AiResult();
}

/// The model picked an item from the candidates, or only a category when
/// none of them fit.
class AiAnswer extends AiResult {
  const AiAnswer({
    required this.itemId,
    required this.categoryId,
    required this.confidence,
    required this.cached,
    required this.elapsed,
  });

  final String? itemId;
  final String categoryId;
  final double confidence;
  final bool cached;

  /// From sending the request to reading the answer, for p50/p95.
  final Duration elapsed;
}

/// Why there is no AI answer.
enum AiProblem {
  /// The models looked and couldn't tell.
  noAnswer,

  /// No connection, or no reply in time.
  offline,

  /// AI is off for today (budget or free allowance used up), or this
  /// install's daily calls are used.
  paused,

  /// Anything else: a server error or an answer the app can't read.
  failed,
}

class AiUnavailable extends AiResult {
  const AiUnavailable(this.problem);

  final AiProblem problem;
}

/// Asks the thin API to identify a photo the phone wasn't sure about.
///
/// Sends the resized JPEG, the area and the on-device candidates and
/// labels; never a location. The API keeps no photo. Disposal instructions
/// always come from the local bundle, never from this answer.
class IdentifyClient {
  IdentifyClient({
    required this.db,
    required this.client,
    String baseUrl = apiBaseUrl,
    this.timeout = const Duration(seconds: 20),
    Random? random,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _random = random ?? Random.secure();

  final AppDatabase db;
  final http.Client client;
  final String baseUrl;
  final Duration timeout;
  final Random _random;

  Future<AiResult> identify({
    required String areaId,
    required Uint8List jpeg,
    required List<SearchHit> candidates,
    required List<String> labels,
  }) async {
    if (candidates.isEmpty) return const AiUnavailable(AiProblem.noAnswer);
    final body = jsonEncode({
      'install_id': await installId(),
      'area_id': areaId,
      'image': base64Encode(jpeg),
      'candidates': [
        for (final c in candidates)
          {
            'item_id': c.rule.itemId,
            'name_ja': c.rule.nameJa,
            'name_en': c.rule.nameEn,
            'category': c.rule.category,
          },
      ],
      'labels': [
        for (final l in labels.take(20)) l.length > 64 ? l.substring(0, 64) : l,
      ],
    });

    final started = DateTime.now();
    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$baseUrl/v1/identify'),
            headers: {'content-type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      return const AiUnavailable(AiProblem.offline);
    } on http.ClientException {
      return const AiUnavailable(AiProblem.offline);
    }
    final elapsed = DateTime.now().difference(started);

    if (response.statusCode == 429 || response.statusCode == 503) {
      return const AiUnavailable(AiProblem.paused);
    }
    if (response.statusCode != 200) {
      return const AiUnavailable(AiProblem.failed);
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = json['answer'] as Map<String, dynamic>?;
      if (answer == null) return const AiUnavailable(AiProblem.noAnswer);
      return AiAnswer(
        itemId: answer['item_id'] as String?,
        categoryId: answer['category'] as String,
        confidence: (answer['confidence'] as num).toDouble(),
        cached: json['cached'] == true,
        elapsed: elapsed,
      );
    } on Object {
      return const AiUnavailable(AiProblem.failed);
    }
  }

  /// This install's random id, made and stored the first time.
  Future<String> installId() async {
    final stored = await db.setting(installIdSettingKey);
    if (stored != null) return stored;
    final id = _uuidV4();
    await db.setSetting(installIdSettingKey, id);
    return id;
  }

  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')];
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10).join()}';
  }
}
