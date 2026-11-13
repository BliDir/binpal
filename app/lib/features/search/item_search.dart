import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../../data/normalize.dart';

/// One search result: the rule and the category it goes in.
class SearchHit {
  const SearchHit(this.rule, this.category);

  final Rule rule;
  final WasteCategory category;
}

/// Offline item search over the stored bundle.
///
/// The query is normalised the same way as the index ([normalizeForSearch]),
/// so カサ, ｶｻ and かさ are the same query, and so are UMBRELLA and umbrella.
/// Words separated by spaces must all match. A word of three or more
/// characters uses the trigram full-text index; a shorter one (傘, 電池)
/// uses LIKE on the same table.
///
/// Results are ranked by how well the best name or alias matches: exactly
/// (a curated alias before a name or reading), then from its start, then from
/// the start of a word, then anywhere. Ties go to the shorter Japanese name.
/// So かさ lists the umbrellas, whose alias it is, before 笠 (a conical hat),
/// whose reading it happens to be.
class ItemSearch {
  ItemSearch(this.db);

  final AppDatabase db;

  static const limit = 100;

  Future<List<SearchHit>> search(
    String municipalityId,
    String query, {
    DateTime? now,
  }) async {
    final words = normalizeForSearch(query).split(' ').where((w) => w != '');
    if (words.isEmpty) return const [];

    // Best score per rule for each word; a rule must match every word.
    Map<int, int>? scores;
    for (final word in words) {
      final matches = await _match(municipalityId, word);
      final next = <int, int>{};
      for (final (ruleId, term, isAlias) in matches) {
        if (scores != null && !scores.containsKey(ruleId)) continue;
        final s = _score(term, word, isAlias) + (scores?[ruleId] ?? 0);
        final current = next[ruleId];
        if (current == null || s < current) next[ruleId] = s;
      }
      scores = next;
      if (scores.isEmpty) return const [];
    }

    final today = _japanDate(now ?? DateTime.now());
    final rules =
        await (db.select(db.rules)..where(
              (r) =>
                  r.id.isIn(scores!.keys) &
                  r.validFrom.isSmallerOrEqualValue(today) &
                  (r.validTo.isNull() | r.validTo.isBiggerOrEqualValue(today)),
            ))
            .get();
    rules.sort((a, b) {
      final byScore = scores![a.id]!.compareTo(scores[b.id]!);
      if (byScore != 0) return byScore;
      final byLength = a.nameJa.length.compareTo(b.nameJa.length);
      return byLength != 0 ? byLength : a.id.compareTo(b.id);
    });

    final categories = {
      for (final c in await (db.select(
        db.categories,
      )..where((c) => c.municipalityId.equals(municipalityId))).get())
        c.id: c,
    };
    return [
      for (final r in rules.take(limit))
        if (categories[r.category] case final category?) SearchHit(r, category),
    ];
  }

  Future<List<(int, String, bool)>> _match(String municipalityId, String word) {
    final String condition;
    final String pattern;
    if (word.runes.length >= 3) {
      condition = 'search_index MATCH ?';
      pattern = '"${word.replaceAll('"', '""')}"';
    } else {
      condition = r"term LIKE ? ESCAPE '\'";
      pattern =
          '%${word.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';
    }
    return db
        .customSelect(
          'SELECT rule_id, term, is_alias FROM search_index '
          'WHERE municipality_id = ? AND $condition',
          variables: [
            Variable.withString(municipalityId),
            Variable.withString(pattern),
          ],
        )
        .map(
          (row) => (
            row.read<int>('rule_id'),
            row.read<String>('term'),
            row.read<int>('is_alias') == 1,
          ),
        )
        .get();
  }
}

/// Lower is better.
int _score(String term, String word, bool isAlias) {
  if (term == word) return isAlias ? 0 : 1;
  if (term.startsWith(word)) return 2;
  final i = term.indexOf(word);
  if (i > 0 && ' ([/・-'.contains(term[i - 1])) return 3;
  return 4;
}

/// Today's date in Japan, `YYYY-MM-DD`, which is how bundles write dates.
String _japanDate(DateTime moment) {
  final japan = moment.toUtc().add(const Duration(hours: 9));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${japan.year}-${two(japan.month)}-${two(japan.day)}';
}
