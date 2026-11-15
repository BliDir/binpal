import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../../data/normalize.dart';
import '../search/item_search.dart';
import 'recycling_marks.dart';

/// One on-device image label, such as "Umbrella" at 0.86.
class PhotoLabel {
  const PhotoLabel(this.text, this.confidence);

  final String text;
  final double confidence;
}

/// What the phone saw in a photo: image labels, the text printed on it, and
/// the recycling marks in that text.
class PhotoSignals {
  PhotoSignals({
    required List<PhotoLabel> labels,
    this.text = '',
    this.modelsMissing = false,
  }) : labels = [
         for (final l in labels)
           if (!_ignoredLabels.contains(l.text.toLowerCase())) l,
       ]..sort((a, b) => b.confidence.compareTo(a.confidence)),
       marks = findRecyclingMarks(text),
       spray = mentionsSpray(text);

  /// Most confident first, without labels that say nothing about the item
  /// ("Hand", "Room").
  final List<PhotoLabel> labels;
  final String text;
  final Set<RecyclingMark> marks;

  /// The text says spray or aerosol, so metal marks don't decide.
  final bool spray;

  /// Labeling or text recognition couldn't run, typically because Android's
  /// Play Services is still downloading the models after install.
  final bool modelsMissing;

  /// Labels confident enough to remember a choice by.
  static const rememberAbove = 0.6;

  /// Identifies "the same item" for remembered choices: the confident labels
  /// and the marks, sorted. Empty when there is nothing to go on.
  String get key {
    final parts = <String>{
      for (final l in labels.take(5))
        if (l.confidence >= rememberAbove) l.text.toLowerCase(),
      for (final m in marks) 'mark:${m.name}',
    }.toList()..sort();
    return parts.join('|');
  }

  /// Sent to the API for tuning the alias table: label names and marks,
  /// never the recognised text itself.
  List<String> get logLabels => [
    for (final m in marks) 'mark:${m.name}',
    for (final l in labels.take(20 - marks.length)) l.text,
  ];
}

/// Where a confident answer came from.
enum PhotoAnswerSource {
  /// The user chose this item before for the same labels and marks.
  remembered,

  /// A recycling mark decided the category.
  mark,

  /// One candidate was clearly ahead of the others.
  label,

  /// The likely candidates are all in one category.
  sharedCategory,

  /// The thin API's model chose it.
  ai,
}

/// A confident answer: always a category, and an item when one is known.
class PhotoAnswer {
  const PhotoAnswer({required this.category, this.item, required this.source});

  final WasteCategory category;
  final SearchHit? item;
  final PhotoAnswerSource source;
}

/// The on-device result for a photo.
class PhotoMatch {
  const PhotoMatch({required this.candidates, this.answer});

  /// Likely items, best first, at most [PhotoMatcher.maxCandidates]. These
  /// are what the user picks from and what the AI chooses among.
  final List<SearchHit> candidates;

  /// Set when the phone is confident; otherwise ask the user (and the AI).
  final PhotoAnswer? answer;
}

/// Turns what the phone saw into likely items from the stored bundle, with
/// no network.
///
/// Each label is searched like a typed query ([ItemSearch]), so it reaches
/// rules through their names and the bundle's aliases. A candidate's weight
/// is the label's confidence times how well it matched (an exact alias
/// counts fully, a match inside a longer name a third), plus a little for
/// every other label that also found it.
///
/// The phone is confident when, in order:
/// 1. the user picked an item before for the same labels and marks;
/// 2. a recycling mark names one category (PET wins over プラ, which is for
///    the cap and label); metal marks don't count on a spray can;
/// 3. one candidate is clearly ahead ([clearWeight], [clearLead]);
/// 4. every likely candidate is in the same category.
class PhotoMatcher {
  PhotoMatcher(this.db, {DateTime Function()? clock})
    : _search = ItemSearch(db),
      _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final ItemSearch _search;
  final DateTime Function() _clock;

  /// The API accepts 30; the ticket asks for about 20.
  static const maxCandidates = 20;

  /// Labels below this are too unsure to search for.
  static const minLabelConfidence = 0.5;

  static const clearWeight = 0.7;
  static const clearLead = 0.25;

  /// Candidates within this share of the best one count as likely.
  static const likelyShare = 0.8;
  static const sharedCategoryWeight = 0.6;

