// The photo check test set: how many photos the phone answers on its own,
// how many need AI, how accurate each path is, and AI response times.
//
// Photos go in one folder per expected Yokohama item id, for example
//   photos/yokohama-2832/bottle-1.jpg
//   photos/yokohama-1460/can-side.jpg
// and the run reads them from PHOTO_DIR. On the iOS Simulator that can be a
// folder on the Mac. On Android, run once with --no-uninstall, copy the
// folder into the app's files (adb push, then run-as … cp into app_flutter/),
// and run again with --no-uninstall and without PHOTO_DIR.
//
//   flutter test integration_test/photo_test_set_test.dart -d <device> \
//     --dart-define=PHOTO_DIR=/path/to/photos
//
// Add --dart-define=ASK_AI=false to measure the on-device path only. With AI,
// the photos the phone isn't sure of go to the live API (api.blidir.fun) and
// count against its daily limits; repeated runs hit its answer cache, so AI
// timings come from the first run. Run on mobile data for the ticket's
// p50/p95.
//
// The report is printed and written to PHOTO_DIR/report.md.

import 'dart:io';

import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/features/photo/identify_client.dart';
import 'package:binpal/features/photo/photo_analyzer.dart';
import 'package:binpal/features/photo/photo_image.dart';
import 'package:binpal/features/photo/photo_matcher.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _photoDir = String.fromEnvironment('PHOTO_DIR');
const _askAi = bool.fromEnvironment('ASK_AI', defaultValue: true);

/// Aoba-ku, the first ward covered.
const _areaId = '14117-001001';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photo check test set', (tester) async {
    final dir = Directory(
      _photoDir.isNotEmpty
          ? _photoDir
          : '${(await getApplicationDocumentsDirectory()).path}/photos',
    );
    if (!dir.existsSync()) {
      markTestSkipped('No photos in ${dir.path}; see the top of this file.');
      return;
    }

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final sync = await BundleSync(
      db: db,
      client: http.Client(),
    ).sync(launchMunicipalityId);
    expect(sync.outcome, SyncOutcome.updated);

    final analyzer = DevicePhotoAnalyzer();
    addTearDown(analyzer.close);
    final matcher = PhotoMatcher(db);
    final identify = IdentifyClient(db: db, client: http.Client());

    final rows = <_Row>[];
    // Skips hidden entries, such as the ._ files macOS adds to archives.
    bool visible(FileSystemEntity e) =>
        !e.uri.pathSegments.lastWhere((s) => s != '').startsWith('.');
    final folders =
        dir.listSync().whereType<Directory>().where(visible).toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final folder in folders) {
      final expectedId = folder.uri.pathSegments.lastWhere((s) => s != '');
      final expected = await matcher.itemHit(launchMunicipalityId, expectedId);
      if (expected == null) {
        fail('$expectedId is not an item in the current Yokohama bundle');
      }
      final photos = folder
          .listSync()
          .whereType<File>()
          .where(visible)
          .where(
            (f) => RegExp(
              r'\.(jpe?g|png|heic)$',
              caseSensitive: false,
            ).hasMatch(f.path),
          );
      for (final photo in photos) {
        final watch = Stopwatch()..start();
        final signals = await analyzer.analyze(photo.path);
        final match = await matcher.match(launchMunicipalityId, signals);
        final onDeviceMs = watch.elapsedMilliseconds;

        var answer = match.answer;
        int? aiMs;
        AiResult? ai;
        if (answer == null && _askAi && match.candidates.isNotEmpty) {
          final jpeg = await resizeForUpload(await photo.readAsBytes());
          ai = await identify.identify(
            areaId: _areaId,
            jpeg: jpeg,
            candidates: match.candidates,
            labels: signals.logLabels,
          );
          if (ai case AiAnswer(
            :final itemId,
            :final categoryId,
            :final elapsed,
          )) {
            aiMs = elapsed.inMilliseconds;
            final item = match.candidates
                .where((c) => c.rule.itemId == itemId)
                .firstOrNull;
            final category =
                item?.category ??
                await matcher.categoryById(launchMunicipalityId, categoryId);
            if (category != null) {
              answer = PhotoAnswer(
                category: category,
                item: item,
                source: PhotoAnswerSource.ai,
              );
            }
          }
        }

        rows.add(
          _Row(
            photo:
                '${folder.uri.pathSegments.lastWhere((s) => s != '')}/'
                '${photo.uri.pathSegments.last}',
            expected: expected.rule.itemId,
            expectedCategory: expected.category.id,
            source: answer?.source,
            item: answer?.item?.rule.itemId,
            category: answer?.category.id,
            inCandidates: match.candidates.any(
              (c) => c.rule.itemId == expected.rule.itemId,
            ),
            labels: signals.logLabels.take(5).join(', '),
            onDeviceMs: onDeviceMs,
            aiMs: aiMs,
            aiCached: ai is AiAnswer && ai.cached,
            aiProblem: ai is AiUnavailable ? ai.problem.name : null,
          ),
        );
      }
    }

    final report = _report(rows);
    // ignore: avoid_print
    print(report);
    File('${dir.path}/report.md').writeAsStringSync(report);
    expect(rows, isNotEmpty);
  });
}

