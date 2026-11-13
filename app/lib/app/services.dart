import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../data/area_controller.dart';
import '../data/bundle_sync.dart';
import '../data/database.dart';
import '../data/sync_controller.dart';
import '../reminders/reminder_notifications.dart';
import '../reminders/reminder_service.dart';

/// The app's long-lived objects: the local database, the bundle sync, the
/// chosen area and the reminders.
class AppServices {
  AppServices({
    required this.db,
    required this.sync,
    required this.area,
    required this.reminders,
    this.syncOnLaunch = true,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    // After every refresh (launch, foreground, bundle update): re-read the
    // area, which a new bundle can change, and top up reminders.
    sync.afterRefresh ??= () async {
      await area.load();
      await reminders.reschedule();
    };
  }

  /// The real database file, network client and notifications.
  factory AppServices.live() {
    final db = AppDatabase();
    return AppServices(
      db: db,
      sync: SyncController(
        db: db,
        sync: BundleSync(db: db, client: http.Client()),
      ),
      area: AreaController(db: db),
      reminders: ReminderService(
        db: db,
        notifications: LocalReminderNotifications(),
      ),
    );
  }

  final AppDatabase db;
  final SyncController sync;
  final AreaController area;
  final ReminderService reminders;

  /// Off in widget tests, which must not touch the database or the network.
  final bool syncOnLaunch;

  /// The current time. Tests set it to a fixed day.
  final DateTime Function() clock;

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
