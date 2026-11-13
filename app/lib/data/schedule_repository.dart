import 'dart:convert';

import 'package:drift/drift.dart';

import '../calendar/collection_schedule.dart';
import 'database.dart';

/// Builds the [CollectionSchedule] of one area from the stored bundle.
class ScheduleRepository {
  ScheduleRepository(this.db);

  final AppDatabase db;

  Future<CollectionSchedule> forArea(
    String municipalityId,
    String areaId,
  ) async {
    final calendarIds = {
      for (final row
          in await (db.select(db.calendarAreas)..where(
                (c) =>
                    c.municipalityId.equals(municipalityId) &
                    c.areaId.equals(areaId),
              ))
              .get())
        row.calendarId,
    };
    // rowid is insertion order, which is the bundle's order.
    final calendars =
        await (db.select(db.calendars)
              ..where((c) => c.municipalityId.equals(municipalityId))
              ..orderBy([(_) => OrderingTerm.asc(_rowid)]))
            .get();
    final exceptions =
        await (db.select(db.collectionExceptions)
              ..where((e) => e.municipalityId.equals(municipalityId))
              ..orderBy([(e) => OrderingTerm.asc(e.id)]))
            .get();

    return CollectionSchedule(
      calendars: [
        // In bundle order, which is also the order categories are listed in.
        for (final c in calendars)
          if (calendarIds.contains(c.id))
            CalendarEntry(
              id: c.id,
              categories: (jsonDecode(c.categories) as List<dynamic>)
                  .cast<String>(),
              pattern: CollectionPattern.fromJson(
                jsonDecode(c.pattern) as Map<String, dynamic>,
              ),
              validFrom: JapanDate.parse(c.validFrom),
              validTo: c.validTo == null ? null : JapanDate.parse(c.validTo!),
              putOutBy: c.putOutBy,
            ),
      ],
      exceptions: [
        for (final e in exceptions)
          if (_appliesTo(e.areaIds, areaId))
            if (_type(e.type) case final type?)
              ExceptionEntry(
                date: JapanDate.parse(e.date),
                type: type,
                categories: e.categories == null
                    ? null
                    : (jsonDecode(e.categories!) as List<dynamic>)
                          .cast<String>()
                          .toSet(),
                noteJa: e.noteJa,
                noteEn: e.noteEn,
              ),
      ],
    );
  }
}

const _rowid = CustomExpression<int>('rowid');

bool _appliesTo(String? areaIds, String areaId) =>
    areaIds == null || (jsonDecode(areaIds) as List<dynamic>).contains(areaId);

/// Unknown exception types are skipped, as the schema asks.
ExceptionType? _type(String type) => switch (type) {
  'no_collection' => ExceptionType.noCollection,
  'extra_collection' => ExceptionType.extraCollection,
  _ => null,
};
