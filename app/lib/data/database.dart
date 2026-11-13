import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'normalize.dart';

part 'database.g.dart';

/// One row per downloaded municipality bundle.
@DataClassName('StoredBundle')
class Bundles extends Table {
  TextColumn get municipalityId => text()();
  IntColumn get bundleVersion => integer()();
  TextColumn get sha256 => text()();
  TextColumn get generatedAt => text()();
  TextColumn get nameJa => text()();
  TextColumn get nameKana => text()();
  TextColumn get nameEn => text()();

  /// The bundle's `attribution` list as JSON, shown as licence credits.
  TextColumn get attribution => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {municipalityId};
}

class Wards extends Table {
  TextColumn get id => text()();
  TextColumn get municipalityId => text()();
  TextColumn get nameJa => text()();
  TextColumn get nameKana => text()();
  TextColumn get nameEn => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Areas extends Table {
  TextColumn get id => text()();
  TextColumn get municipalityId => text()();
  TextColumn get wardId => text().nullable()();
  TextColumn get nameJa => text()();
  TextColumn get nameKana => text()();
  TextColumn get nameEn => text()();
  TextColumn get townJa => text()();
  TextColumn get townKana => text()();
  TextColumn get townEn => text()();
  IntColumn get chome => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WasteCategory')
class Categories extends Table {
  TextColumn get municipalityId => text()();
  TextColumn get id => text()();
  TextColumn get nameJa => text()();
  TextColumn get nameKana => text()();
  TextColumn get nameEn => text()();

  /// One of the shared set that drives icons and colours (`burnable`, …).
  TextColumn get common => text()();
  TextColumn get descriptionJa => text().nullable()();
  TextColumn get descriptionEn => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {municipalityId, id};
}

@TableIndex(name: 'rules_municipality', columns: {#municipalityId})
class Rules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get municipalityId => text()();
  TextColumn get itemId => text()();
  TextColumn get nameJa => text()();
  TextColumn get nameKana => text()();
  TextColumn get nameEn => text()();
  TextColumn get category => text()();
  TextColumn get instructionsJa => text()();
  TextColumn get instructionsEn => text()();

  /// Inclusive `YYYY-MM-DD` dates in Japan time; no [validTo] means open-ended.
  TextColumn get validFrom => text()();
  TextColumn get validTo => text().nullable()();
  TextColumn get sourceUrl => text()();
  TextColumn get verifiedAt => text()();
}

@DataClassName('RuleAlias')
@TableIndex(name: 'aliases_rule', columns: {#ruleId})
class Aliases extends Table {
  IntColumn get ruleId =>
      integer().references(Rules, #id, onDelete: KeyAction.cascade)();
  TextColumn get alias => text()();
}

@DataClassName('CollectionCalendar')
class Calendars extends Table {
  TextColumn get municipalityId => text()();
  TextColumn get id => text()();

  /// JSON list of category ids collected on this pattern.
  TextColumn get categories => text()();

  /// The bundle's `pattern` object as JSON (`weekly`, `monthly_nth_weekday`, …).
  /// Kept whole so an unknown pattern type can be skipped, not fail the import.
  TextColumn get pattern => text()();
  TextColumn get putOutBy => text().nullable()();
  TextColumn get validFrom => text()();
  TextColumn get validTo => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {municipalityId, id};
}

@TableIndex(name: 'calendar_areas_area', columns: {#areaId})
class CalendarAreas extends Table {
  TextColumn get municipalityId => text()();
  TextColumn get calendarId => text()();
  TextColumn get areaId => text()();

  @override
  Set<Column> get primaryKey => {municipalityId, calendarId, areaId};
}

@DataClassName('CollectionException')
class CollectionExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get municipalityId => text()();
  TextColumn get date => text()();
  TextColumn get type => text()();

  /// JSON lists; null means every category or every area.
  TextColumn get categories => text().nullable()();
  TextColumn get areaIds => text().nullable()();
  TextColumn get noteJa => text().nullable()();
  TextColumn get noteEn => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
}

/// Searches that found nothing, counted on the device to improve aliases.
/// Only the normalised query text and a count are kept; nothing is sent.
class MissedSearches extends Table {
  TextColumn get query => text()();
  IntColumn get count => integer()();
  DateTimeColumn get lastAt => dateTime()();

  @override
  Set<Column> get primaryKey => {query};
}

/// Small key-value store: the chosen municipality and area, last sync time.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Bundles,
    Wards,
    Areas,
    Categories,
    Rules,
    Aliases,
    Calendars,
    CalendarAreas,
    CollectionExceptions,
    MissedSearches,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'binpal'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createSearchIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(missedSearches);
        await _createSearchIndex();
        for (final b in await select(bundles).get()) {
          await _indexMunicipality(b.municipalityId);
        }
      }
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// Full-text index over every rule's names and aliases, normalised with
  /// [normalizeForSearch]. The trigram tokenizer matches any substring of
  /// three or more characters; shorter queries use LIKE on the same table.
  /// `is_alias` marks terms that came from the bundle's curated aliases.
  Future<void> _createSearchIndex() => customStatement(
    'CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5('
    'term, rule_id UNINDEXED, municipality_id UNINDEXED, is_alias UNINDEXED, '
    "tokenize = 'trigram')",
  );

  Future<void> _indexMunicipality(String mid) async {
    await customStatement(
      'DELETE FROM search_index WHERE municipality_id = ?',
      [mid],
    );
    final rows = await customSelect(
      'SELECT r.id, r.name_ja, r.name_kana, r.name_en, '
      '(SELECT group_concat(alias, char(31)) FROM aliases a '
      'WHERE a.rule_id = r.id) AS aliases '
      'FROM rules r WHERE r.municipality_id = ?',
      variables: [Variable.withString(mid)],
    ).get();
    await batch((b) {
      for (final row in rows) {
        final id = row.read<int>('id');
        // Term -> whether it came from an alias. A term that is both a name
        // and an alias counts as an alias.
        final terms = <String, bool>{
          for (final t in [
            row.read<String>('name_ja'),
            row.read<String>('name_kana'),
            row.read<String>('name_en'),
          ])
            normalizeForSearch(t): false,
          for (final t
              in row.readNullable<String>('aliases')?.split('\u001f') ??
                  const <String>[])
            normalizeForSearch(t): true,
        }..remove('');
        for (final MapEntry(key: term, value: isAlias) in terms.entries) {
          b.customStatement(
            'INSERT INTO search_index '
            '(term, rule_id, municipality_id, is_alias) VALUES (?, ?, ?, ?)',
            [term, id, mid, if (isAlias) 1 else 0],
          );
        }
      }
    });
  }

  /// Counts a search that found nothing.
  Future<void> recordMissedSearch(String query, {DateTime? at}) async {
    final normalized = normalizeForSearch(query);
    if (normalized.isEmpty) return;
    await customStatement(
      'INSERT INTO missed_searches (query, count, last_at) VALUES (?, 1, ?) '
      'ON CONFLICT(query) DO UPDATE SET count = count + 1, '
      'last_at = excluded.last_at',
      [normalized, (at ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000],
    );
  }

  Future<StoredBundle?> bundleFor(String municipalityId) => (select(
    bundles,
  )..where((b) => b.municipalityId.equals(municipalityId))).getSingleOrNull();

  Future<String?> setting(String key) async {
    final row = await (select(
      settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) => into(settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  /// Replaces everything stored for the bundle's municipality with [bundle],
  /// in one transaction: if anything in it is malformed, the previous data
  /// stays exactly as it was.
  Future<void> importBundle(
    Map<String, dynamic> bundle, {
    required String sha256,
    DateTime? importedAt,
  }) {
    return transaction(() async {
      final municipality = bundle['municipality'] as Map<String, dynamic>;
      final mid = municipality['id'] as String;
      final names = municipality['names'] as Map<String, dynamic>;

      await _deleteMunicipality(mid);

      await into(bundles).insert(
        BundlesCompanion.insert(
          municipalityId: mid,
          bundleVersion: bundle['bundle_version'] as int,
          sha256: sha256,
          generatedAt: bundle['generated_at'] as String,
          nameJa: names['ja'] as String,
          nameKana: names['kana'] as String,
          nameEn: names['en'] as String,
          attribution: jsonEncode(bundle['attribution']),
          importedAt: importedAt ?? DateTime.now(),
        ),
      );

      await batch((b) {
        for (final w in _maps(bundle['wards'])) {
          final n = w['names'] as Map<String, dynamic>;
          b.insert(
            wards,
            WardsCompanion.insert(
              id: w['id'] as String,
              municipalityId: mid,
              nameJa: n['ja'] as String,
              nameKana: n['kana'] as String,
              nameEn: n['en'] as String,
            ),
          );
        }
        for (final a in _maps(bundle['areas'])) {
          final n = a['names'] as Map<String, dynamic>;
          final t = a['town'] as Map<String, dynamic>;
          b.insert(
            areas,
            AreasCompanion.insert(
              id: a['id'] as String,
              municipalityId: mid,
              wardId: Value(a['ward_id'] as String?),
              nameJa: n['ja'] as String,
              nameKana: n['kana'] as String,
              nameEn: n['en'] as String,
              townJa: t['ja'] as String,
              townKana: t['kana'] as String,
              townEn: t['en'] as String,
              chome: Value(a['chome'] as int?),
            ),
          );
        }
        for (final c in _maps(bundle['categories'])) {
          final n = c['names'] as Map<String, dynamic>;
          final d = c['description'] as Map<String, dynamic>?;
          b.insert(
            categories,
            CategoriesCompanion.insert(
              municipalityId: mid,
              id: c['id'] as String,
              nameJa: n['ja'] as String,
              nameKana: n['kana'] as String,
              nameEn: n['en'] as String,
              common: c['common'] as String,
              descriptionJa: Value(d?['ja'] as String?),
              descriptionEn: Value(d?['en'] as String?),
              sourceUrl: Value(c['source_url'] as String?),
            ),
          );
        }
        for (final c in _maps(bundle['calendars'])) {
          final calendarId = c['id'] as String;
          b.insert(
            calendars,
            CalendarsCompanion.insert(
              municipalityId: mid,
              id: calendarId,
              categories: jsonEncode(c['categories']),
              pattern: jsonEncode(c['pattern']),
              putOutBy: Value(c['put_out_by'] as String?),
              validFrom: c['valid_from'] as String,
              validTo: Value(c['valid_to'] as String?),
              sourceUrl: Value(c['source_url'] as String?),
            ),
          );
          for (final areaId in c['area_ids'] as List<dynamic>) {
            b.insert(
              calendarAreas,
              CalendarAreasCompanion.insert(
                municipalityId: mid,
                calendarId: calendarId,
                areaId: areaId as String,
              ),
            );
          }
        }
        for (final e in _maps(bundle['exceptions'])) {
          final note = e['note'] as Map<String, dynamic>?;
          b.insert(
            collectionExceptions,
            CollectionExceptionsCompanion.insert(
              municipalityId: mid,
              date: e['date'] as String,
              type: e['type'] as String,
              categories: Value(_jsonOrNull(e['categories'])),
              areaIds: Value(_jsonOrNull(e['area_ids'])),
              noteJa: Value(note?['ja'] as String?),
              noteEn: Value(note?['en'] as String?),
              sourceUrl: Value(e['source_url'] as String?),
            ),
          );
        }
      });

      // Rule ids are assigned here rather than by SQLite, so rules and their
      // aliases can go in one batch.
      final maxId = await customSelect(
        'SELECT COALESCE(MAX(id), 0) AS m FROM rules',
      ).map((row) => row.read<int>('m')).getSingle();
      var ruleId = maxId;
      await batch((b) {
        for (final r in _maps(bundle['rules'])) {
          ruleId++;
          final n = r['names'] as Map<String, dynamic>;
          final i = r['instructions'] as Map<String, dynamic>;
          b.insert(
            rules,
            RulesCompanion.insert(
              id: Value(ruleId),
              municipalityId: mid,
              itemId: r['item_id'] as String,
              nameJa: n['ja'] as String,
              nameKana: n['kana'] as String,
              nameEn: n['en'] as String,
              category: r['category'] as String,
              instructionsJa: i['ja'] as String,
              instructionsEn: i['en'] as String,
              validFrom: r['valid_from'] as String,
              validTo: Value(r['valid_to'] as String?),
              sourceUrl: r['source_url'] as String,
              verifiedAt: r['verified_at'] as String,
            ),
          );
          for (final alias in r['aliases'] as List<dynamic>) {
            b.insert(
              aliases,
              AliasesCompanion.insert(ruleId: ruleId, alias: alias as String),
            );
          }
        }
      });

      await _indexMunicipality(mid);
    });
  }

  Future<void> _deleteMunicipality(String mid) async {
    // Aliases go with their rules through the foreign key.
    await (delete(rules)..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(wards)..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(areas)..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(categories)..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(calendars)..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(
      calendarAreas,
    )..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(
      collectionExceptions,
    )..where((t) => t.municipalityId.equals(mid))).go();
    await (delete(bundles)..where((t) => t.municipalityId.equals(mid))).go();
  }
}

Iterable<Map<String, dynamic>> _maps(Object? list) =>
    (list as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

String? _jsonOrNull(Object? value) => value == null ? null : jsonEncode(value);
