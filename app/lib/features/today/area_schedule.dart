import '../../calendar/collection_schedule.dart';
import '../../data/database.dart';
import '../../data/schedule_repository.dart';

/// Everything the Today and calendar screens show for one area, read from
/// the local database only.
class AreaSchedule {
  const AreaSchedule({
    required this.area,
    required this.ward,
    required this.schedule,
    required this.categories,
  });

  final Area area;
  final Ward? ward;
  final CollectionSchedule schedule;

  /// The municipality's categories by id.
  final Map<String, WasteCategory> categories;

  static Future<AreaSchedule> load(
    AppDatabase db,
    Area area,
    Ward? ward,
  ) async {
    final schedule = await ScheduleRepository(db)
        .forArea(area.municipalityId, area.id);
    final categories = {
      for (final c in await (db.select(
        db.categories,
      )..where((c) => c.municipalityId.equals(area.municipalityId))).get())
        c.id: c,
    };
    return AreaSchedule(
      area: area,
      ward: ward,
      schedule: schedule,
      categories: categories,
    );
  }

  /// The official page for the area's collection days, if the bundle has one.
  String? get sourceUrl => schedule.calendars
      .map((c) => c.sourceUrl)
      .whereType<String>()
      .firstOrNull;

  /// [day]'s collections whose category the bundle defines, in order.
  List<(Collection, WasteCategory)> collectionsOn(CollectionDay day) => [
    for (final c in day.collections)
      if (categories[c.category] case final category?) (c, category),
  ];
}
