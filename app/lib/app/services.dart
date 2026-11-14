import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../area/boundary_store.dart';
import '../area/location_source.dart';

import '../data/area_controller.dart';
import '../data/bundle_sync.dart';
import '../data/database.dart';
import '../data/language_controller.dart';
import '../data/sync_controller.dart';
import '../reminders/reminder_notifications.dart';
import '../reminders/reminder_service.dart';

/// The app's long-lived objects: the local database, the bundle sync, the
/// chosen area and language, the reminders, and what finds the area from
/// the phone's location.
class AppServices {
  AppServices({
    required this.db,
    required this.sync,
    required this.area,
    required this.language,
    required this.reminders,
    LocationSource? location,
    BoundaryStore? boundaries,
    this.syncOnLaunch = true,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now,
       location = location ?? const GeolocatorLocationSource(),
       boundaries =
           boundaries ??
           BoundaryStore(
             client: http.Client(),
             directory: getApplicationSupportDirectory,
           ) {
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
    final language = LanguageController(db: db);
    return AppServices(
      db: db,
      sync: SyncController(
        db: db,
        sync: BundleSync(db: db, client: http.Client()),
      ),
      area: AreaController(db: db),
      language: language,
      reminders: ReminderService(
        db: db,
        notifications: LocalReminderNotifications(),
        locale: () => language.current,
      ),
    );
  }

  final AppDatabase db;
  final SyncController sync;
  final AreaController area;
  final LanguageController language;
  final ReminderService reminders;
  final LocationSource location;
  final BoundaryStore boundaries;

  /// Off in widget tests, which must not touch the database or the network.
  final bool syncOnLaunch;

  /// The current time. Tests set it to a fixed day.
  final DateTime Function() clock;

  /// Saves [chosen] as the user's area and moves reminders to its days. Only
  /// the area's id is stored, never where the phone was.
  Future<void> chooseArea(Area chosen) async {
    await area.select(chosen);
    await reminders.reschedule();
  }

  /// Shows the app in [chosen], or follows the phone when it is null, and
  /// rewrites the scheduled reminders in that language.
  Future<void> chooseLanguage(Locale? chosen) async {
    await language.choose(chosen);
    await reminders.reschedule();
  }

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
