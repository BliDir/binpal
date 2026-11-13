import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bundle_sync.dart';
import 'database.dart';

/// The only municipality with a published bundle. Used until area setup lets
/// the user choose; after that the chosen municipality is in settings.
const launchMunicipalityId = '14100';

const municipalitySettingKey = 'municipality_id';

/// Runs [BundleSync] in the background on launch and whenever the app comes
/// back to the foreground, and tells listeners what data is on the device.
///
/// Nothing here is awaited by the UI: the first screen is drawn from whatever
/// is already stored.
class SyncController extends ChangeNotifier with WidgetsBindingObserver {
  SyncController({required this.db, required this.sync});

  final AppDatabase db;
  final BundleSync sync;

  /// The bundle currently stored for the user's municipality, if any.
  StoredBundle? bundle;

  /// Result of the most recent check that actually ran.
  SyncResult? lastResult;
  bool syncing = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// Loads what is stored, then checks the CDN if a check is due (or [force]).
  Future<void> refresh({bool force = false}) async {
    if (syncing) return;
    syncing = true;
    try {
      final municipalityId =
          await db.setting(municipalitySettingKey) ?? launchMunicipalityId;
      bundle = await db.bundleFor(municipalityId);
      notifyListeners();

      final result = force
          ? await sync.sync(municipalityId)
          : await sync.syncIfDue(municipalityId);
      if (result != null) {
        lastResult = result;
        if (result.outcome == SyncOutcome.updated) {
          bundle = await db.bundleFor(municipalityId);
        }
      }
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
