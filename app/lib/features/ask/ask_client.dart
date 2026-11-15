import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/database.dart';
import '../../data/thin_api.dart';
import '../search/item_search.dart';

/// The API's limits.
const maxQuestionLength = 200;
const _maxInstructionLength = 300;

sealed class AskResult {
  const AskResult();
}

/// The answer, grounded in the candidates the app sent.
class AskAnswer extends AskResult {
  const AskAnswer({
    required this.covered,
    required this.itemIds,
    required this.text,
    required this.cached,
    required this.elapsed,
  });

  /// False when the area's rules don't settle the question.
  final bool covered;

  /// The rules the answer relies on, most relevant first.
  final List<String> itemIds;

  /// The model's sentence; null when the API dropped it because it named a
  /// category the cited rules don't have.
  final String? text;
  final bool cached;
  final Duration elapsed;
}

enum AskProblem { offline, paused, failed }

class AskUnavailable extends AskResult {
  const AskUnavailable(this.problem);

  final AskProblem problem;
}

/// Asks the thin API a plain-language question about the area's rules.
/// Sends the question, the area id and the candidate rules found on the
/// phone (names, category, English instructions); never a location.
class AskClient {
  AskClient({
    required this.db,
    required this.client,
    String baseUrl = apiBaseUrl,
    Future<String?> Function()? appVersion,
    this.timeout = const Duration(seconds: 25),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       appVersion = appVersion ?? _packageVersion;

  final AppDatabase db;
  final http.Client client;
  final String baseUrl;
  final Future<String?> Function() appVersion;
  final Duration timeout;

  Future<AskResult> ask({
    required String areaId,
    required String question,
    required List<SearchHit> candidates,
    required bool japanese,
  }) async {
    final version = await appVersion();
    final body = jsonEncode({
      'install_id': await installId(db),
      'area_id': areaId,
      'question': question.trim(),
      'language': japanese ? 'ja' : 'en',
      'candidates': [
        for (final c in candidates)
          {
            'item_id': c.rule.itemId,
            'name_ja': c.rule.nameJa,
            'name_en': c.rule.nameEn,
            'category': c.rule.category,
            'instructions_en': _cut(c.rule.instructionsEn),
          },
      ],
      'app_version': ?version,
    });
    final started = DateTime.now();
    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$baseUrl/v1/ask'),
            headers: {'content-type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      return const AskUnavailable(AskProblem.offline);
    } on http.ClientException {
      return const AskUnavailable(AskProblem.offline);
    } on Object {
      return const AskUnavailable(AskProblem.failed);
    }
    if (response.statusCode == 429 || response.statusCode == 503) {
      return const AskUnavailable(AskProblem.paused);
    }
    if (response.statusCode != 200) {
      return const AskUnavailable(AskProblem.failed);
    }
    try {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final answer = json['answer'] as Map<String, dynamic>;
      return AskAnswer(
        covered: answer['covered'] as bool,
        itemIds: (answer['item_ids'] as List<dynamic>).cast<String>(),
        text: answer['text'] as String?,
        cached: json['cached'] == true,
        elapsed: DateTime.now().difference(started),
      );
    } on Object {
      return const AskUnavailable(AskProblem.failed);
    }
  }
}

String _cut(String text) => text.length <= _maxInstructionLength
    ? text
    : '${text.substring(0, _maxInstructionLength - 1)}…';

Future<String?> _packageVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Object {
    return null;
  }
}
