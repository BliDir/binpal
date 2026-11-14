// Every MVP screen in English and Japanese, with the full Yokohama bundle
// and the Kanagawa boundaries from the CDN, for reviewing both languages.
// Screenshots are saved to build/screenshots/:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screens_test.dart -d <device>

import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:binpal/app/services.dart';
import 'package:binpal/area/boundary_store.dart';
import 'package:binpal/area/location_source.dart';
import 'package:binpal/data/area_controller.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:binpal/data/language_controller.dart';
import 'package:binpal/data/sync_controller.dart';
import 'package:binpal/reminders/reminder_notifications.dart';
import 'package:binpal/reminders/reminder_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Refused at first, then at あざみ野二丁目, 48 m from あざみ野一丁目, so the
/// confirm screen shows a neighbour too. Never asks the real phone.
class _Location implements LocationSource {
  var result = const LocationResult.problem(LocationProblem.denied);

  @override
  Future<LocationResult> current() async => result;

  @override
  Future<void> openSettings(LocationProblem problem) async {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;
  setUp(() => surfaceConverted = false);

  for (final locale in const [Locale('en'), Locale('ja')]) {
    final code = locale.languageCode;
    final ja = code == 'ja';

    Future<void> screenshot(WidgetTester tester, String name) async {
      await tester.pumpAndSettle();
      if (!const bool.fromEnvironment('SCREENSHOTS', defaultValue: true)) {
        return;
      }
      if (Platform.isAndroid && !surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
        await tester.pumpAndSettle();
      }
      final platform = Platform.isIOS ? 'ios' : 'android';
      await binding.takeScreenshot('${platform}_${code}_$name');
    }

    Future<void> tap(WidgetTester tester, Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    /// A button with [text], so a title with the same words is not tapped.
    Finder button(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

    Future<void> back(WidgetTester tester) =>
        tap(tester, find.byType(BackButton));

    testWidgets('every screen ($code)', (tester) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final boundaryDir = await Directory.systemTemp.createTemp('binpal');
      addTearDown(() => boundaryDir.delete(recursive: true));
      final location = _Location();
      final language = LanguageController(db: db);
      final sync = SyncController(
        db: db,
        sync: BundleSync(db: db, client: http.Client()),
      );
      final services = AppServices(
        db: db,
        sync: sync,
        area: AreaController(db: db),
        language: language,
        reminders: ReminderService(
          db: db,
          notifications: LocalReminderNotifications(),
          locale: () => language.current,
        ),
        location: location,
        boundaries: BoundaryStore(
          client: http.Client(),
          directory: () async => boundaryDir,
        ),
        syncOnLaunch: false,
      );
      await sync.refresh(force: true);
      expect(sync.bundle, isNotNull);
      await services.area.load();

      await tester.pumpWidget(BinPalApp(services: services));
      await tester.pumpAndSettle();

      // Area setup, location refused.
      expect(find.text(ja ? '収集地域を設定' : 'Set your collection area'), findsOne);
      await screenshot(tester, 'setup');
      await tap(tester, button(ja ? '現在地を使う' : 'Use my location'));
      await screenshot(tester, 'setup_denied');

      // Confirm, near a boundary. The boundary download needs real time.
      location.result = const LocationResult.position(35.568253, 139.553345);
      await tester.tap(button(ja ? 'もう一度試す' : 'Try again'));
      final heading = find.text(ja ? 'この地域でよろしいですか？' : 'Is this your area?');
      for (var i = 0; i < 300 && heading.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.text(ja ? '近くの地域' : 'Also near you'), findsOne);
      await screenshot(tester, 'confirm');

      // The picker, then back to confirm and confirm.
      await tap(tester, button(ja ? '別の地域を選ぶ' : 'Choose another area'));
      await screenshot(tester, 'picker');
      await back(tester);
      await tap(tester, button(ja ? 'この地域にする' : 'Confirm area'));

      // Today and the calendar.
      expect(
        find.text(ja ? '青葉区あざみ野二丁目' : 'Azamino 2-chome, Aoba Ward'),
        findsWidgets,
      );
      await screenshot(tester, 'today');
      final viewCalendar = find.text(ja ? 'カレンダーを見る' : 'View calendar');
      await tester.scrollUntilVisible(viewCalendar, 200);
      await tap(tester, viewCalendar);
      await screenshot(tester, 'calendar');
      await back(tester);

      // Search, results and an item.
      await tap(tester, find.text(ja ? '検索' : 'Search').last);
      await screenshot(tester, 'search');
      await tester.enterText(find.byType(TextField), ja ? '傘' : 'umbrella');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await screenshot(tester, 'search_results');
      await tap(tester, find.byIcon(Icons.chevron_right).first);
      await screenshot(tester, 'item');
      await back(tester);

      // Settings and what opens from it.
      await tap(tester, find.byTooltip(ja ? '設定' : 'Settings').last);
      await screenshot(tester, 'settings');
      await tap(tester, find.text(ja ? 'お知らせ' : 'Reminders'));
      await screenshot(tester, 'reminders');
      await back(tester);
      await tap(tester, find.text(ja ? '言語 / Language' : 'Language'));
      await screenshot(tester, 'language');
      await back(tester);
      await tap(tester, find.text(ja ? 'BinPalについて' : 'About BinPal'));
      await screenshot(tester, 'about');
    });
  }
}
