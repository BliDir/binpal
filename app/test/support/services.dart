import 'package:binpal/app/services.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Services for widget tests: an in-memory database, a network that answers
/// 404, and no sync on launch.
AppServices testServices({AppDatabase? db, http.Client? client}) {
  // Each test makes its own in-memory database; they never share a file.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final database = db ?? AppDatabase(NativeDatabase.memory());
  return AppServices(
    db: database,
    sync: SyncController(
      db: database,
      sync: BundleSync(
        db: database,
        client: client ?? MockClient((_) async => http.Response('', 404)),
      ),
    ),
    syncOnLaunch: false,
  );
}
