import '../../data/database.dart';
import '../../data/normalize.dart';
import '../search/item_search.dart';

/// The area's rules a question may be about, found on the phone. They are
/// what the AI may answer from, and nothing else.
///
/// The question is cut into search words: English words that say what the
/// item is (not "can", "throw", "the"), and in Japanese the runs of kanji and
/// katakana, where item names are. Each is searched like a typed query
/// ([ItemSearch]); a rule found by more words, and by better matches, ranks
/// higher.
class QuestionSearch {
  QuestionSearch(AppDatabase db) : _search = ItemSearch(db);

  final ItemSearch _search;

  /// The API takes at most 20.
  static const maxCandidates = 20;

  Future<List<SearchHit>> candidates(
    String municipalityId,
    String question, {
    DateTime? now,
  }) async {
    final scores = <String, (SearchHit, double)>{};
    for (final word in searchWords(question)) {
      final hits = await _search.search(municipalityId, word, now: now);
      for (final hit in hits.take(40)) {
        final weight = switch (hit.score) {
          0 => 1.0,
          1 => 0.9,
          2 => 0.6,
          3 => 0.5,
          _ => 0.3,
        };
        final id = hit.rule.itemId;
        final current = scores[id];
        scores[id] = (hit, (current?.$2 ?? 0) + weight);
      }
    }
    final ranked = scores.values.toList()
      ..sort((a, b) {
        final byWeight = b.$2.compareTo(a.$2);
        return byWeight != 0
            ? byWeight
            : a.$1.rule.nameJa.length.compareTo(b.$1.rule.nameJa.length);
      });
    return [for (final (hit, _) in ranked.take(maxCandidates)) hit];
  }
}

/// The words of [question] worth searching for.
List<String> searchWords(String question) {
  final words = <String>{};
  final folded = normalizeForSearch(question);
  for (final m in RegExp(r'[a-z][a-z-]*').allMatches(folded)) {
    final word = m[0]!;
    if (word.length >= 3 && !_englishStopwords.contains(word)) {
      words.add(word.endsWith('s') && word.length > 4 ? _singular(word) : word);
    }
  }
  // Kanji and katakana runs; katakana is folded to hiragana by
  // normalizeForSearch, so read them from the original text.
  for (final m in RegExp(r'[一-鿿々]+|[ァ-ヺー]{2,}').allMatches(question)) {
    final run = m[0]!;
    if (!_japaneseStopwords.contains(run)) words.add(run);
  }
  return words.toList();
}

String _singular(String word) => word.endsWith('ies')
    ? '${word.substring(0, word.length - 3)}y'
    : word.endsWith('ses') || word.endsWith('xes') || word.endsWith('ches')
    ? word.substring(0, word.length - 2)
    : word.substring(0, word.length - 1);

/// Words that say nothing about the item.
final _englishStopwords =
    ('the and for can how what where when which who why with without '
            'into out off put throw throwing away dispose disposal get rid '
            'should would could does did are was were this that these those '
            'there here have has had old broken used some any all about from '
            'garbage rubbish trash waste bin recycle recycling recyclable sort '
            'sorting day days collection collected yes not you your our its '
            'they them one two need want like also still type kind category '
            'please ok okay allowed possible')
        .split(' ')
        .toSet();

const _japaneseStopwords = {'何', '日', '方', '物', '時', '今', '出', '捨'};
