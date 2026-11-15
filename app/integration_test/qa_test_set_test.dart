// The Q&A test question set: real questions against the full Yokohama
// bundle and the live API (api.blidir.fun). An answer passes when it cites
// a rule in the expected category, or, for questions the rules don't
// cover, when it says so. A cited rule in another category is a
// contradiction and fails the run.
//
//   flutter test integration_test/qa_test_set_test.dart -d <device>
//
// Each question is one AI call within the install's daily cap; repeated
// runs hit the API's answer cache. The report is printed.

import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/features/ask/ask_client.dart';
import 'package:binpal/features/ask/question_search.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Aoba-ku.
const _areaId = '14117-068001';

/// (question, Japanese?, expected category id, or null when the rules
/// shouldn't cover it).
const _questions = [
  ('Can I throw out a broken umbrella with a metal frame?', false, 'kinzoku'),
  ('Can I throw out a sofa?', false, 'sodai'),
  ('How do I dispose of a frying pan?', false, 'kinzoku'),
  ('Where do used dry cell batteries go?', false, 'denchi'),
  ('How do I put out an empty spray can?', false, 'spray'),
  ('Is a PET bottle for drinks recyclable?', false, 'kan-bin-pet'),
  ('What do I do with old newspapers?', false, 'koshi'),
  ('Where does an old metal cup go?', false, 'kinzoku'),
  ('Can I put a mattress out with burnable rubbish?', false, 'sodai'),
  ('Where does a plastic food tray go?', false, 'plastic'),
  ('Can the city take my old TV?', false, 'shushu-fuka'),
  ('壊れた傘(骨が金属)はどう出しますか?', true, 'kinzoku'),
  ('スプレー缶の出し方は?', true, 'spray'),
  ('ペットボトルのキャップは?', true, 'plastic'),
  ('When does the recycling centre open on Sundays?', false, null),
  ('How much does it cost to rent a skip?', false, null),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Q&A test question set', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sync = await BundleSync(
      db: db,
      client: http.Client(),
    ).sync(launchMunicipalityId);
    expect(sync.outcome, SyncOutcome.updated);
    final search = QuestionSearch(db);
    final client = AskClient(db: db, client: http.Client());

    final lines = <String>[];
    var contradictions = 0, passed = 0;
    for (final (question, japanese, expected) in _questions) {
      final candidates = await search.candidates(
        launchMunicipalityId,
        question,
      );
      final result = candidates.isEmpty
          ? null
          : await client.ask(
              areaId: _areaId,
              question: question,
              candidates: candidates,
              japanese: japanese,
            );
      final String verdict;
      if (result is AskAnswer && result.covered) {
        final cited = [
          for (final id in result.itemIds)
            candidates.firstWhere((c) => c.rule.itemId == id),
        ];
        final category = cited.first.category.id;
        final ok = category == expected;
        if (!ok && expected != null) contradictions++;
        if (ok) passed++;
        verdict =
            '${ok ? 'ok  ' : 'FAIL'} cites ${cited.first.rule.nameEn} '
            '($category)${result.text == null ? ', summary dropped' : ': ${result.text}'}'
            ' [${result.elapsed.inMilliseconds} ms${result.cached ? ', cached' : ''}]';
      } else if (result is AskUnavailable) {
        verdict = 'ERR  ${result.problem.name}';
      } else {
        final ok = expected == null;
        if (ok) passed++;
        verdict =
            '${ok ? 'ok  ' : 'miss'} not covered'
            '${candidates.isEmpty ? ' (no rule matched on the phone)' : ''}';
      }
      lines.add(
        '$verdict  <- $question (expected ${expected ?? 'not covered'})',
      );
    }
    // ignore: avoid_print
    print(
      'Q&A test set: $passed / ${_questions.length} as expected, '
      '$contradictions contradictions\n${lines.join('\n')}',
    );
    expect(contradictions, 0);
  });
}
