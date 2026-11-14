import 'dart:io';

import 'package:binpal/app/services.dart';
import 'package:binpal/area/boundary_package.dart';
import 'package:binpal/area/boundary_store.dart';
import 'package:binpal/area/location_source.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/language_controller.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_notifications.dart';

/// Services for widget tests: an in-memory database, a network that answers
/// 404, notifications that are only recorded, and no sync on launch.
AppServices testServices({
  AppDatabase? db,
  http.Client? client,
  FakeReminderNotifications? notifications,
  DateTime Function()? now,
  LocationSource? location,
  BoundaryStore? boundaries,
}) {
  // Each test makes its own in-memory database; they never share a file.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final database = db ?? AppDatabase(NativeDatabase.memory());
  final language = LanguageController(db: database);
  return AppServices(
    db: database,
    sync: SyncController(
      db: database,
      sync: BundleSync(
        db: database,
        client: client ?? MockClient((_) async => http.Response('', 404)),
      ),
    ),
    area: AreaController(db: database),
    language: language,
    reminders: ReminderService(
      db: database,
      notifications: notifications ?? FakeReminderNotifications(),
      now: now,
      locale: () => language.current,
    ),
    location: location ?? FakeLocationSource.denied(),
    boundaries:
        boundaries ??
        BoundaryStore(
          client: MockClient((_) async => http.Response('', 404)),
          directory: () async => Directory.systemTemp.createTemp('binpal'),
        ),
    syncOnLaunch: false,
    clock: now,
  );
}

/// A phone at a fixed place, or one where location access is refused.
class FakeLocationSource implements LocationSource {
  FakeLocationSource(this.result);
  FakeLocationSource.at(double lat, double lon)
    : result = LocationResult.position(lat, lon);
  FakeLocationSource.denied()
    : result = const LocationResult.problem(LocationProblem.denied);

  LocationResult result;
  int calls = 0;
  final openedSettings = <LocationProblem>[];

  @override
  Future<LocationResult> current() async {
    calls++;
    return result;
  }

  @override
  Future<void> openSettings(LocationProblem problem) async =>
      openedSettings.add(problem);
}

/// Boundaries that answer every lookup with fixed [areas], without a
/// download or a package.
class FakeBoundaryStore extends BoundaryStore {
  FakeBoundaryStore(this.areas, {Map<String, String>? municipalities})
    : municipalities = municipalities ?? {},
      super(
        client: MockClient((_) async => http.Response('', 404)),
        directory: () async => Directory.systemTemp,
      );

  List<AreaMatch>? areas;
  final Map<String, String> municipalities;
  final positions = <(double, double)>[];

  @override
  Future<BoundaryLookup?> lookup(
    double lat,
    double lon, {
    void Function()? onDownload,
  }) async {
    positions.add((lat, lon));
    final found = areas;
    return found == null
        ? null
        : BoundaryLookup(areas: found, municipalities: municipalities);
  }
}
