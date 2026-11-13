// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BundlesTable extends Bundles
    with TableInfo<$BundlesTable, StoredBundle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BundlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bundleVersionMeta = const VerificationMeta(
    'bundleVersion',
  );
  @override
  late final GeneratedColumn<int> bundleVersion = GeneratedColumn<int>(
    'bundle_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<String> generatedAt = GeneratedColumn<String>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
    'name_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKanaMeta = const VerificationMeta(
    'nameKana',
  );
  @override
  late final GeneratedColumn<String> nameKana = GeneratedColumn<String>(
    'name_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    municipalityId,
    bundleVersion,
    sha256,
    generatedAt,
    nameJa,
    nameKana,
    nameEn,
    attribution,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bundles';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredBundle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('bundle_version')) {
      context.handle(
        _bundleVersionMeta,
        bundleVersion.isAcceptableOrUnknown(
          data['bundle_version']!,
          _bundleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bundleVersionMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(
        _nameJaMeta,
        nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('name_kana')) {
      context.handle(
        _nameKanaMeta,
        nameKana.isAcceptableOrUnknown(data['name_kana']!, _nameKanaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKanaMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attributionMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {municipalityId};
  @override
  StoredBundle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredBundle(
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      bundleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bundle_version'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generated_at'],
      )!,
      nameJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ja'],
      )!,
      nameKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kana'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $BundlesTable createAlias(String alias) {
    return $BundlesTable(attachedDatabase, alias);
  }
}

class StoredBundle extends DataClass implements Insertable<StoredBundle> {
  final String municipalityId;
  final int bundleVersion;
  final String sha256;
  final String generatedAt;
  final String nameJa;
  final String nameKana;
  final String nameEn;

  /// The bundle's `attribution` list as JSON, shown as licence credits.
  final String attribution;
  final DateTime importedAt;
  const StoredBundle({
    required this.municipalityId,
    required this.bundleVersion,
    required this.sha256,
    required this.generatedAt,
    required this.nameJa,
    required this.nameKana,
    required this.nameEn,
    required this.attribution,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['municipality_id'] = Variable<String>(municipalityId);
    map['bundle_version'] = Variable<int>(bundleVersion);
    map['sha256'] = Variable<String>(sha256);
    map['generated_at'] = Variable<String>(generatedAt);
    map['name_ja'] = Variable<String>(nameJa);
    map['name_kana'] = Variable<String>(nameKana);
    map['name_en'] = Variable<String>(nameEn);
    map['attribution'] = Variable<String>(attribution);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  BundlesCompanion toCompanion(bool nullToAbsent) {
    return BundlesCompanion(
      municipalityId: Value(municipalityId),
      bundleVersion: Value(bundleVersion),
      sha256: Value(sha256),
      generatedAt: Value(generatedAt),
      nameJa: Value(nameJa),
      nameKana: Value(nameKana),
      nameEn: Value(nameEn),
      attribution: Value(attribution),
      importedAt: Value(importedAt),
    );
  }

  factory StoredBundle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredBundle(
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      bundleVersion: serializer.fromJson<int>(json['bundleVersion']),
      sha256: serializer.fromJson<String>(json['sha256']),
      generatedAt: serializer.fromJson<String>(json['generatedAt']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameKana: serializer.fromJson<String>(json['nameKana']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      attribution: serializer.fromJson<String>(json['attribution']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'municipalityId': serializer.toJson<String>(municipalityId),
      'bundleVersion': serializer.toJson<int>(bundleVersion),
      'sha256': serializer.toJson<String>(sha256),
      'generatedAt': serializer.toJson<String>(generatedAt),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameKana': serializer.toJson<String>(nameKana),
      'nameEn': serializer.toJson<String>(nameEn),
      'attribution': serializer.toJson<String>(attribution),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  StoredBundle copyWith({
    String? municipalityId,
    int? bundleVersion,
    String? sha256,
    String? generatedAt,
    String? nameJa,
    String? nameKana,
    String? nameEn,
    String? attribution,
    DateTime? importedAt,
  }) => StoredBundle(
    municipalityId: municipalityId ?? this.municipalityId,
    bundleVersion: bundleVersion ?? this.bundleVersion,
    sha256: sha256 ?? this.sha256,
    generatedAt: generatedAt ?? this.generatedAt,
    nameJa: nameJa ?? this.nameJa,
    nameKana: nameKana ?? this.nameKana,
    nameEn: nameEn ?? this.nameEn,
    attribution: attribution ?? this.attribution,
    importedAt: importedAt ?? this.importedAt,
  );
  StoredBundle copyWithCompanion(BundlesCompanion data) {
    return StoredBundle(
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      bundleVersion: data.bundleVersion.present
          ? data.bundleVersion.value
          : this.bundleVersion,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameKana: data.nameKana.present ? data.nameKana.value : this.nameKana,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredBundle(')
          ..write('municipalityId: $municipalityId, ')
          ..write('bundleVersion: $bundleVersion, ')
          ..write('sha256: $sha256, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('attribution: $attribution, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    municipalityId,
    bundleVersion,
    sha256,
    generatedAt,
    nameJa,
    nameKana,
    nameEn,
    attribution,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredBundle &&
          other.municipalityId == this.municipalityId &&
          other.bundleVersion == this.bundleVersion &&
          other.sha256 == this.sha256 &&
          other.generatedAt == this.generatedAt &&
          other.nameJa == this.nameJa &&
          other.nameKana == this.nameKana &&
          other.nameEn == this.nameEn &&
          other.attribution == this.attribution &&
          other.importedAt == this.importedAt);
}

class BundlesCompanion extends UpdateCompanion<StoredBundle> {
  final Value<String> municipalityId;
  final Value<int> bundleVersion;
  final Value<String> sha256;
  final Value<String> generatedAt;
  final Value<String> nameJa;
  final Value<String> nameKana;
  final Value<String> nameEn;
  final Value<String> attribution;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const BundlesCompanion({
    this.municipalityId = const Value.absent(),
    this.bundleVersion = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameKana = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.attribution = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BundlesCompanion.insert({
    required String municipalityId,
    required int bundleVersion,
    required String sha256,
    required String generatedAt,
    required String nameJa,
    required String nameKana,
    required String nameEn,
    required String attribution,
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : municipalityId = Value(municipalityId),
       bundleVersion = Value(bundleVersion),
       sha256 = Value(sha256),
       generatedAt = Value(generatedAt),
       nameJa = Value(nameJa),
       nameKana = Value(nameKana),
       nameEn = Value(nameEn),
       attribution = Value(attribution),
       importedAt = Value(importedAt);
  static Insertable<StoredBundle> custom({
    Expression<String>? municipalityId,
    Expression<int>? bundleVersion,
    Expression<String>? sha256,
    Expression<String>? generatedAt,
    Expression<String>? nameJa,
    Expression<String>? nameKana,
    Expression<String>? nameEn,
    Expression<String>? attribution,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (bundleVersion != null) 'bundle_version': bundleVersion,
      if (sha256 != null) 'sha256': sha256,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameKana != null) 'name_kana': nameKana,
      if (nameEn != null) 'name_en': nameEn,
      if (attribution != null) 'attribution': attribution,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BundlesCompanion copyWith({
    Value<String>? municipalityId,
    Value<int>? bundleVersion,
    Value<String>? sha256,
    Value<String>? generatedAt,
    Value<String>? nameJa,
    Value<String>? nameKana,
    Value<String>? nameEn,
    Value<String>? attribution,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return BundlesCompanion(
      municipalityId: municipalityId ?? this.municipalityId,
      bundleVersion: bundleVersion ?? this.bundleVersion,
      sha256: sha256 ?? this.sha256,
      generatedAt: generatedAt ?? this.generatedAt,
      nameJa: nameJa ?? this.nameJa,
      nameKana: nameKana ?? this.nameKana,
      nameEn: nameEn ?? this.nameEn,
      attribution: attribution ?? this.attribution,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (bundleVersion.present) {
      map['bundle_version'] = Variable<int>(bundleVersion.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<String>(generatedAt.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameKana.present) {
      map['name_kana'] = Variable<String>(nameKana.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BundlesCompanion(')
          ..write('municipalityId: $municipalityId, ')
          ..write('bundleVersion: $bundleVersion, ')
          ..write('sha256: $sha256, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('attribution: $attribution, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WardsTable extends Wards with TableInfo<$WardsTable, Ward> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
    'name_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKanaMeta = const VerificationMeta(
    'nameKana',
  );
  @override
  late final GeneratedColumn<String> nameKana = GeneratedColumn<String>(
    'name_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    municipalityId,
    nameJa,
    nameKana,
    nameEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ward> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(
        _nameJaMeta,
        nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('name_kana')) {
      context.handle(
        _nameKanaMeta,
        nameKana.isAcceptableOrUnknown(data['name_kana']!, _nameKanaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKanaMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ward map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ward(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      nameJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ja'],
      )!,
      nameKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kana'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
    );
  }

  @override
  $WardsTable createAlias(String alias) {
    return $WardsTable(attachedDatabase, alias);
  }
}

class Ward extends DataClass implements Insertable<Ward> {
  final String id;
  final String municipalityId;
  final String nameJa;
  final String nameKana;
  final String nameEn;
  const Ward({
    required this.id,
    required this.municipalityId,
    required this.nameJa,
    required this.nameKana,
    required this.nameEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['municipality_id'] = Variable<String>(municipalityId);
    map['name_ja'] = Variable<String>(nameJa);
    map['name_kana'] = Variable<String>(nameKana);
    map['name_en'] = Variable<String>(nameEn);
    return map;
  }

  WardsCompanion toCompanion(bool nullToAbsent) {
    return WardsCompanion(
      id: Value(id),
      municipalityId: Value(municipalityId),
      nameJa: Value(nameJa),
      nameKana: Value(nameKana),
      nameEn: Value(nameEn),
    );
  }

  factory Ward.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ward(
      id: serializer.fromJson<String>(json['id']),
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameKana: serializer.fromJson<String>(json['nameKana']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'municipalityId': serializer.toJson<String>(municipalityId),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameKana': serializer.toJson<String>(nameKana),
      'nameEn': serializer.toJson<String>(nameEn),
    };
  }

  Ward copyWith({
    String? id,
    String? municipalityId,
    String? nameJa,
    String? nameKana,
    String? nameEn,
  }) => Ward(
    id: id ?? this.id,
    municipalityId: municipalityId ?? this.municipalityId,
    nameJa: nameJa ?? this.nameJa,
    nameKana: nameKana ?? this.nameKana,
    nameEn: nameEn ?? this.nameEn,
  );
  Ward copyWithCompanion(WardsCompanion data) {
    return Ward(
      id: data.id.present ? data.id.value : this.id,
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameKana: data.nameKana.present ? data.nameKana.value : this.nameKana,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ward(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, municipalityId, nameJa, nameKana, nameEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ward &&
          other.id == this.id &&
          other.municipalityId == this.municipalityId &&
          other.nameJa == this.nameJa &&
          other.nameKana == this.nameKana &&
          other.nameEn == this.nameEn);
}

class WardsCompanion extends UpdateCompanion<Ward> {
  final Value<String> id;
  final Value<String> municipalityId;
  final Value<String> nameJa;
  final Value<String> nameKana;
  final Value<String> nameEn;
  final Value<int> rowid;
  const WardsCompanion({
    this.id = const Value.absent(),
    this.municipalityId = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameKana = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WardsCompanion.insert({
    required String id,
    required String municipalityId,
    required String nameJa,
    required String nameKana,
    required String nameEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       municipalityId = Value(municipalityId),
       nameJa = Value(nameJa),
       nameKana = Value(nameKana),
       nameEn = Value(nameEn);
  static Insertable<Ward> custom({
    Expression<String>? id,
    Expression<String>? municipalityId,
    Expression<String>? nameJa,
    Expression<String>? nameKana,
    Expression<String>? nameEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameKana != null) 'name_kana': nameKana,
      if (nameEn != null) 'name_en': nameEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WardsCompanion copyWith({
    Value<String>? id,
    Value<String>? municipalityId,
    Value<String>? nameJa,
    Value<String>? nameKana,
    Value<String>? nameEn,
    Value<int>? rowid,
  }) {
    return WardsCompanion(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      nameJa: nameJa ?? this.nameJa,
      nameKana: nameKana ?? this.nameKana,
      nameEn: nameEn ?? this.nameEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameKana.present) {
      map['name_kana'] = Variable<String>(nameKana.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardsCompanion(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AreasTable extends Areas with TableInfo<$AreasTable, Area> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wardIdMeta = const VerificationMeta('wardId');
  @override
  late final GeneratedColumn<String> wardId = GeneratedColumn<String>(
    'ward_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
    'name_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKanaMeta = const VerificationMeta(
    'nameKana',
  );
  @override
  late final GeneratedColumn<String> nameKana = GeneratedColumn<String>(
    'name_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _townJaMeta = const VerificationMeta('townJa');
  @override
  late final GeneratedColumn<String> townJa = GeneratedColumn<String>(
    'town_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _townKanaMeta = const VerificationMeta(
    'townKana',
  );
  @override
  late final GeneratedColumn<String> townKana = GeneratedColumn<String>(
    'town_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _townEnMeta = const VerificationMeta('townEn');
  @override
  late final GeneratedColumn<String> townEn = GeneratedColumn<String>(
    'town_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chomeMeta = const VerificationMeta('chome');
  @override
  late final GeneratedColumn<int> chome = GeneratedColumn<int>(
    'chome',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    municipalityId,
    wardId,
    nameJa,
    nameKana,
    nameEn,
    townJa,
    townKana,
    townEn,
    chome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Area> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('ward_id')) {
      context.handle(
        _wardIdMeta,
        wardId.isAcceptableOrUnknown(data['ward_id']!, _wardIdMeta),
      );
    }
    if (data.containsKey('name_ja')) {
      context.handle(
        _nameJaMeta,
        nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('name_kana')) {
      context.handle(
        _nameKanaMeta,
        nameKana.isAcceptableOrUnknown(data['name_kana']!, _nameKanaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKanaMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('town_ja')) {
      context.handle(
        _townJaMeta,
        townJa.isAcceptableOrUnknown(data['town_ja']!, _townJaMeta),
      );
    } else if (isInserting) {
      context.missing(_townJaMeta);
    }
    if (data.containsKey('town_kana')) {
      context.handle(
        _townKanaMeta,
        townKana.isAcceptableOrUnknown(data['town_kana']!, _townKanaMeta),
      );
    } else if (isInserting) {
      context.missing(_townKanaMeta);
    }
    if (data.containsKey('town_en')) {
      context.handle(
        _townEnMeta,
        townEn.isAcceptableOrUnknown(data['town_en']!, _townEnMeta),
      );
    } else if (isInserting) {
      context.missing(_townEnMeta);
    }
    if (data.containsKey('chome')) {
      context.handle(
        _chomeMeta,
        chome.isAcceptableOrUnknown(data['chome']!, _chomeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Area map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Area(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      wardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ward_id'],
      ),
      nameJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ja'],
      )!,
      nameKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kana'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      townJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}town_ja'],
      )!,
      townKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}town_kana'],
      )!,
      townEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}town_en'],
      )!,
      chome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chome'],
      ),
    );
  }

  @override
  $AreasTable createAlias(String alias) {
    return $AreasTable(attachedDatabase, alias);
  }
}

class Area extends DataClass implements Insertable<Area> {
  final String id;
  final String municipalityId;
  final String? wardId;
  final String nameJa;
  final String nameKana;
  final String nameEn;
  final String townJa;
  final String townKana;
  final String townEn;
  final int? chome;
  const Area({
    required this.id,
    required this.municipalityId,
    this.wardId,
    required this.nameJa,
    required this.nameKana,
    required this.nameEn,
    required this.townJa,
    required this.townKana,
    required this.townEn,
    this.chome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['municipality_id'] = Variable<String>(municipalityId);
    if (!nullToAbsent || wardId != null) {
      map['ward_id'] = Variable<String>(wardId);
    }
    map['name_ja'] = Variable<String>(nameJa);
    map['name_kana'] = Variable<String>(nameKana);
    map['name_en'] = Variable<String>(nameEn);
    map['town_ja'] = Variable<String>(townJa);
    map['town_kana'] = Variable<String>(townKana);
    map['town_en'] = Variable<String>(townEn);
    if (!nullToAbsent || chome != null) {
      map['chome'] = Variable<int>(chome);
    }
    return map;
  }

  AreasCompanion toCompanion(bool nullToAbsent) {
    return AreasCompanion(
      id: Value(id),
      municipalityId: Value(municipalityId),
      wardId: wardId == null && nullToAbsent
          ? const Value.absent()
          : Value(wardId),
      nameJa: Value(nameJa),
      nameKana: Value(nameKana),
      nameEn: Value(nameEn),
      townJa: Value(townJa),
      townKana: Value(townKana),
      townEn: Value(townEn),
      chome: chome == null && nullToAbsent
          ? const Value.absent()
          : Value(chome),
    );
  }

  factory Area.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Area(
      id: serializer.fromJson<String>(json['id']),
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      wardId: serializer.fromJson<String?>(json['wardId']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameKana: serializer.fromJson<String>(json['nameKana']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      townJa: serializer.fromJson<String>(json['townJa']),
      townKana: serializer.fromJson<String>(json['townKana']),
      townEn: serializer.fromJson<String>(json['townEn']),
      chome: serializer.fromJson<int?>(json['chome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'municipalityId': serializer.toJson<String>(municipalityId),
      'wardId': serializer.toJson<String?>(wardId),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameKana': serializer.toJson<String>(nameKana),
      'nameEn': serializer.toJson<String>(nameEn),
      'townJa': serializer.toJson<String>(townJa),
      'townKana': serializer.toJson<String>(townKana),
      'townEn': serializer.toJson<String>(townEn),
      'chome': serializer.toJson<int?>(chome),
    };
  }

  Area copyWith({
    String? id,
    String? municipalityId,
    Value<String?> wardId = const Value.absent(),
    String? nameJa,
    String? nameKana,
    String? nameEn,
    String? townJa,
    String? townKana,
    String? townEn,
    Value<int?> chome = const Value.absent(),
  }) => Area(
    id: id ?? this.id,
    municipalityId: municipalityId ?? this.municipalityId,
    wardId: wardId.present ? wardId.value : this.wardId,
    nameJa: nameJa ?? this.nameJa,
    nameKana: nameKana ?? this.nameKana,
    nameEn: nameEn ?? this.nameEn,
    townJa: townJa ?? this.townJa,
    townKana: townKana ?? this.townKana,
    townEn: townEn ?? this.townEn,
    chome: chome.present ? chome.value : this.chome,
  );
  Area copyWithCompanion(AreasCompanion data) {
    return Area(
      id: data.id.present ? data.id.value : this.id,
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      wardId: data.wardId.present ? data.wardId.value : this.wardId,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameKana: data.nameKana.present ? data.nameKana.value : this.nameKana,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      townJa: data.townJa.present ? data.townJa.value : this.townJa,
      townKana: data.townKana.present ? data.townKana.value : this.townKana,
      townEn: data.townEn.present ? data.townEn.value : this.townEn,
      chome: data.chome.present ? data.chome.value : this.chome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Area(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('wardId: $wardId, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('townJa: $townJa, ')
          ..write('townKana: $townKana, ')
          ..write('townEn: $townEn, ')
          ..write('chome: $chome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    municipalityId,
    wardId,
    nameJa,
    nameKana,
    nameEn,
    townJa,
    townKana,
    townEn,
    chome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Area &&
          other.id == this.id &&
          other.municipalityId == this.municipalityId &&
          other.wardId == this.wardId &&
          other.nameJa == this.nameJa &&
          other.nameKana == this.nameKana &&
          other.nameEn == this.nameEn &&
          other.townJa == this.townJa &&
          other.townKana == this.townKana &&
          other.townEn == this.townEn &&
          other.chome == this.chome);
}

class AreasCompanion extends UpdateCompanion<Area> {
  final Value<String> id;
  final Value<String> municipalityId;
  final Value<String?> wardId;
  final Value<String> nameJa;
  final Value<String> nameKana;
  final Value<String> nameEn;
  final Value<String> townJa;
  final Value<String> townKana;
  final Value<String> townEn;
  final Value<int?> chome;
  final Value<int> rowid;
  const AreasCompanion({
    this.id = const Value.absent(),
    this.municipalityId = const Value.absent(),
    this.wardId = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameKana = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.townJa = const Value.absent(),
    this.townKana = const Value.absent(),
    this.townEn = const Value.absent(),
    this.chome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AreasCompanion.insert({
    required String id,
    required String municipalityId,
    this.wardId = const Value.absent(),
    required String nameJa,
    required String nameKana,
    required String nameEn,
    required String townJa,
    required String townKana,
    required String townEn,
    this.chome = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       municipalityId = Value(municipalityId),
       nameJa = Value(nameJa),
       nameKana = Value(nameKana),
       nameEn = Value(nameEn),
       townJa = Value(townJa),
       townKana = Value(townKana),
       townEn = Value(townEn);
  static Insertable<Area> custom({
    Expression<String>? id,
    Expression<String>? municipalityId,
    Expression<String>? wardId,
    Expression<String>? nameJa,
    Expression<String>? nameKana,
    Expression<String>? nameEn,
    Expression<String>? townJa,
    Expression<String>? townKana,
    Expression<String>? townEn,
    Expression<int>? chome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (wardId != null) 'ward_id': wardId,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameKana != null) 'name_kana': nameKana,
      if (nameEn != null) 'name_en': nameEn,
      if (townJa != null) 'town_ja': townJa,
      if (townKana != null) 'town_kana': townKana,
      if (townEn != null) 'town_en': townEn,
      if (chome != null) 'chome': chome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AreasCompanion copyWith({
    Value<String>? id,
    Value<String>? municipalityId,
    Value<String?>? wardId,
    Value<String>? nameJa,
    Value<String>? nameKana,
    Value<String>? nameEn,
    Value<String>? townJa,
    Value<String>? townKana,
    Value<String>? townEn,
    Value<int?>? chome,
    Value<int>? rowid,
  }) {
    return AreasCompanion(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      wardId: wardId ?? this.wardId,
      nameJa: nameJa ?? this.nameJa,
      nameKana: nameKana ?? this.nameKana,
      nameEn: nameEn ?? this.nameEn,
      townJa: townJa ?? this.townJa,
      townKana: townKana ?? this.townKana,
      townEn: townEn ?? this.townEn,
      chome: chome ?? this.chome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (wardId.present) {
      map['ward_id'] = Variable<String>(wardId.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameKana.present) {
      map['name_kana'] = Variable<String>(nameKana.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (townJa.present) {
      map['town_ja'] = Variable<String>(townJa.value);
    }
    if (townKana.present) {
      map['town_kana'] = Variable<String>(townKana.value);
    }
    if (townEn.present) {
      map['town_en'] = Variable<String>(townEn.value);
    }
    if (chome.present) {
      map['chome'] = Variable<int>(chome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AreasCompanion(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('wardId: $wardId, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('townJa: $townJa, ')
          ..write('townKana: $townKana, ')
          ..write('townEn: $townEn, ')
          ..write('chome: $chome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, WasteCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
    'name_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKanaMeta = const VerificationMeta(
    'nameKana',
  );
  @override
  late final GeneratedColumn<String> nameKana = GeneratedColumn<String>(
    'name_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commonMeta = const VerificationMeta('common');
  @override
  late final GeneratedColumn<String> common = GeneratedColumn<String>(
    'common',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionJaMeta = const VerificationMeta(
    'descriptionJa',
  );
  @override
  late final GeneratedColumn<String> descriptionJa = GeneratedColumn<String>(
    'description_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionEnMeta = const VerificationMeta(
    'descriptionEn',
  );
  @override
  late final GeneratedColumn<String> descriptionEn = GeneratedColumn<String>(
    'description_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    municipalityId,
    id,
    nameJa,
    nameKana,
    nameEn,
    common,
    descriptionJa,
    descriptionEn,
    sourceUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<WasteCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(
        _nameJaMeta,
        nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('name_kana')) {
      context.handle(
        _nameKanaMeta,
        nameKana.isAcceptableOrUnknown(data['name_kana']!, _nameKanaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKanaMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('common')) {
      context.handle(
        _commonMeta,
        common.isAcceptableOrUnknown(data['common']!, _commonMeta),
      );
    } else if (isInserting) {
      context.missing(_commonMeta);
    }
    if (data.containsKey('description_ja')) {
      context.handle(
        _descriptionJaMeta,
        descriptionJa.isAcceptableOrUnknown(
          data['description_ja']!,
          _descriptionJaMeta,
        ),
      );
    }
    if (data.containsKey('description_en')) {
      context.handle(
        _descriptionEnMeta,
        descriptionEn.isAcceptableOrUnknown(
          data['description_en']!,
          _descriptionEnMeta,
        ),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {municipalityId, id};
  @override
  WasteCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WasteCategory(
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ja'],
      )!,
      nameKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kana'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      common: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}common'],
      )!,
      descriptionJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_ja'],
      ),
      descriptionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_en'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class WasteCategory extends DataClass implements Insertable<WasteCategory> {
  final String municipalityId;
  final String id;
  final String nameJa;
  final String nameKana;
  final String nameEn;

  /// One of the shared set that drives icons and colours (`burnable`, …).
  final String common;
  final String? descriptionJa;
  final String? descriptionEn;
  final String? sourceUrl;
  const WasteCategory({
    required this.municipalityId,
    required this.id,
    required this.nameJa,
    required this.nameKana,
    required this.nameEn,
    required this.common,
    this.descriptionJa,
    this.descriptionEn,
    this.sourceUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['municipality_id'] = Variable<String>(municipalityId);
    map['id'] = Variable<String>(id);
    map['name_ja'] = Variable<String>(nameJa);
    map['name_kana'] = Variable<String>(nameKana);
    map['name_en'] = Variable<String>(nameEn);
    map['common'] = Variable<String>(common);
    if (!nullToAbsent || descriptionJa != null) {
      map['description_ja'] = Variable<String>(descriptionJa);
    }
    if (!nullToAbsent || descriptionEn != null) {
      map['description_en'] = Variable<String>(descriptionEn);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      municipalityId: Value(municipalityId),
      id: Value(id),
      nameJa: Value(nameJa),
      nameKana: Value(nameKana),
      nameEn: Value(nameEn),
      common: Value(common),
      descriptionJa: descriptionJa == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionJa),
      descriptionEn: descriptionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionEn),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
    );
  }

  factory WasteCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WasteCategory(
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      id: serializer.fromJson<String>(json['id']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameKana: serializer.fromJson<String>(json['nameKana']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      common: serializer.fromJson<String>(json['common']),
      descriptionJa: serializer.fromJson<String?>(json['descriptionJa']),
      descriptionEn: serializer.fromJson<String?>(json['descriptionEn']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'municipalityId': serializer.toJson<String>(municipalityId),
      'id': serializer.toJson<String>(id),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameKana': serializer.toJson<String>(nameKana),
      'nameEn': serializer.toJson<String>(nameEn),
      'common': serializer.toJson<String>(common),
      'descriptionJa': serializer.toJson<String?>(descriptionJa),
      'descriptionEn': serializer.toJson<String?>(descriptionEn),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
    };
  }

  WasteCategory copyWith({
    String? municipalityId,
    String? id,
    String? nameJa,
    String? nameKana,
    String? nameEn,
    String? common,
    Value<String?> descriptionJa = const Value.absent(),
    Value<String?> descriptionEn = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
  }) => WasteCategory(
    municipalityId: municipalityId ?? this.municipalityId,
    id: id ?? this.id,
    nameJa: nameJa ?? this.nameJa,
    nameKana: nameKana ?? this.nameKana,
    nameEn: nameEn ?? this.nameEn,
    common: common ?? this.common,
    descriptionJa: descriptionJa.present
        ? descriptionJa.value
        : this.descriptionJa,
    descriptionEn: descriptionEn.present
        ? descriptionEn.value
        : this.descriptionEn,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
  );
  WasteCategory copyWithCompanion(CategoriesCompanion data) {
    return WasteCategory(
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      id: data.id.present ? data.id.value : this.id,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameKana: data.nameKana.present ? data.nameKana.value : this.nameKana,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      common: data.common.present ? data.common.value : this.common,
      descriptionJa: data.descriptionJa.present
          ? data.descriptionJa.value
          : this.descriptionJa,
      descriptionEn: data.descriptionEn.present
          ? data.descriptionEn.value
          : this.descriptionEn,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WasteCategory(')
          ..write('municipalityId: $municipalityId, ')
          ..write('id: $id, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('common: $common, ')
          ..write('descriptionJa: $descriptionJa, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('sourceUrl: $sourceUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    municipalityId,
    id,
    nameJa,
    nameKana,
    nameEn,
    common,
    descriptionJa,
    descriptionEn,
    sourceUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WasteCategory &&
          other.municipalityId == this.municipalityId &&
          other.id == this.id &&
          other.nameJa == this.nameJa &&
          other.nameKana == this.nameKana &&
          other.nameEn == this.nameEn &&
          other.common == this.common &&
          other.descriptionJa == this.descriptionJa &&
          other.descriptionEn == this.descriptionEn &&
          other.sourceUrl == this.sourceUrl);
}

class CategoriesCompanion extends UpdateCompanion<WasteCategory> {
  final Value<String> municipalityId;
  final Value<String> id;
  final Value<String> nameJa;
  final Value<String> nameKana;
  final Value<String> nameEn;
  final Value<String> common;
  final Value<String?> descriptionJa;
  final Value<String?> descriptionEn;
  final Value<String?> sourceUrl;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.municipalityId = const Value.absent(),
    this.id = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameKana = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.common = const Value.absent(),
    this.descriptionJa = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String municipalityId,
    required String id,
    required String nameJa,
    required String nameKana,
    required String nameEn,
    required String common,
    this.descriptionJa = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : municipalityId = Value(municipalityId),
       id = Value(id),
       nameJa = Value(nameJa),
       nameKana = Value(nameKana),
       nameEn = Value(nameEn),
       common = Value(common);
  static Insertable<WasteCategory> custom({
    Expression<String>? municipalityId,
    Expression<String>? id,
    Expression<String>? nameJa,
    Expression<String>? nameKana,
    Expression<String>? nameEn,
    Expression<String>? common,
    Expression<String>? descriptionJa,
    Expression<String>? descriptionEn,
    Expression<String>? sourceUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (id != null) 'id': id,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameKana != null) 'name_kana': nameKana,
      if (nameEn != null) 'name_en': nameEn,
      if (common != null) 'common': common,
      if (descriptionJa != null) 'description_ja': descriptionJa,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? municipalityId,
    Value<String>? id,
    Value<String>? nameJa,
    Value<String>? nameKana,
    Value<String>? nameEn,
    Value<String>? common,
    Value<String?>? descriptionJa,
    Value<String?>? descriptionEn,
    Value<String?>? sourceUrl,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      municipalityId: municipalityId ?? this.municipalityId,
      id: id ?? this.id,
      nameJa: nameJa ?? this.nameJa,
      nameKana: nameKana ?? this.nameKana,
      nameEn: nameEn ?? this.nameEn,
      common: common ?? this.common,
      descriptionJa: descriptionJa ?? this.descriptionJa,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameKana.present) {
      map['name_kana'] = Variable<String>(nameKana.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (common.present) {
      map['common'] = Variable<String>(common.value);
    }
    if (descriptionJa.present) {
      map['description_ja'] = Variable<String>(descriptionJa.value);
    }
    if (descriptionEn.present) {
      map['description_en'] = Variable<String>(descriptionEn.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('municipalityId: $municipalityId, ')
          ..write('id: $id, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('common: $common, ')
          ..write('descriptionJa: $descriptionJa, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RulesTable extends Rules with TableInfo<$RulesTable, Rule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
    'name_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKanaMeta = const VerificationMeta(
    'nameKana',
  );
  @override
  late final GeneratedColumn<String> nameKana = GeneratedColumn<String>(
    'name_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instructionsJaMeta = const VerificationMeta(
    'instructionsJa',
  );
  @override
  late final GeneratedColumn<String> instructionsJa = GeneratedColumn<String>(
    'instructions_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instructionsEnMeta = const VerificationMeta(
    'instructionsEn',
  );
  @override
  late final GeneratedColumn<String> instructionsEn = GeneratedColumn<String>(
    'instructions_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<String> validFrom = GeneratedColumn<String>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<String> validTo = GeneratedColumn<String>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<String> verifiedAt = GeneratedColumn<String>(
    'verified_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    municipalityId,
    itemId,
    nameJa,
    nameKana,
    nameEn,
    category,
    instructionsJa,
    instructionsEn,
    validFrom,
    validTo,
    sourceUrl,
    verifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<Rule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name_ja')) {
      context.handle(
        _nameJaMeta,
        nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameJaMeta);
    }
    if (data.containsKey('name_kana')) {
      context.handle(
        _nameKanaMeta,
        nameKana.isAcceptableOrUnknown(data['name_kana']!, _nameKanaMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKanaMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('instructions_ja')) {
      context.handle(
        _instructionsJaMeta,
        instructionsJa.isAcceptableOrUnknown(
          data['instructions_ja']!,
          _instructionsJaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionsJaMeta);
    }
    if (data.containsKey('instructions_en')) {
      context.handle(
        _instructionsEnMeta,
        instructionsEn.isAcceptableOrUnknown(
          data['instructions_en']!,
          _instructionsEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionsEnMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_verifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Rule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      nameJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ja'],
      )!,
      nameKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kana'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      instructionsJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions_ja'],
      )!,
      instructionsEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions_en'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_from'],
      )!,
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_to'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified_at'],
      )!,
    );
  }

  @override
  $RulesTable createAlias(String alias) {
    return $RulesTable(attachedDatabase, alias);
  }
}

class Rule extends DataClass implements Insertable<Rule> {
  final int id;
  final String municipalityId;
  final String itemId;
  final String nameJa;
  final String nameKana;
  final String nameEn;
  final String category;
  final String instructionsJa;
  final String instructionsEn;

  /// Inclusive `YYYY-MM-DD` dates in Japan time; no [validTo] means open-ended.
  final String validFrom;
  final String? validTo;
  final String sourceUrl;
  final String verifiedAt;
  const Rule({
    required this.id,
    required this.municipalityId,
    required this.itemId,
    required this.nameJa,
    required this.nameKana,
    required this.nameEn,
    required this.category,
    required this.instructionsJa,
    required this.instructionsEn,
    required this.validFrom,
    this.validTo,
    required this.sourceUrl,
    required this.verifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['municipality_id'] = Variable<String>(municipalityId);
    map['item_id'] = Variable<String>(itemId);
    map['name_ja'] = Variable<String>(nameJa);
    map['name_kana'] = Variable<String>(nameKana);
    map['name_en'] = Variable<String>(nameEn);
    map['category'] = Variable<String>(category);
    map['instructions_ja'] = Variable<String>(instructionsJa);
    map['instructions_en'] = Variable<String>(instructionsEn);
    map['valid_from'] = Variable<String>(validFrom);
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<String>(validTo);
    }
    map['source_url'] = Variable<String>(sourceUrl);
    map['verified_at'] = Variable<String>(verifiedAt);
    return map;
  }

  RulesCompanion toCompanion(bool nullToAbsent) {
    return RulesCompanion(
      id: Value(id),
      municipalityId: Value(municipalityId),
      itemId: Value(itemId),
      nameJa: Value(nameJa),
      nameKana: Value(nameKana),
      nameEn: Value(nameEn),
      category: Value(category),
      instructionsJa: Value(instructionsJa),
      instructionsEn: Value(instructionsEn),
      validFrom: Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      sourceUrl: Value(sourceUrl),
      verifiedAt: Value(verifiedAt),
    );
  }

  factory Rule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rule(
      id: serializer.fromJson<int>(json['id']),
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameKana: serializer.fromJson<String>(json['nameKana']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      category: serializer.fromJson<String>(json['category']),
      instructionsJa: serializer.fromJson<String>(json['instructionsJa']),
      instructionsEn: serializer.fromJson<String>(json['instructionsEn']),
      validFrom: serializer.fromJson<String>(json['validFrom']),
      validTo: serializer.fromJson<String?>(json['validTo']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      verifiedAt: serializer.fromJson<String>(json['verifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'municipalityId': serializer.toJson<String>(municipalityId),
      'itemId': serializer.toJson<String>(itemId),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameKana': serializer.toJson<String>(nameKana),
      'nameEn': serializer.toJson<String>(nameEn),
      'category': serializer.toJson<String>(category),
      'instructionsJa': serializer.toJson<String>(instructionsJa),
      'instructionsEn': serializer.toJson<String>(instructionsEn),
      'validFrom': serializer.toJson<String>(validFrom),
      'validTo': serializer.toJson<String?>(validTo),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'verifiedAt': serializer.toJson<String>(verifiedAt),
    };
  }

  Rule copyWith({
    int? id,
    String? municipalityId,
    String? itemId,
    String? nameJa,
    String? nameKana,
    String? nameEn,
    String? category,
    String? instructionsJa,
    String? instructionsEn,
    String? validFrom,
    Value<String?> validTo = const Value.absent(),
    String? sourceUrl,
    String? verifiedAt,
  }) => Rule(
    id: id ?? this.id,
    municipalityId: municipalityId ?? this.municipalityId,
    itemId: itemId ?? this.itemId,
    nameJa: nameJa ?? this.nameJa,
    nameKana: nameKana ?? this.nameKana,
    nameEn: nameEn ?? this.nameEn,
    category: category ?? this.category,
    instructionsJa: instructionsJa ?? this.instructionsJa,
    instructionsEn: instructionsEn ?? this.instructionsEn,
    validFrom: validFrom ?? this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    verifiedAt: verifiedAt ?? this.verifiedAt,
  );
  Rule copyWithCompanion(RulesCompanion data) {
    return Rule(
      id: data.id.present ? data.id.value : this.id,
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameKana: data.nameKana.present ? data.nameKana.value : this.nameKana,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      category: data.category.present ? data.category.value : this.category,
      instructionsJa: data.instructionsJa.present
          ? data.instructionsJa.value
          : this.instructionsJa,
      instructionsEn: data.instructionsEn.present
          ? data.instructionsEn.value
          : this.instructionsEn,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rule(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('itemId: $itemId, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('category: $category, ')
          ..write('instructionsJa: $instructionsJa, ')
          ..write('instructionsEn: $instructionsEn, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('verifiedAt: $verifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    municipalityId,
    itemId,
    nameJa,
    nameKana,
    nameEn,
    category,
    instructionsJa,
    instructionsEn,
    validFrom,
    validTo,
    sourceUrl,
    verifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rule &&
          other.id == this.id &&
          other.municipalityId == this.municipalityId &&
          other.itemId == this.itemId &&
          other.nameJa == this.nameJa &&
          other.nameKana == this.nameKana &&
          other.nameEn == this.nameEn &&
          other.category == this.category &&
          other.instructionsJa == this.instructionsJa &&
          other.instructionsEn == this.instructionsEn &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.sourceUrl == this.sourceUrl &&
          other.verifiedAt == this.verifiedAt);
}

class RulesCompanion extends UpdateCompanion<Rule> {
  final Value<int> id;
  final Value<String> municipalityId;
  final Value<String> itemId;
  final Value<String> nameJa;
  final Value<String> nameKana;
  final Value<String> nameEn;
  final Value<String> category;
  final Value<String> instructionsJa;
  final Value<String> instructionsEn;
  final Value<String> validFrom;
  final Value<String?> validTo;
  final Value<String> sourceUrl;
  final Value<String> verifiedAt;
  const RulesCompanion({
    this.id = const Value.absent(),
    this.municipalityId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameKana = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.category = const Value.absent(),
    this.instructionsJa = const Value.absent(),
    this.instructionsEn = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.verifiedAt = const Value.absent(),
  });
  RulesCompanion.insert({
    this.id = const Value.absent(),
    required String municipalityId,
    required String itemId,
    required String nameJa,
    required String nameKana,
    required String nameEn,
    required String category,
    required String instructionsJa,
    required String instructionsEn,
    required String validFrom,
    this.validTo = const Value.absent(),
    required String sourceUrl,
    required String verifiedAt,
  }) : municipalityId = Value(municipalityId),
       itemId = Value(itemId),
       nameJa = Value(nameJa),
       nameKana = Value(nameKana),
       nameEn = Value(nameEn),
       category = Value(category),
       instructionsJa = Value(instructionsJa),
       instructionsEn = Value(instructionsEn),
       validFrom = Value(validFrom),
       sourceUrl = Value(sourceUrl),
       verifiedAt = Value(verifiedAt);
  static Insertable<Rule> custom({
    Expression<int>? id,
    Expression<String>? municipalityId,
    Expression<String>? itemId,
    Expression<String>? nameJa,
    Expression<String>? nameKana,
    Expression<String>? nameEn,
    Expression<String>? category,
    Expression<String>? instructionsJa,
    Expression<String>? instructionsEn,
    Expression<String>? validFrom,
    Expression<String>? validTo,
    Expression<String>? sourceUrl,
    Expression<String>? verifiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (itemId != null) 'item_id': itemId,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameKana != null) 'name_kana': nameKana,
      if (nameEn != null) 'name_en': nameEn,
      if (category != null) 'category': category,
      if (instructionsJa != null) 'instructions_ja': instructionsJa,
      if (instructionsEn != null) 'instructions_en': instructionsEn,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (verifiedAt != null) 'verified_at': verifiedAt,
    });
  }

  RulesCompanion copyWith({
    Value<int>? id,
    Value<String>? municipalityId,
    Value<String>? itemId,
    Value<String>? nameJa,
    Value<String>? nameKana,
    Value<String>? nameEn,
    Value<String>? category,
    Value<String>? instructionsJa,
    Value<String>? instructionsEn,
    Value<String>? validFrom,
    Value<String?>? validTo,
    Value<String>? sourceUrl,
    Value<String>? verifiedAt,
  }) {
    return RulesCompanion(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      itemId: itemId ?? this.itemId,
      nameJa: nameJa ?? this.nameJa,
      nameKana: nameKana ?? this.nameKana,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      instructionsJa: instructionsJa ?? this.instructionsJa,
      instructionsEn: instructionsEn ?? this.instructionsEn,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameKana.present) {
      map['name_kana'] = Variable<String>(nameKana.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (instructionsJa.present) {
      map['instructions_ja'] = Variable<String>(instructionsJa.value);
    }
    if (instructionsEn.present) {
      map['instructions_en'] = Variable<String>(instructionsEn.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<String>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<String>(validTo.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<String>(verifiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulesCompanion(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('itemId: $itemId, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameKana: $nameKana, ')
          ..write('nameEn: $nameEn, ')
          ..write('category: $category, ')
          ..write('instructionsJa: $instructionsJa, ')
          ..write('instructionsEn: $instructionsEn, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('verifiedAt: $verifiedAt')
          ..write(')'))
        .toString();
  }
}

class $AliasesTable extends Aliases with TableInfo<$AliasesTable, RuleAlias> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<int> ruleId = GeneratedColumn<int>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ruleId, alias];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleAlias> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RuleAlias map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleAlias(
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
    );
  }

  @override
  $AliasesTable createAlias(String alias) {
    return $AliasesTable(attachedDatabase, alias);
  }
}

class RuleAlias extends DataClass implements Insertable<RuleAlias> {
  final int ruleId;
  final String alias;
  const RuleAlias({required this.ruleId, required this.alias});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rule_id'] = Variable<int>(ruleId);
    map['alias'] = Variable<String>(alias);
    return map;
  }

  AliasesCompanion toCompanion(bool nullToAbsent) {
    return AliasesCompanion(ruleId: Value(ruleId), alias: Value(alias));
  }

  factory RuleAlias.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleAlias(
      ruleId: serializer.fromJson<int>(json['ruleId']),
      alias: serializer.fromJson<String>(json['alias']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ruleId': serializer.toJson<int>(ruleId),
      'alias': serializer.toJson<String>(alias),
    };
  }

  RuleAlias copyWith({int? ruleId, String? alias}) =>
      RuleAlias(ruleId: ruleId ?? this.ruleId, alias: alias ?? this.alias);
  RuleAlias copyWithCompanion(AliasesCompanion data) {
    return RuleAlias(
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      alias: data.alias.present ? data.alias.value : this.alias,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleAlias(')
          ..write('ruleId: $ruleId, ')
          ..write('alias: $alias')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ruleId, alias);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleAlias &&
          other.ruleId == this.ruleId &&
          other.alias == this.alias);
}

class AliasesCompanion extends UpdateCompanion<RuleAlias> {
  final Value<int> ruleId;
  final Value<String> alias;
  final Value<int> rowid;
  const AliasesCompanion({
    this.ruleId = const Value.absent(),
    this.alias = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AliasesCompanion.insert({
    required int ruleId,
    required String alias,
    this.rowid = const Value.absent(),
  }) : ruleId = Value(ruleId),
       alias = Value(alias);
  static Insertable<RuleAlias> custom({
    Expression<int>? ruleId,
    Expression<String>? alias,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ruleId != null) 'rule_id': ruleId,
      if (alias != null) 'alias': alias,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AliasesCompanion copyWith({
    Value<int>? ruleId,
    Value<String>? alias,
    Value<int>? rowid,
  }) {
    return AliasesCompanion(
      ruleId: ruleId ?? this.ruleId,
      alias: alias ?? this.alias,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ruleId.present) {
      map['rule_id'] = Variable<int>(ruleId.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AliasesCompanion(')
          ..write('ruleId: $ruleId, ')
          ..write('alias: $alias, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarsTable extends Calendars
    with TableInfo<$CalendarsTable, CollectionCalendar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _putOutByMeta = const VerificationMeta(
    'putOutBy',
  );
  @override
  late final GeneratedColumn<String> putOutBy = GeneratedColumn<String>(
    'put_out_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<String> validFrom = GeneratedColumn<String>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<String> validTo = GeneratedColumn<String>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    municipalityId,
    id,
    categories,
    pattern,
    putOutBy,
    validFrom,
    validTo,
    sourceUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendars';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionCalendar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriesMeta);
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('put_out_by')) {
      context.handle(
        _putOutByMeta,
        putOutBy.isAcceptableOrUnknown(data['put_out_by']!, _putOutByMeta),
      );
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {municipalityId, id};
  @override
  CollectionCalendar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionCalendar(
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      )!,
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      )!,
      putOutBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}put_out_by'],
      ),
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_from'],
      )!,
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valid_to'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
    );
  }

  @override
  $CalendarsTable createAlias(String alias) {
    return $CalendarsTable(attachedDatabase, alias);
  }
}

class CollectionCalendar extends DataClass
    implements Insertable<CollectionCalendar> {
  final String municipalityId;
  final String id;

  /// JSON list of category ids collected on this pattern.
  final String categories;

  /// The bundle's `pattern` object as JSON (`weekly`, `monthly_nth_weekday`, …).
  /// Kept whole so an unknown pattern type can be skipped, not fail the import.
  final String pattern;
  final String? putOutBy;
  final String validFrom;
  final String? validTo;
  final String? sourceUrl;
  const CollectionCalendar({
    required this.municipalityId,
    required this.id,
    required this.categories,
    required this.pattern,
    this.putOutBy,
    required this.validFrom,
    this.validTo,
    this.sourceUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['municipality_id'] = Variable<String>(municipalityId);
    map['id'] = Variable<String>(id);
    map['categories'] = Variable<String>(categories);
    map['pattern'] = Variable<String>(pattern);
    if (!nullToAbsent || putOutBy != null) {
      map['put_out_by'] = Variable<String>(putOutBy);
    }
    map['valid_from'] = Variable<String>(validFrom);
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<String>(validTo);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    return map;
  }

  CalendarsCompanion toCompanion(bool nullToAbsent) {
    return CalendarsCompanion(
      municipalityId: Value(municipalityId),
      id: Value(id),
      categories: Value(categories),
      pattern: Value(pattern),
      putOutBy: putOutBy == null && nullToAbsent
          ? const Value.absent()
          : Value(putOutBy),
      validFrom: Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
    );
  }

  factory CollectionCalendar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionCalendar(
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      id: serializer.fromJson<String>(json['id']),
      categories: serializer.fromJson<String>(json['categories']),
      pattern: serializer.fromJson<String>(json['pattern']),
      putOutBy: serializer.fromJson<String?>(json['putOutBy']),
      validFrom: serializer.fromJson<String>(json['validFrom']),
      validTo: serializer.fromJson<String?>(json['validTo']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'municipalityId': serializer.toJson<String>(municipalityId),
      'id': serializer.toJson<String>(id),
      'categories': serializer.toJson<String>(categories),
      'pattern': serializer.toJson<String>(pattern),
      'putOutBy': serializer.toJson<String?>(putOutBy),
      'validFrom': serializer.toJson<String>(validFrom),
      'validTo': serializer.toJson<String?>(validTo),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
    };
  }

  CollectionCalendar copyWith({
    String? municipalityId,
    String? id,
    String? categories,
    String? pattern,
    Value<String?> putOutBy = const Value.absent(),
    String? validFrom,
    Value<String?> validTo = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
  }) => CollectionCalendar(
    municipalityId: municipalityId ?? this.municipalityId,
    id: id ?? this.id,
    categories: categories ?? this.categories,
    pattern: pattern ?? this.pattern,
    putOutBy: putOutBy.present ? putOutBy.value : this.putOutBy,
    validFrom: validFrom ?? this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
  );
  CollectionCalendar copyWithCompanion(CalendarsCompanion data) {
    return CollectionCalendar(
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      id: data.id.present ? data.id.value : this.id,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      putOutBy: data.putOutBy.present ? data.putOutBy.value : this.putOutBy,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionCalendar(')
          ..write('municipalityId: $municipalityId, ')
          ..write('id: $id, ')
          ..write('categories: $categories, ')
          ..write('pattern: $pattern, ')
          ..write('putOutBy: $putOutBy, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('sourceUrl: $sourceUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    municipalityId,
    id,
    categories,
    pattern,
    putOutBy,
    validFrom,
    validTo,
    sourceUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionCalendar &&
          other.municipalityId == this.municipalityId &&
          other.id == this.id &&
          other.categories == this.categories &&
          other.pattern == this.pattern &&
          other.putOutBy == this.putOutBy &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.sourceUrl == this.sourceUrl);
}

class CalendarsCompanion extends UpdateCompanion<CollectionCalendar> {
  final Value<String> municipalityId;
  final Value<String> id;
  final Value<String> categories;
  final Value<String> pattern;
  final Value<String?> putOutBy;
  final Value<String> validFrom;
  final Value<String?> validTo;
  final Value<String?> sourceUrl;
  final Value<int> rowid;
  const CalendarsCompanion({
    this.municipalityId = const Value.absent(),
    this.id = const Value.absent(),
    this.categories = const Value.absent(),
    this.pattern = const Value.absent(),
    this.putOutBy = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarsCompanion.insert({
    required String municipalityId,
    required String id,
    required String categories,
    required String pattern,
    this.putOutBy = const Value.absent(),
    required String validFrom,
    this.validTo = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : municipalityId = Value(municipalityId),
       id = Value(id),
       categories = Value(categories),
       pattern = Value(pattern),
       validFrom = Value(validFrom);
  static Insertable<CollectionCalendar> custom({
    Expression<String>? municipalityId,
    Expression<String>? id,
    Expression<String>? categories,
    Expression<String>? pattern,
    Expression<String>? putOutBy,
    Expression<String>? validFrom,
    Expression<String>? validTo,
    Expression<String>? sourceUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (id != null) 'id': id,
      if (categories != null) 'categories': categories,
      if (pattern != null) 'pattern': pattern,
      if (putOutBy != null) 'put_out_by': putOutBy,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarsCompanion copyWith({
    Value<String>? municipalityId,
    Value<String>? id,
    Value<String>? categories,
    Value<String>? pattern,
    Value<String?>? putOutBy,
    Value<String>? validFrom,
    Value<String?>? validTo,
    Value<String?>? sourceUrl,
    Value<int>? rowid,
  }) {
    return CalendarsCompanion(
      municipalityId: municipalityId ?? this.municipalityId,
      id: id ?? this.id,
      categories: categories ?? this.categories,
      pattern: pattern ?? this.pattern,
      putOutBy: putOutBy ?? this.putOutBy,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (putOutBy.present) {
      map['put_out_by'] = Variable<String>(putOutBy.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<String>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<String>(validTo.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarsCompanion(')
          ..write('municipalityId: $municipalityId, ')
          ..write('id: $id, ')
          ..write('categories: $categories, ')
          ..write('pattern: $pattern, ')
          ..write('putOutBy: $putOutBy, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarAreasTable extends CalendarAreas
    with TableInfo<$CalendarAreasTable, CalendarArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarAreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [municipalityId, calendarId, areaId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarArea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_areaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {municipalityId, calendarId, areaId};
  @override
  CalendarArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarArea(
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_id'],
      )!,
    );
  }

  @override
  $CalendarAreasTable createAlias(String alias) {
    return $CalendarAreasTable(attachedDatabase, alias);
  }
}

class CalendarArea extends DataClass implements Insertable<CalendarArea> {
  final String municipalityId;
  final String calendarId;
  final String areaId;
  const CalendarArea({
    required this.municipalityId,
    required this.calendarId,
    required this.areaId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['municipality_id'] = Variable<String>(municipalityId);
    map['calendar_id'] = Variable<String>(calendarId);
    map['area_id'] = Variable<String>(areaId);
    return map;
  }

  CalendarAreasCompanion toCompanion(bool nullToAbsent) {
    return CalendarAreasCompanion(
      municipalityId: Value(municipalityId),
      calendarId: Value(calendarId),
      areaId: Value(areaId),
    );
  }

  factory CalendarArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarArea(
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      areaId: serializer.fromJson<String>(json['areaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'municipalityId': serializer.toJson<String>(municipalityId),
      'calendarId': serializer.toJson<String>(calendarId),
      'areaId': serializer.toJson<String>(areaId),
    };
  }

  CalendarArea copyWith({
    String? municipalityId,
    String? calendarId,
    String? areaId,
  }) => CalendarArea(
    municipalityId: municipalityId ?? this.municipalityId,
    calendarId: calendarId ?? this.calendarId,
    areaId: areaId ?? this.areaId,
  );
  CalendarArea copyWithCompanion(CalendarAreasCompanion data) {
    return CalendarArea(
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarArea(')
          ..write('municipalityId: $municipalityId, ')
          ..write('calendarId: $calendarId, ')
          ..write('areaId: $areaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(municipalityId, calendarId, areaId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarArea &&
          other.municipalityId == this.municipalityId &&
          other.calendarId == this.calendarId &&
          other.areaId == this.areaId);
}

class CalendarAreasCompanion extends UpdateCompanion<CalendarArea> {
  final Value<String> municipalityId;
  final Value<String> calendarId;
  final Value<String> areaId;
  final Value<int> rowid;
  const CalendarAreasCompanion({
    this.municipalityId = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.areaId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarAreasCompanion.insert({
    required String municipalityId,
    required String calendarId,
    required String areaId,
    this.rowid = const Value.absent(),
  }) : municipalityId = Value(municipalityId),
       calendarId = Value(calendarId),
       areaId = Value(areaId);
  static Insertable<CalendarArea> custom({
    Expression<String>? municipalityId,
    Expression<String>? calendarId,
    Expression<String>? areaId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (calendarId != null) 'calendar_id': calendarId,
      if (areaId != null) 'area_id': areaId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarAreasCompanion copyWith({
    Value<String>? municipalityId,
    Value<String>? calendarId,
    Value<String>? areaId,
    Value<int>? rowid,
  }) {
    return CalendarAreasCompanion(
      municipalityId: municipalityId ?? this.municipalityId,
      calendarId: calendarId ?? this.calendarId,
      areaId: areaId ?? this.areaId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarAreasCompanion(')
          ..write('municipalityId: $municipalityId, ')
          ..write('calendarId: $calendarId, ')
          ..write('areaId: $areaId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionExceptionsTable extends CollectionExceptions
    with TableInfo<$CollectionExceptionsTable, CollectionException> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionExceptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _municipalityIdMeta = const VerificationMeta(
    'municipalityId',
  );
  @override
  late final GeneratedColumn<String> municipalityId = GeneratedColumn<String>(
    'municipality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdsMeta = const VerificationMeta(
    'areaIds',
  );
  @override
  late final GeneratedColumn<String> areaIds = GeneratedColumn<String>(
    'area_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteJaMeta = const VerificationMeta('noteJa');
  @override
  late final GeneratedColumn<String> noteJa = GeneratedColumn<String>(
    'note_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteEnMeta = const VerificationMeta('noteEn');
  @override
  late final GeneratedColumn<String> noteEn = GeneratedColumn<String>(
    'note_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    municipalityId,
    date,
    type,
    categories,
    areaIds,
    noteJa,
    noteEn,
    sourceUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionException> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('municipality_id')) {
      context.handle(
        _municipalityIdMeta,
        municipalityId.isAcceptableOrUnknown(
          data['municipality_id']!,
          _municipalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    }
    if (data.containsKey('area_ids')) {
      context.handle(
        _areaIdsMeta,
        areaIds.isAcceptableOrUnknown(data['area_ids']!, _areaIdsMeta),
      );
    }
    if (data.containsKey('note_ja')) {
      context.handle(
        _noteJaMeta,
        noteJa.isAcceptableOrUnknown(data['note_ja']!, _noteJaMeta),
      );
    }
    if (data.containsKey('note_en')) {
      context.handle(
        _noteEnMeta,
        noteEn.isAcceptableOrUnknown(data['note_en']!, _noteEnMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionException map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionException(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      municipalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      ),
      areaIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_ids'],
      ),
      noteJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_ja'],
      ),
      noteEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_en'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
    );
  }

  @override
  $CollectionExceptionsTable createAlias(String alias) {
    return $CollectionExceptionsTable(attachedDatabase, alias);
  }
}

class CollectionException extends DataClass
    implements Insertable<CollectionException> {
  final int id;
  final String municipalityId;
  final String date;
  final String type;

  /// JSON lists; null means every category or every area.
  final String? categories;
  final String? areaIds;
  final String? noteJa;
  final String? noteEn;
  final String? sourceUrl;
  const CollectionException({
    required this.id,
    required this.municipalityId,
    required this.date,
    required this.type,
    this.categories,
    this.areaIds,
    this.noteJa,
    this.noteEn,
    this.sourceUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['municipality_id'] = Variable<String>(municipalityId);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || categories != null) {
      map['categories'] = Variable<String>(categories);
    }
    if (!nullToAbsent || areaIds != null) {
      map['area_ids'] = Variable<String>(areaIds);
    }
    if (!nullToAbsent || noteJa != null) {
      map['note_ja'] = Variable<String>(noteJa);
    }
    if (!nullToAbsent || noteEn != null) {
      map['note_en'] = Variable<String>(noteEn);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    return map;
  }

  CollectionExceptionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionExceptionsCompanion(
      id: Value(id),
      municipalityId: Value(municipalityId),
      date: Value(date),
      type: Value(type),
      categories: categories == null && nullToAbsent
          ? const Value.absent()
          : Value(categories),
      areaIds: areaIds == null && nullToAbsent
          ? const Value.absent()
          : Value(areaIds),
      noteJa: noteJa == null && nullToAbsent
          ? const Value.absent()
          : Value(noteJa),
      noteEn: noteEn == null && nullToAbsent
          ? const Value.absent()
          : Value(noteEn),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
    );
  }

  factory CollectionException.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionException(
      id: serializer.fromJson<int>(json['id']),
      municipalityId: serializer.fromJson<String>(json['municipalityId']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      categories: serializer.fromJson<String?>(json['categories']),
      areaIds: serializer.fromJson<String?>(json['areaIds']),
      noteJa: serializer.fromJson<String?>(json['noteJa']),
      noteEn: serializer.fromJson<String?>(json['noteEn']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'municipalityId': serializer.toJson<String>(municipalityId),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'categories': serializer.toJson<String?>(categories),
      'areaIds': serializer.toJson<String?>(areaIds),
      'noteJa': serializer.toJson<String?>(noteJa),
      'noteEn': serializer.toJson<String?>(noteEn),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
    };
  }

  CollectionException copyWith({
    int? id,
    String? municipalityId,
    String? date,
    String? type,
    Value<String?> categories = const Value.absent(),
    Value<String?> areaIds = const Value.absent(),
    Value<String?> noteJa = const Value.absent(),
    Value<String?> noteEn = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
  }) => CollectionException(
    id: id ?? this.id,
    municipalityId: municipalityId ?? this.municipalityId,
    date: date ?? this.date,
    type: type ?? this.type,
    categories: categories.present ? categories.value : this.categories,
    areaIds: areaIds.present ? areaIds.value : this.areaIds,
    noteJa: noteJa.present ? noteJa.value : this.noteJa,
    noteEn: noteEn.present ? noteEn.value : this.noteEn,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
  );
  CollectionException copyWithCompanion(CollectionExceptionsCompanion data) {
    return CollectionException(
      id: data.id.present ? data.id.value : this.id,
      municipalityId: data.municipalityId.present
          ? data.municipalityId.value
          : this.municipalityId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      areaIds: data.areaIds.present ? data.areaIds.value : this.areaIds,
      noteJa: data.noteJa.present ? data.noteJa.value : this.noteJa,
      noteEn: data.noteEn.present ? data.noteEn.value : this.noteEn,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionException(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('categories: $categories, ')
          ..write('areaIds: $areaIds, ')
          ..write('noteJa: $noteJa, ')
          ..write('noteEn: $noteEn, ')
          ..write('sourceUrl: $sourceUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    municipalityId,
    date,
    type,
    categories,
    areaIds,
    noteJa,
    noteEn,
    sourceUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionException &&
          other.id == this.id &&
          other.municipalityId == this.municipalityId &&
          other.date == this.date &&
          other.type == this.type &&
          other.categories == this.categories &&
          other.areaIds == this.areaIds &&
          other.noteJa == this.noteJa &&
          other.noteEn == this.noteEn &&
          other.sourceUrl == this.sourceUrl);
}

class CollectionExceptionsCompanion
    extends UpdateCompanion<CollectionException> {
  final Value<int> id;
  final Value<String> municipalityId;
  final Value<String> date;
  final Value<String> type;
  final Value<String?> categories;
  final Value<String?> areaIds;
  final Value<String?> noteJa;
  final Value<String?> noteEn;
  final Value<String?> sourceUrl;
  const CollectionExceptionsCompanion({
    this.id = const Value.absent(),
    this.municipalityId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.categories = const Value.absent(),
    this.areaIds = const Value.absent(),
    this.noteJa = const Value.absent(),
    this.noteEn = const Value.absent(),
    this.sourceUrl = const Value.absent(),
  });
  CollectionExceptionsCompanion.insert({
    this.id = const Value.absent(),
    required String municipalityId,
    required String date,
    required String type,
    this.categories = const Value.absent(),
    this.areaIds = const Value.absent(),
    this.noteJa = const Value.absent(),
    this.noteEn = const Value.absent(),
    this.sourceUrl = const Value.absent(),
  }) : municipalityId = Value(municipalityId),
       date = Value(date),
       type = Value(type);
  static Insertable<CollectionException> custom({
    Expression<int>? id,
    Expression<String>? municipalityId,
    Expression<String>? date,
    Expression<String>? type,
    Expression<String>? categories,
    Expression<String>? areaIds,
    Expression<String>? noteJa,
    Expression<String>? noteEn,
    Expression<String>? sourceUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (categories != null) 'categories': categories,
      if (areaIds != null) 'area_ids': areaIds,
      if (noteJa != null) 'note_ja': noteJa,
      if (noteEn != null) 'note_en': noteEn,
      if (sourceUrl != null) 'source_url': sourceUrl,
    });
  }

  CollectionExceptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? municipalityId,
    Value<String>? date,
    Value<String>? type,
    Value<String?>? categories,
    Value<String?>? areaIds,
    Value<String?>? noteJa,
    Value<String?>? noteEn,
    Value<String?>? sourceUrl,
  }) {
    return CollectionExceptionsCompanion(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      date: date ?? this.date,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      areaIds: areaIds ?? this.areaIds,
      noteJa: noteJa ?? this.noteJa,
      noteEn: noteEn ?? this.noteEn,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (municipalityId.present) {
      map['municipality_id'] = Variable<String>(municipalityId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (areaIds.present) {
      map['area_ids'] = Variable<String>(areaIds.value);
    }
    if (noteJa.present) {
      map['note_ja'] = Variable<String>(noteJa.value);
    }
    if (noteEn.present) {
      map['note_en'] = Variable<String>(noteEn.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionExceptionsCompanion(')
          ..write('id: $id, ')
          ..write('municipalityId: $municipalityId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('categories: $categories, ')
          ..write('areaIds: $areaIds, ')
          ..write('noteJa: $noteJa, ')
          ..write('noteEn: $noteEn, ')
          ..write('sourceUrl: $sourceUrl')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BundlesTable bundles = $BundlesTable(this);
  late final $WardsTable wards = $WardsTable(this);
  late final $AreasTable areas = $AreasTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RulesTable rules = $RulesTable(this);
  late final $AliasesTable aliases = $AliasesTable(this);
  late final $CalendarsTable calendars = $CalendarsTable(this);
  late final $CalendarAreasTable calendarAreas = $CalendarAreasTable(this);
  late final $CollectionExceptionsTable collectionExceptions =
      $CollectionExceptionsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index rulesMunicipality = Index(
    'rules_municipality',
    'CREATE INDEX rules_municipality ON rules (municipality_id)',
  );
  late final Index aliasesRule = Index(
    'aliases_rule',
    'CREATE INDEX aliases_rule ON aliases (rule_id)',
  );
  late final Index calendarAreasArea = Index(
    'calendar_areas_area',
    'CREATE INDEX calendar_areas_area ON calendar_areas (area_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bundles,
    wards,
    areas,
    categories,
    rules,
    aliases,
    calendars,
    calendarAreas,
    collectionExceptions,
    settings,
    rulesMunicipality,
    aliasesRule,
    calendarAreasArea,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('aliases', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BundlesTableCreateCompanionBuilder = BundlesCompanion Function({
  required String municipalityId,
  required int bundleVersion,
  required String sha256,
  required String generatedAt,
  required String nameJa,
  required String nameKana,
  required String nameEn,
  required String attribution,
  required DateTime importedAt,
  Value<int> rowid,
});
typedef $$BundlesTableUpdateCompanionBuilder = BundlesCompanion Function({
  Value<String> municipalityId,
  Value<int> bundleVersion,
  Value<String> sha256,
  Value<String> generatedAt,
  Value<String> nameJa,
  Value<String> nameKana,
  Value<String> nameEn,
  Value<String> attribution,
  Value<DateTime> importedAt,
  Value<int> rowid,
});

class $$BundlesTableFilterComposer
    extends Composer<_$AppDatabase, $BundlesTable> {
  $$BundlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bundleVersion => $composableBuilder(
    column: $table.bundleVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BundlesTableOrderingComposer
    extends Composer<_$AppDatabase, $BundlesTable> {
  $$BundlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bundleVersion => $composableBuilder(
    column: $table.bundleVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BundlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BundlesTable> {
  $$BundlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bundleVersion => $composableBuilder(
    column: $table.bundleVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameKana =>
      $composableBuilder(column: $table.nameKana, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$BundlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BundlesTable,
          StoredBundle,
          $$BundlesTableFilterComposer,
          $$BundlesTableOrderingComposer,
          $$BundlesTableAnnotationComposer,
          $$BundlesTableCreateCompanionBuilder,
          $$BundlesTableUpdateCompanionBuilder,
          (
            StoredBundle,
            BaseReferences<_$AppDatabase, $BundlesTable, StoredBundle>,
          ),
          StoredBundle,
          PrefetchHooks Function()
        > {
  $$BundlesTableTableManager(_$AppDatabase db, $BundlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BundlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BundlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BundlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> municipalityId = const Value.absent(),
                Value<int> bundleVersion = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> generatedAt = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameKana = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> attribution = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundlesCompanion(
                municipalityId: municipalityId,
                bundleVersion: bundleVersion,
                sha256: sha256,
                generatedAt: generatedAt,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                attribution: attribution,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String municipalityId,
                required int bundleVersion,
                required String sha256,
                required String generatedAt,
                required String nameJa,
                required String nameKana,
                required String nameEn,
                required String attribution,
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => BundlesCompanion.insert(
                municipalityId: municipalityId,
                bundleVersion: bundleVersion,
                sha256: sha256,
                generatedAt: generatedAt,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                attribution: attribution,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BundlesTable, StoredBundle>(table),
                  BaseReferences<_$AppDatabase, $BundlesTable, StoredBundle>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BundlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BundlesTable,
      StoredBundle,
      $$BundlesTableFilterComposer,
      $$BundlesTableOrderingComposer,
      $$BundlesTableAnnotationComposer,
      $$BundlesTableCreateCompanionBuilder,
      $$BundlesTableUpdateCompanionBuilder,
      (
        StoredBundle,
        BaseReferences<_$AppDatabase, $BundlesTable, StoredBundle>,
      ),
      StoredBundle,
      PrefetchHooks Function()
    >;
typedef $$WardsTableCreateCompanionBuilder = WardsCompanion Function({
  required String id,
  required String municipalityId,
  required String nameJa,
  required String nameKana,
  required String nameEn,
  Value<int> rowid,
});
typedef $$WardsTableUpdateCompanionBuilder = WardsCompanion Function({
  Value<String> id,
  Value<String> municipalityId,
  Value<String> nameJa,
  Value<String> nameKana,
  Value<String> nameEn,
  Value<int> rowid,
});

class $$WardsTableFilterComposer extends Composer<_$AppDatabase, $WardsTable> {
  $$WardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WardsTableOrderingComposer
    extends Composer<_$AppDatabase, $WardsTable> {
  $$WardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WardsTable> {
  $$WardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameKana =>
      $composableBuilder(column: $table.nameKana, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);
}

class $$WardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WardsTable,
          Ward,
          $$WardsTableFilterComposer,
          $$WardsTableOrderingComposer,
          $$WardsTableAnnotationComposer,
          $$WardsTableCreateCompanionBuilder,
          $$WardsTableUpdateCompanionBuilder,
          (Ward, BaseReferences<_$AppDatabase, $WardsTable, Ward>),
          Ward,
          PrefetchHooks Function()
        > {
  $$WardsTableTableManager(_$AppDatabase db, $WardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> municipalityId = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameKana = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WardsCompanion(
                id: id,
                municipalityId: municipalityId,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String municipalityId,
                required String nameJa,
                required String nameKana,
                required String nameEn,
                Value<int> rowid = const Value.absent(),
              }) => WardsCompanion.insert(
                id: id,
                municipalityId: municipalityId,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WardsTable, Ward>(table),
                  BaseReferences<_$AppDatabase, $WardsTable, Ward>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WardsTable,
      Ward,
      $$WardsTableFilterComposer,
      $$WardsTableOrderingComposer,
      $$WardsTableAnnotationComposer,
      $$WardsTableCreateCompanionBuilder,
      $$WardsTableUpdateCompanionBuilder,
      (Ward, BaseReferences<_$AppDatabase, $WardsTable, Ward>),
      Ward,
      PrefetchHooks Function()
    >;
typedef $$AreasTableCreateCompanionBuilder = AreasCompanion Function({
  required String id,
  required String municipalityId,
  Value<String?> wardId,
  required String nameJa,
  required String nameKana,
  required String nameEn,
  required String townJa,
  required String townKana,
  required String townEn,
  Value<int?> chome,
  Value<int> rowid,
});
typedef $$AreasTableUpdateCompanionBuilder = AreasCompanion Function({
  Value<String> id,
  Value<String> municipalityId,
  Value<String?> wardId,
  Value<String> nameJa,
  Value<String> nameKana,
  Value<String> nameEn,
  Value<String> townJa,
  Value<String> townKana,
  Value<String> townEn,
  Value<int?> chome,
  Value<int> rowid,
});

class $$AreasTableFilterComposer extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wardId => $composableBuilder(
    column: $table.wardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get townJa => $composableBuilder(
    column: $table.townJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get townKana => $composableBuilder(
    column: $table.townKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get townEn => $composableBuilder(
    column: $table.townEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chome => $composableBuilder(
    column: $table.chome,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AreasTableOrderingComposer
    extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wardId => $composableBuilder(
    column: $table.wardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get townJa => $composableBuilder(
    column: $table.townJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get townKana => $composableBuilder(
    column: $table.townKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get townEn => $composableBuilder(
    column: $table.townEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chome => $composableBuilder(
    column: $table.chome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wardId =>
      $composableBuilder(column: $table.wardId, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameKana =>
      $composableBuilder(column: $table.nameKana, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get townJa =>
      $composableBuilder(column: $table.townJa, builder: (column) => column);

  GeneratedColumn<String> get townKana =>
      $composableBuilder(column: $table.townKana, builder: (column) => column);

  GeneratedColumn<String> get townEn =>
      $composableBuilder(column: $table.townEn, builder: (column) => column);

  GeneratedColumn<int> get chome =>
      $composableBuilder(column: $table.chome, builder: (column) => column);
}

class $$AreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AreasTable,
          Area,
          $$AreasTableFilterComposer,
          $$AreasTableOrderingComposer,
          $$AreasTableAnnotationComposer,
          $$AreasTableCreateCompanionBuilder,
          $$AreasTableUpdateCompanionBuilder,
          (Area, BaseReferences<_$AppDatabase, $AreasTable, Area>),
          Area,
          PrefetchHooks Function()
        > {
  $$AreasTableTableManager(_$AppDatabase db, $AreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> municipalityId = const Value.absent(),
                Value<String?> wardId = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameKana = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> townJa = const Value.absent(),
                Value<String> townKana = const Value.absent(),
                Value<String> townEn = const Value.absent(),
                Value<int?> chome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion(
                id: id,
                municipalityId: municipalityId,
                wardId: wardId,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                townJa: townJa,
                townKana: townKana,
                townEn: townEn,
                chome: chome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String municipalityId,
                Value<String?> wardId = const Value.absent(),
                required String nameJa,
                required String nameKana,
                required String nameEn,
                required String townJa,
                required String townKana,
                required String townEn,
                Value<int?> chome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion.insert(
                id: id,
                municipalityId: municipalityId,
                wardId: wardId,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                townJa: townJa,
                townKana: townKana,
                townEn: townEn,
                chome: chome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AreasTable, Area>(table),
                  BaseReferences<_$AppDatabase, $AreasTable, Area>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AreasTable,
      Area,
      $$AreasTableFilterComposer,
      $$AreasTableOrderingComposer,
      $$AreasTableAnnotationComposer,
      $$AreasTableCreateCompanionBuilder,
      $$AreasTableUpdateCompanionBuilder,
      (Area, BaseReferences<_$AppDatabase, $AreasTable, Area>),
      Area,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String municipalityId,
  required String id,
  required String nameJa,
  required String nameKana,
  required String nameEn,
  required String common,
  Value<String?> descriptionJa,
  Value<String?> descriptionEn,
  Value<String?> sourceUrl,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> municipalityId,
  Value<String> id,
  Value<String> nameJa,
  Value<String> nameKana,
  Value<String> nameEn,
  Value<String> common,
  Value<String?> descriptionJa,
  Value<String?> descriptionEn,
  Value<String?> sourceUrl,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get common => $composableBuilder(
    column: $table.common,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionJa => $composableBuilder(
    column: $table.descriptionJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get common => $composableBuilder(
    column: $table.common,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionJa => $composableBuilder(
    column: $table.descriptionJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameKana =>
      $composableBuilder(column: $table.nameKana, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get common =>
      $composableBuilder(column: $table.common, builder: (column) => column);

  GeneratedColumn<String> get descriptionJa => $composableBuilder(
    column: $table.descriptionJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          WasteCategory,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            WasteCategory,
            BaseReferences<_$AppDatabase, $CategoriesTable, WasteCategory>,
          ),
          WasteCategory,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> municipalityId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameKana = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> common = const Value.absent(),
                Value<String?> descriptionJa = const Value.absent(),
                Value<String?> descriptionEn = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                municipalityId: municipalityId,
                id: id,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                common: common,
                descriptionJa: descriptionJa,
                descriptionEn: descriptionEn,
                sourceUrl: sourceUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String municipalityId,
                required String id,
                required String nameJa,
                required String nameKana,
                required String nameEn,
                required String common,
                Value<String?> descriptionJa = const Value.absent(),
                Value<String?> descriptionEn = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                municipalityId: municipalityId,
                id: id,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                common: common,
                descriptionJa: descriptionJa,
                descriptionEn: descriptionEn,
                sourceUrl: sourceUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, WasteCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CategoriesTable,
                    WasteCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      WasteCategory,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        WasteCategory,
        BaseReferences<_$AppDatabase, $CategoriesTable, WasteCategory>,
      ),
      WasteCategory,
      PrefetchHooks Function()
    >;
typedef $$RulesTableCreateCompanionBuilder = RulesCompanion Function({
  Value<int> id,
  required String municipalityId,
  required String itemId,
  required String nameJa,
  required String nameKana,
  required String nameEn,
  required String category,
  required String instructionsJa,
  required String instructionsEn,
  required String validFrom,
  Value<String?> validTo,
  required String sourceUrl,
  required String verifiedAt,
});
typedef $$RulesTableUpdateCompanionBuilder = RulesCompanion Function({
  Value<int> id,
  Value<String> municipalityId,
  Value<String> itemId,
  Value<String> nameJa,
  Value<String> nameKana,
  Value<String> nameEn,
  Value<String> category,
  Value<String> instructionsJa,
  Value<String> instructionsEn,
  Value<String> validFrom,
  Value<String?> validTo,
  Value<String> sourceUrl,
  Value<String> verifiedAt,
});

final class $$RulesTableReferences
    extends BaseReferences<_$AppDatabase, $RulesTable, Rule> {
  $$RulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AliasesTable, List<RuleAlias>> _aliasesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.aliases,
    aliasName: 'rules__id__aliases__rule_id',
  );

  $$AliasesTableProcessedTableManager get aliasesRefs {
    final manager = $$AliasesTableTableManager(
      $_db,
      $_db.aliases,
    ).filter((f) => f.ruleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_aliasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RulesTableFilterComposer extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructionsJa => $composableBuilder(
    column: $table.instructionsJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructionsEn => $composableBuilder(
    column: $table.instructionsEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> aliasesRefs(
    Expression<bool> Function($$AliasesTableFilterComposer f) f,
  ) {
    final $$AliasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aliases,
      getReferencedColumn: (t) => t.ruleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AliasesTableFilterComposer(
            $db: $db,
            $table: $db.aliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKana => $composableBuilder(
    column: $table.nameKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructionsJa => $composableBuilder(
    column: $table.instructionsJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructionsEn => $composableBuilder(
    column: $table.instructionsEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameKana =>
      $composableBuilder(column: $table.nameKana, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get instructionsJa => $composableBuilder(
    column: $table.instructionsJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instructionsEn => $composableBuilder(
    column: $table.instructionsEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<String> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  Expression<T> aliasesRefs<T extends Object>(
    Expression<T> Function($$AliasesTableAnnotationComposer a) f,
  ) {
    final $$AliasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aliases,
      getReferencedColumn: (t) => t.ruleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AliasesTableAnnotationComposer(
            $db: $db,
            $table: $db.aliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RulesTable,
          Rule,
          $$RulesTableFilterComposer,
          $$RulesTableOrderingComposer,
          $$RulesTableAnnotationComposer,
          $$RulesTableCreateCompanionBuilder,
          $$RulesTableUpdateCompanionBuilder,
          (Rule, $$RulesTableReferences),
          Rule,
          PrefetchHooks Function({bool aliasesRefs})
        > {
  $$RulesTableTableManager(_$AppDatabase db, $RulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> municipalityId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameKana = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> instructionsJa = const Value.absent(),
                Value<String> instructionsEn = const Value.absent(),
                Value<String> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> verifiedAt = const Value.absent(),
              }) => RulesCompanion(
                id: id,
                municipalityId: municipalityId,
                itemId: itemId,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                category: category,
                instructionsJa: instructionsJa,
                instructionsEn: instructionsEn,
                validFrom: validFrom,
                validTo: validTo,
                sourceUrl: sourceUrl,
                verifiedAt: verifiedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String municipalityId,
                required String itemId,
                required String nameJa,
                required String nameKana,
                required String nameEn,
                required String category,
                required String instructionsJa,
                required String instructionsEn,
                required String validFrom,
                Value<String?> validTo = const Value.absent(),
                required String sourceUrl,
                required String verifiedAt,
              }) => RulesCompanion.insert(
                id: id,
                municipalityId: municipalityId,
                itemId: itemId,
                nameJa: nameJa,
                nameKana: nameKana,
                nameEn: nameEn,
                category: category,
                instructionsJa: instructionsJa,
                instructionsEn: instructionsEn,
                validFrom: validFrom,
                validTo: validTo,
                sourceUrl: sourceUrl,
                verifiedAt: verifiedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RulesTable, Rule>(table),
                  $$RulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({aliasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (aliasesRefs) db.aliases],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aliasesRefs)
                    await $_getPrefetchedDataByColumns<
                      Rule,
                      $RulesTable,
                      RuleAlias,
                      $AliasesTable
                    >(
                      currentTable: table,
                      referencedTable: $$RulesTableReferences._aliasesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$RulesTableReferences(db, table, p0).aliasesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'rule_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RulesTable,
      Rule,
      $$RulesTableFilterComposer,
      $$RulesTableOrderingComposer,
      $$RulesTableAnnotationComposer,
      $$RulesTableCreateCompanionBuilder,
      $$RulesTableUpdateCompanionBuilder,
      (Rule, $$RulesTableReferences),
      Rule,
      PrefetchHooks Function({bool aliasesRefs})
    >;
typedef $$AliasesTableCreateCompanionBuilder = AliasesCompanion Function({
  required int ruleId,
  required String alias,
  Value<int> rowid,
});
typedef $$AliasesTableUpdateCompanionBuilder = AliasesCompanion Function({
  Value<int> ruleId,
  Value<String> alias,
  Value<int> rowid,
});

final class $$AliasesTableReferences
    extends BaseReferences<_$AppDatabase, $AliasesTable, RuleAlias> {
  $$AliasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RulesTable _ruleIdTable(_$AppDatabase db) =>
      db.rules.createAlias('aliases__rule_id__rules__id');

  $$RulesTableProcessedTableManager get ruleId {
    final $_column = $_itemColumn<int>('rule_id')!;

    final manager = $$RulesTableTableManager(
      $_db,
      $_db.rules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ruleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AliasesTableFilterComposer
    extends Composer<_$AppDatabase, $AliasesTable> {
  $$AliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  $$RulesTableFilterComposer get ruleId {
    final $$RulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RulesTableFilterComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $AliasesTable> {
  $$AliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  $$RulesTableOrderingComposer get ruleId {
    final $$RulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RulesTableOrderingComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AliasesTable> {
  $$AliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  $$RulesTableAnnotationComposer get ruleId {
    final $$RulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RulesTableAnnotationComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AliasesTable,
          RuleAlias,
          $$AliasesTableFilterComposer,
          $$AliasesTableOrderingComposer,
          $$AliasesTableAnnotationComposer,
          $$AliasesTableCreateCompanionBuilder,
          $$AliasesTableUpdateCompanionBuilder,
          (RuleAlias, $$AliasesTableReferences),
          RuleAlias,
          PrefetchHooks Function({bool ruleId})
        > {
  $$AliasesTableTableManager(_$AppDatabase db, $AliasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> ruleId = const Value.absent(),
            Value<String> alias = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AliasesCompanion(ruleId: ruleId, alias: alias, rowid: rowid),
          createCompanionCallback:
              ({
                required int ruleId,
                required String alias,
                Value<int> rowid = const Value.absent(),
              }) => AliasesCompanion.insert(
                ruleId: ruleId,
                alias: alias,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AliasesTable, RuleAlias>(table),
                  $$AliasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ruleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ruleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ruleId,
                        referencedTable: $$AliasesTableReferences._ruleIdTable(
                          db,
                        ),
                        referencedColumn: $$AliasesTableReferences
                            ._ruleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AliasesTable,
      RuleAlias,
      $$AliasesTableFilterComposer,
      $$AliasesTableOrderingComposer,
      $$AliasesTableAnnotationComposer,
      $$AliasesTableCreateCompanionBuilder,
      $$AliasesTableUpdateCompanionBuilder,
      (RuleAlias, $$AliasesTableReferences),
      RuleAlias,
      PrefetchHooks Function({bool ruleId})
    >;
typedef $$CalendarsTableCreateCompanionBuilder = CalendarsCompanion Function({
  required String municipalityId,
  required String id,
  required String categories,
  required String pattern,
  Value<String?> putOutBy,
  required String validFrom,
  Value<String?> validTo,
  Value<String?> sourceUrl,
  Value<int> rowid,
});
typedef $$CalendarsTableUpdateCompanionBuilder = CalendarsCompanion Function({
  Value<String> municipalityId,
  Value<String> id,
  Value<String> categories,
  Value<String> pattern,
  Value<String?> putOutBy,
  Value<String> validFrom,
  Value<String?> validTo,
  Value<String?> sourceUrl,
  Value<int> rowid,
});

class $$CalendarsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get putOutBy => $composableBuilder(
    column: $table.putOutBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get putOutBy => $composableBuilder(
    column: $table.putOutBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get putOutBy =>
      $composableBuilder(column: $table.putOutBy, builder: (column) => column);

  GeneratedColumn<String> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<String> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);
}

class $$CalendarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarsTable,
          CollectionCalendar,
          $$CalendarsTableFilterComposer,
          $$CalendarsTableOrderingComposer,
          $$CalendarsTableAnnotationComposer,
          $$CalendarsTableCreateCompanionBuilder,
          $$CalendarsTableUpdateCompanionBuilder,
          (
            CollectionCalendar,
            BaseReferences<_$AppDatabase, $CalendarsTable, CollectionCalendar>,
          ),
          CollectionCalendar,
          PrefetchHooks Function()
        > {
  $$CalendarsTableTableManager(_$AppDatabase db, $CalendarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> municipalityId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String?> putOutBy = const Value.absent(),
                Value<String> validFrom = const Value.absent(),
                Value<String?> validTo = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion(
                municipalityId: municipalityId,
                id: id,
                categories: categories,
                pattern: pattern,
                putOutBy: putOutBy,
                validFrom: validFrom,
                validTo: validTo,
                sourceUrl: sourceUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String municipalityId,
                required String id,
                required String categories,
                required String pattern,
                Value<String?> putOutBy = const Value.absent(),
                required String validFrom,
                Value<String?> validTo = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion.insert(
                municipalityId: municipalityId,
                id: id,
                categories: categories,
                pattern: pattern,
                putOutBy: putOutBy,
                validFrom: validFrom,
                validTo: validTo,
                sourceUrl: sourceUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarsTable, CollectionCalendar>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CalendarsTable,
                    CollectionCalendar
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarsTable,
      CollectionCalendar,
      $$CalendarsTableFilterComposer,
      $$CalendarsTableOrderingComposer,
      $$CalendarsTableAnnotationComposer,
      $$CalendarsTableCreateCompanionBuilder,
      $$CalendarsTableUpdateCompanionBuilder,
      (
        CollectionCalendar,
        BaseReferences<_$AppDatabase, $CalendarsTable, CollectionCalendar>,
      ),
      CollectionCalendar,
      PrefetchHooks Function()
    >;
typedef $$CalendarAreasTableCreateCompanionBuilder =
    CalendarAreasCompanion Function({
      required String municipalityId,
      required String calendarId,
      required String areaId,
      Value<int> rowid,
    });
typedef $$CalendarAreasTableUpdateCompanionBuilder =
    CalendarAreasCompanion Function({
      Value<String> municipalityId,
      Value<String> calendarId,
      Value<String> areaId,
      Value<int> rowid,
    });

class $$CalendarAreasTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarAreasTable> {
  $$CalendarAreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarAreasTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarAreasTable> {
  $$CalendarAreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarAreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarAreasTable> {
  $$CalendarAreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);
}

class $$CalendarAreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarAreasTable,
          CalendarArea,
          $$CalendarAreasTableFilterComposer,
          $$CalendarAreasTableOrderingComposer,
          $$CalendarAreasTableAnnotationComposer,
          $$CalendarAreasTableCreateCompanionBuilder,
          $$CalendarAreasTableUpdateCompanionBuilder,
          (
            CalendarArea,
            BaseReferences<_$AppDatabase, $CalendarAreasTable, CalendarArea>,
          ),
          CalendarArea,
          PrefetchHooks Function()
        > {
  $$CalendarAreasTableTableManager(_$AppDatabase db, $CalendarAreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> municipalityId = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<String> areaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarAreasCompanion(
                municipalityId: municipalityId,
                calendarId: calendarId,
                areaId: areaId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String municipalityId,
                required String calendarId,
                required String areaId,
                Value<int> rowid = const Value.absent(),
              }) => CalendarAreasCompanion.insert(
                municipalityId: municipalityId,
                calendarId: calendarId,
                areaId: areaId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarAreasTable, CalendarArea>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CalendarAreasTable,
                    CalendarArea
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarAreasTable,
      CalendarArea,
      $$CalendarAreasTableFilterComposer,
      $$CalendarAreasTableOrderingComposer,
      $$CalendarAreasTableAnnotationComposer,
      $$CalendarAreasTableCreateCompanionBuilder,
      $$CalendarAreasTableUpdateCompanionBuilder,
      (
        CalendarArea,
        BaseReferences<_$AppDatabase, $CalendarAreasTable, CalendarArea>,
      ),
      CalendarArea,
      PrefetchHooks Function()
    >;
typedef $$CollectionExceptionsTableCreateCompanionBuilder =
    CollectionExceptionsCompanion Function({
      Value<int> id,
      required String municipalityId,
      required String date,
      required String type,
      Value<String?> categories,
      Value<String?> areaIds,
      Value<String?> noteJa,
      Value<String?> noteEn,
      Value<String?> sourceUrl,
    });
typedef $$CollectionExceptionsTableUpdateCompanionBuilder =
    CollectionExceptionsCompanion Function({
      Value<int> id,
      Value<String> municipalityId,
      Value<String> date,
      Value<String> type,
      Value<String?> categories,
      Value<String?> areaIds,
      Value<String?> noteJa,
      Value<String?> noteEn,
      Value<String?> sourceUrl,
    });

class $$CollectionExceptionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionExceptionsTable> {
  $$CollectionExceptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaIds => $composableBuilder(
    column: $table.areaIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteJa => $composableBuilder(
    column: $table.noteJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteEn => $composableBuilder(
    column: $table.noteEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionExceptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionExceptionsTable> {
  $$CollectionExceptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaIds => $composableBuilder(
    column: $table.areaIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteJa => $composableBuilder(
    column: $table.noteJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteEn => $composableBuilder(
    column: $table.noteEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionExceptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionExceptionsTable> {
  $$CollectionExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipalityId => $composableBuilder(
    column: $table.municipalityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get areaIds =>
      $composableBuilder(column: $table.areaIds, builder: (column) => column);

  GeneratedColumn<String> get noteJa =>
      $composableBuilder(column: $table.noteJa, builder: (column) => column);

  GeneratedColumn<String> get noteEn =>
      $composableBuilder(column: $table.noteEn, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);
}

class $$CollectionExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionExceptionsTable,
          CollectionException,
          $$CollectionExceptionsTableFilterComposer,
          $$CollectionExceptionsTableOrderingComposer,
          $$CollectionExceptionsTableAnnotationComposer,
          $$CollectionExceptionsTableCreateCompanionBuilder,
          $$CollectionExceptionsTableUpdateCompanionBuilder,
          (
            CollectionException,
            BaseReferences<
              _$AppDatabase,
              $CollectionExceptionsTable,
              CollectionException
            >,
          ),
          CollectionException,
          PrefetchHooks Function()
        > {
  $$CollectionExceptionsTableTableManager(
    _$AppDatabase db,
    $CollectionExceptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionExceptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionExceptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectionExceptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> municipalityId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> categories = const Value.absent(),
                Value<String?> areaIds = const Value.absent(),
                Value<String?> noteJa = const Value.absent(),
                Value<String?> noteEn = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
              }) => CollectionExceptionsCompanion(
                id: id,
                municipalityId: municipalityId,
                date: date,
                type: type,
                categories: categories,
                areaIds: areaIds,
                noteJa: noteJa,
                noteEn: noteEn,
                sourceUrl: sourceUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String municipalityId,
                required String date,
                required String type,
                Value<String?> categories = const Value.absent(),
                Value<String?> areaIds = const Value.absent(),
                Value<String?> noteJa = const Value.absent(),
                Value<String?> noteEn = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
              }) => CollectionExceptionsCompanion.insert(
                id: id,
                municipalityId: municipalityId,
                date: date,
                type: type,
                categories: categories,
                areaIds: areaIds,
                noteJa: noteJa,
                noteEn: noteEn,
                sourceUrl: sourceUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionExceptionsTable, CollectionException>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CollectionExceptionsTable,
                    CollectionException
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionExceptionsTable,
      CollectionException,
      $$CollectionExceptionsTableFilterComposer,
      $$CollectionExceptionsTableOrderingComposer,
      $$CollectionExceptionsTableAnnotationComposer,
      $$CollectionExceptionsTableCreateCompanionBuilder,
      $$CollectionExceptionsTableUpdateCompanionBuilder,
      (
        CollectionException,
        BaseReferences<
          _$AppDatabase,
          $CollectionExceptionsTable,
          CollectionException
        >,
      ),
      CollectionException,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BundlesTableTableManager get bundles =>
      $$BundlesTableTableManager(_db, _db.bundles);
  $$WardsTableTableManager get wards =>
      $$WardsTableTableManager(_db, _db.wards);
  $$AreasTableTableManager get areas =>
      $$AreasTableTableManager(_db, _db.areas);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RulesTableTableManager get rules =>
      $$RulesTableTableManager(_db, _db.rules);
  $$AliasesTableTableManager get aliases =>
      $$AliasesTableTableManager(_db, _db.aliases);
  $$CalendarsTableTableManager get calendars =>
      $$CalendarsTableTableManager(_db, _db.calendars);
  $$CalendarAreasTableTableManager get calendarAreas =>
      $$CalendarAreasTableTableManager(_db, _db.calendarAreas);
  $$CollectionExceptionsTableTableManager get collectionExceptions =>
      $$CollectionExceptionsTableTableManager(_db, _db.collectionExceptions);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
