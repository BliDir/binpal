import 'package:flutter/foundation.dart';

import 'database.dart';
import 'sync_controller.dart';

const areaSettingKey = 'area_id';

/// The user's collection area, as chosen in the area picker.
class AreaController extends ChangeNotifier {
  AreaController({required this.db});

  final AppDatabase db;

  Area? area;
  Ward? ward;

  /// Whether [load] has finished once, so a missing area means "not chosen"
  /// rather than "not read yet".
  bool loaded = false;

  /// Reads the chosen area from settings. The area can disappear from a new
  /// bundle; then [area] is null and the user is asked to choose again.
  Future<void> load() async {
    final id = await db.setting(areaSettingKey);
    final found = id == null
        ? null
        : await (db.select(
            db.areas,
          )..where((a) => a.id.equals(id))).getSingleOrNull();
    final foundWard = found?.wardId == null
        ? null
        : await (db.select(
            db.wards,
          )..where((w) => w.id.equals(found!.wardId!))).getSingleOrNull();
    if (found != area || foundWard != ward || !loaded) {
      area = found;
      ward = foundWard;
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> select(Area chosen) async {
    await db.setSetting(municipalitySettingKey, chosen.municipalityId);
    await db.setSetting(areaSettingKey, chosen.id);
    await load();
  }
}
