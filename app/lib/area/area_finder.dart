import 'package:drift/drift.dart' show OrderingTerm;

import '../app/services.dart';
import '../data/database.dart';
import 'boundary_store.dart';
import 'location_source.dart';

/// What "Use my location" found.
sealed class FindResult {
  const FindResult();
}

/// The areas the user may be in, containing area first, then those within
/// 50 m of the position. Only areas the downloaded bundle has.
class FoundAreas extends FindResult {
  const FoundAreas(this.areas, this.wards);

  final List<Area> areas;

  /// The wards of [areas], by id.
  final Map<String, Ward> wards;
}

class NoLocation extends FindResult {
  const NoLocation(this.problem);
  final LocationProblem problem;
}

/// The boundary package could not be downloaded or read.
class MapFailed extends FindResult {
  const MapFailed();
}

/// The area data (bundle) has not downloaded, so there is nothing to match.
class NoAreaData extends FindResult {
  const NoAreaData();
}

/// The position is outside every area BinPal has collection days for.
/// [place] is the municipality or ward there in Japanese, when the boundary
/// package knows it.
class NotCovered extends FindResult {
  const NotCovered(this.place);
  final String? place;
}

/// Finds the user's collection area from the phone's position.
///
/// The position lives only in this function's locals: it is matched against
/// boundaries on the device and then dropped. Only the area the user
/// confirms is saved, by the caller.
Future<FindResult> findArea(
  AppServices services, {
  void Function()? onDownload,
}) async {
  final location = await services.location.current();
  final lat = location.latitude, lon = location.longitude;
  if (lat == null || lon == null) return NoLocation(location.problem!);

  final BoundaryLookup? lookup;
  try {
    lookup = await services.boundaries.lookup(lat, lon, onDownload: onDownload);
  } on Exception {
    return const MapFailed();
  }
  if (lookup == null || lookup.areas.isEmpty) return const NotCovered(null);

  if (services.sync.bundle == null) await services.sync.refresh(force: true);
  if (services.sync.bundle == null) return const NoAreaData();

  final db = services.db;
  final ids = [for (final m in lookup.areas) m.id];
  final rows = await (db.select(db.areas)..where((a) => a.id.isIn(ids))).get();
  final byId = {for (final a in rows) a.id: a};
  final areas = [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
  if (areas.isEmpty) {
    final code = lookup.areas.first.municipalityCode;
    return NotCovered(lookup.municipalities[code]);
  }
  final wardIds = {for (final a in areas) ?a.wardId};
  final wards =
      await (db.select(db.wards)
            ..where((w) => w.id.isIn(wardIds))
            ..orderBy([(w) => OrderingTerm.asc(w.id)]))
          .get();
  return FoundAreas(areas, {for (final w in wards) w.id: w});
}
