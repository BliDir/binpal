import 'dart:convert';

import '../calendar/collection_schedule.dart';
import '../data/area_controller.dart';
import '../data/database.dart';
import 'boundary_store.dart';
import 'location_source.dart';

/// Days the phone was far from the saved area, and for which area.
const _farKey = 'move.far';

/// The last day the position was checked, `YYYY-MM-DD` in Japan.
const _lastCheckKey = 'move.last_check';

/// After "Not now", no question before this day.
const _snoozedUntilKey = 'move.snoozed_until';

/// Decides when to ask "Did you move?".
///
/// Only when location access is already granted (nothing ever asks for it
/// here), at most one position a day, matched on the device against the
/// saved area's boundary from the package already downloaded. The position
/// is dropped straight away: only dates are kept.
///
/// Travel and commuting shouldn't trigger it, so it asks only after the
/// phone was more than [farMetres] from the saved area on [daysToAsk]
/// different days within [windowDays], with no day near home in between.
/// "Not now" mutes it for [snoozeDays]. It never changes the area itself.
class MoveCheck {
  MoveCheck({
    required this.db,
    required this.location,
    required this.boundaries,
    required this.area,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final LocationSource location;
  final BoundaryStore boundaries;
  final AreaController area;
  final DateTime Function() _clock;

  static const farMetres = 3000.0;
  static const daysToAsk = 3;
  static const windowDays = 14;
  static const snoozeDays = 30;

  /// Looks once a day; true when it's time to ask.
  Future<bool> shouldAsk() async {
    final saved = area.area;
    if (saved == null) return false;
    final today = JapanDate.at(_clock());
    final snoozed = await db.setting(_snoozedUntilKey);
    if (snoozed != null && today.toString().compareTo(snoozed) < 0) {
      return false;
    }
    if (await db.setting(_lastCheckKey) == today.toString()) return false;
    if (!await location.permitted()) return false;

    final position = await location.current();
    final lat = position.latitude, lon = position.longitude;
    if (lat == null || lon == null) return false;
    await db.setSetting(_lastCheckKey, today.toString());
    final double? distance;
    try {
      distance = await boundaries.distanceToArea(saved.id, lat, lon);
    } on Exception {
      return false;
    }
    if (distance == null) return false;

    if (distance <= farMetres) {
      // Home again: whatever came before was a trip or the commute.
      await _clearFar();
      return false;
    }
    final since = today.addDays(-(windowDays - 1)).toString();
    final days = {
      ...(await _farDays(saved.id)).where((d) => d.compareTo(since) >= 0),
      today.toString(),
    }.toList()..sort();
    await _saveFar(saved.id, days);
    return days.length >= daysToAsk;
  }

  /// "Not now": no question for [snoozeDays], and the count starts again.
  Future<void> notNow() async {
    final until = JapanDate.at(_clock()).addDays(snoozeDays);
    await db.setSetting(_snoozedUntilKey, until.toString());
    await _clearFar();
  }

  /// The user chose an area: the count starts again for it.
  Future<void> updated() => _clearFar();

  Future<List<String>> _farDays(String areaId) async {
    final stored = await db.setting(_farKey);
    if (stored == null) return const [];
    final json = jsonDecode(stored) as Map<String, dynamic>;
    // Days far from a previous area don't count for this one.
    if (json['area'] != areaId) return const [];
    return (json['days'] as List<dynamic>).cast<String>();
  }

  Future<void> _saveFar(String areaId, List<String> days) =>
      db.setSetting(_farKey, jsonEncode({'area': areaId, 'days': days}));

  Future<void> _clearFar() =>
      (db.delete(db.settings)..where((s) => s.key.equals(_farKey))).go();
}
