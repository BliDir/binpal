import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../data/bundle_sync.dart';
import '../data/database.dart';
import '../data/sync_controller.dart';

/// The app's long-lived objects: the local database and the bundle sync.
class AppServices {
  AppServices({required this.db, required this.sync, this.syncOnLaunch = true});

  /// The real database file and network client.
  factory AppServices.live() {
    final db = AppDatabase();
    return AppServices(
      db: db,
      sync: SyncController(
        db: db,
        sync: BundleSync(db: db, client: http.Client()),
      ),
    );
  }

  final AppDatabase db;
  final SyncController sync;

  /// Off in widget tests, which must not touch the database or the network.
  final bool syncOnLaunch;

  static AppServices of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'No AppServicesScope above this widget');
    return scope!.services;
  }
}

class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) =>
      services != oldWidget.services;
}