class _Row {
  _Row({
    required this.photo,
    required this.expected,
    required this.expectedCategory,
    required this.source,
    required this.item,
    required this.category,
    required this.inCandidates,
    required this.labels,
    required this.onDeviceMs,
    required this.aiMs,
    required this.aiCached,
    required this.aiProblem,
  });

  final String photo;
  final String expected;
  final String expectedCategory;
  final PhotoAnswerSource? source;
  final String? item;
  final String? category;
  final bool inCandidates;
  final String labels;
  final int onDeviceMs;
  final int? aiMs;
  final bool aiCached;
  final String? aiProblem;

  bool get onDevice => source != null && source != PhotoAnswerSource.ai;
  bool get viaAi => source == PhotoAnswerSource.ai;
  bool get categoryRight => category == expectedCategory;
  bool get itemRight => item == expected;
}

String _report(List<_Row> rows) {
  String pct(int n, int of) =>
      of == 0 ? '–' : '$n / $of (${(100 * n / of).round()}%)';
  int ms(List<int> sorted, double q) =>
      sorted[((sorted.length - 1) * q).round()];

  final onDevice = rows.where((r) => r.onDevice).toList();
  final viaAi = rows.where((r) => r.viaAi).toList();
  final unanswered = rows.where((r) => r.source == null).toList();
  final aiTimes = [
    for (final r in viaAi)
      if (r.aiMs != null && !r.aiCached) r.aiMs!,
  ]..sort();
  final deviceTimes = [for (final r in rows) r.onDeviceMs]..sort();

  final b = StringBuffer()
    ..writeln('# Photo check test set')
    ..writeln()
    ..writeln('${rows.length} photos, ${DateTime.now().toIso8601String()}')
    ..writeln()
    ..writeln('| Path | Photos | Category right | Item right |')
    ..writeln('| -- | -- | -- | -- |')
    ..writeln(
      '| On the phone | ${pct(onDevice.length, rows.length)} | '
      '${pct(onDevice.where((r) => r.categoryRight).length, onDevice.length)} | '
      '${pct(onDevice.where((r) => r.itemRight).length, onDevice.where((r) => r.item != null).length)} |',
    )
    ..writeln(
      '| AI | ${pct(viaAi.length, rows.length)} | '
      '${pct(viaAi.where((r) => r.categoryRight).length, viaAi.length)} | '
      '${pct(viaAi.where((r) => r.itemRight).length, viaAi.where((r) => r.item != null).length)} |',
    )
    ..writeln('| No answer | ${pct(unanswered.length, rows.length)} | | |')
    ..writeln()
    ..writeln(
      'Expected item among the on-device candidates: '
      '${pct(rows.where((r) => r.inCandidates).length, rows.length)}',
    )
    ..writeln()
    ..writeln(
      'On-device time: p50 ${ms(deviceTimes, 0.5)} ms, '
      'p95 ${ms(deviceTimes, 0.95)} ms',
    );
  if (aiTimes.isNotEmpty) {
    b.writeln(
      'AI time (not cached): p50 ${ms(aiTimes, 0.5)} ms, '
      'p95 ${ms(aiTimes, 0.95)} ms, n = ${aiTimes.length}',
    );
  }
  b
    ..writeln()
    ..writeln(
      '| Photo | Path | Answer | Category | Labels | Device ms | AI ms |',
    )
    ..writeln('| -- | -- | -- | -- | -- | -- | -- |');
  for (final r in rows) {
    final mark = r.categoryRight ? (r.itemRight ? '✓' : '✓ cat') : '✗';
    b.writeln(
      '| ${r.photo} | ${r.source?.name ?? r.aiProblem ?? 'none'} | '
      '${r.source == null ? '' : mark} ${r.item ?? ''} | ${r.category ?? ''} | '
      '${r.labels} | ${r.onDeviceMs} | ${r.aiMs ?? ''}${r.aiCached ? ' (cached)' : ''} |',
    );
  }
  return b.toString();
}