  Future<PhotoMatch> match(String municipalityId, PhotoSignals signals) async {
    final now = _clock();
    final ranked = await _rank(municipalityId, signals, now);
    final candidates = [for (final (hit, _) in ranked) hit];

    final remembered = await _remembered(municipalityId, signals, now);
    if (remembered != null) {
      return PhotoMatch(
        candidates: _first(remembered, candidates),
        answer: PhotoAnswer(
          category: remembered.category,
          item: remembered,
          source: PhotoAnswerSource.remembered,
        ),
      );
    }

    final mark = await _markCategory(municipalityId, signals);
    if (mark != null) {
      final (category, itemQuery) = mark;
      final inCategory = [
        for (final c in candidates)
          if (c.category.id == category.id) c,
      ];
      return PhotoMatch(
        candidates: inCategory,
        answer: PhotoAnswer(
          category: category,
          item: await _markItem(
            municipalityId,
            category,
            itemQuery,
            inCategory,
            now,
          ),
          source: PhotoAnswerSource.mark,
        ),
      );
    }

    if (ranked.isEmpty) return const PhotoMatch(candidates: []);
    final (top, topWeight) = ranked.first;
    final second = ranked.length > 1 ? ranked[1].$2 : 0.0;
    if (topWeight >= clearWeight && topWeight - second >= clearLead) {
      return PhotoMatch(
        candidates: candidates,
        answer: PhotoAnswer(
          category: top.category,
          item: top,
          source: PhotoAnswerSource.label,
        ),
      );
    }

    final likely = ranked.where((r) => r.$2 >= topWeight * likelyShare);
    if (topWeight >= sharedCategoryWeight &&
        likely.every((r) => r.$1.category.id == top.category.id)) {
      return PhotoMatch(
        candidates: candidates,
        answer: PhotoAnswer(
          category: top.category,
          // The only likely one is the item, even if not far enough ahead.
          item: likely.length == 1 ? top : null,
          source: PhotoAnswerSource.sharedCategory,
        ),
      );
    }
    return PhotoMatch(candidates: candidates);
  }

  /// Remembers [itemId] as the answer for photos with [signals].
  Future<void> remember(
    String municipalityId,
    PhotoSignals signals,
    String itemId,
  ) async {
    final key = signals.key;
    if (key.isEmpty) return;
    await db
        .into(db.photoChoices)
        .insertOnConflictUpdate(
          PhotoChoicesCompanion.insert(
            municipalityId: municipalityId,
            signals: key,
            itemId: itemId,
            chosenAt: _clock(),
          ),
        );
  }

  /// Candidates with their weights, best first.
  Future<List<(SearchHit, double)>> _rank(
    String municipalityId,
    PhotoSignals signals,
    DateTime now,
  ) async {
    final best = <String, (SearchHit, double, int)>{};
    for (final label in signals.labels) {
      if (label.confidence < minLabelConfidence) break;
      final words = label.text.trim().split(RegExp(r'\s+')).length;
      for (final hit in await _searchLabel(municipalityId, label.text, now)) {
        // A label that is exactly an item's English name ("Mobile phone")
        // counts as an exact match; otherwise average over its words.
        final score =
            normalizeForSearch(hit.rule.nameEn) ==
                normalizeForSearch(label.text)
            ? 1
            : hit.score ~/ words;
        final weight = label.confidence * _quality(score);
        final current = best[hit.rule.itemId];
        if (current == null) {
          best[hit.rule.itemId] = (hit, weight, 0);
        } else {
          final (h, w, others) = current;
          best[hit.rule.itemId] = weight > w
              ? (hit, weight, others + 1)
              : (h, w, others + 1);
        }
      }
    }
    final ranked = [
      for (final (hit, weight, others) in best.values)
        (hit, (weight + 0.1 * others).clamp(0.0, 1.0)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return ranked.take(maxCandidates).toList();
  }

  Future<List<SearchHit>> _searchLabel(
    String municipalityId,
    String label,
    DateTime now,
  ) async {
    final query = label.toLowerCase();
    final hits = await _search.search(municipalityId, query, now: now);
    if (hits.isNotEmpty || !query.endsWith('s')) return hits;
    // "Shoes" finds "shoe" only without the plural.
    final singular = query.endsWith('es') && !query.endsWith('ses')
        ? query.substring(0, query.length - 2)
        : query.substring(0, query.length - 1);
    return _search.search(municipalityId, singular, now: now);
  }

  Future<SearchHit?> _remembered(
    String municipalityId,
    PhotoSignals signals,
    DateTime now,
  ) async {
    final key = signals.key;
    if (key.isEmpty) return null;
    final choice =
        await (db.select(db.photoChoices)..where(
              (c) =>
                  c.municipalityId.equals(municipalityId) &
                  c.signals.equals(key),
            ))
            .getSingleOrNull();
    if (choice == null) return null;
    return itemHit(municipalityId, choice.itemId, now: now);
  }

  /// The rule valid today for [itemId], with its category; null when the
  /// current bundle no longer has it.
  Future<SearchHit?> itemHit(
    String municipalityId,
    String itemId, {
    DateTime? now,
  }) async {
    final today = japanDate(now ?? _clock());
    final rule =
        await (db.select(db.rules)
              ..where(
                (r) =>
                    r.municipalityId.equals(municipalityId) &
                    r.itemId.equals(itemId) &
                    r.validFrom.isSmallerOrEqualValue(today) &
                    (r.validTo.isNull() |
                        r.validTo.isBiggerOrEqualValue(today)),
              )
              ..limit(1))
            .getSingleOrNull();
    if (rule == null) return null;
    final category = await categoryById(municipalityId, rule.category);
    return category == null ? null : SearchHit(rule, category);
  }

  Future<WasteCategory?> categoryById(String municipalityId, String id) =>
      (db.select(db.categories)..where(
            (c) => c.municipalityId.equals(municipalityId) & c.id.equals(id),
          ))
          .getSingleOrNull();

  /// The category the marks name, if they name exactly one, and a search
  /// for the item the mark itself stands for (a PET bottle, a drink can).
  Future<(WasteCategory, String?)?> _markCategory(
    String municipalityId,
    PhotoSignals signals,
  ) async {
    var marks = {...signals.marks};
    if (signals.spray) {
      marks.removeAll({RecyclingMark.aluminium, RecyclingMark.steel});
    }
    // A PET bottle carries PET for the bottle and プラ for the cap and label.
    if (marks.contains(RecyclingMark.pet)) marks.remove(RecyclingMark.plastic);
    if (marks.isEmpty) return null;

    final categories = await (db.select(
      db.categories,
    )..where((c) => c.municipalityId.equals(municipalityId))).get();
    WasteCategory? byCommon(List<String> commons) {
      for (final common in commons) {
        for (final c in categories) {
          if (c.common == common) return c;
        }
      }
      return null;
    }

    final found = {
      for (final mark in marks)
        byCommon(switch (mark) {
          RecyclingMark.plastic => ['plastic'],
          RecyclingMark.pet => ['pet_bottles', 'cans_bottles'],
          RecyclingMark.aluminium ||
          RecyclingMark.steel => ['cans_bottles', 'resources'],
          RecyclingMark.paper => ['paper'],
        })?.id,
    };
    if (found.length != 1 || found.first == null) return null;
    final category = categories.firstWhere((c) => c.id == found.first);
    // プラ and 紙 cover many kinds of packaging, so they name no one item.
    final itemQuery = marks.contains(RecyclingMark.pet)
        ? 'pet bottle'
        : marks.any(
            (m) => m == RecyclingMark.aluminium || m == RecyclingMark.steel,
          )
        ? 'drink can'
        : null;
    return (category, itemQuery);
  }

  /// The item a mark stands for: the best label candidate that [itemQuery]
  /// also finds ("Soy sauce PET bottle"), or else the query's best hit in
  /// [category] ("PET bottle (for drinks)").
  Future<SearchHit?> _markItem(
    String municipalityId,
    WasteCategory category,
    String? itemQuery,
    List<SearchHit> inCategory,
    DateTime now,
  ) async {
    if (itemQuery == null) return null;
    final hits = [
      for (final h in await _search.search(municipalityId, itemQuery, now: now))
        if (h.category.id == category.id) h,
    ];
    final ids = {for (final h in hits) h.rule.itemId};
    for (final c in inCategory) {
      if (ids.contains(c.rule.itemId)) return c;
    }
    return hits.firstOrNull;
  }
}

/// [candidates] with [hit] moved to the front.
List<SearchHit> _first(SearchHit hit, List<SearchHit> candidates) => [
  hit,
  for (final c in candidates)
    if (c.rule.itemId != hit.rule.itemId) c,
];

/// How much a match counts, by [SearchHit.score].
double _quality(int score) => switch (score) {
  0 => 1.0,
  1 => 0.9,
  2 => 0.6,
  3 => 0.5,
  _ => 0.3,
};

/// Labels ML Kit gives for almost any photo, which say nothing about the item.
const _ignoredLabels = {
  'hand',
  'finger',
  'room',
  'pattern',
  'font',
  'material',
  'rectangle',
  'circle',
  'event',
  'fun',
  'smile',
  'sky',
  'skin',
  'nail',
};
