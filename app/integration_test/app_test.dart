// End-to-end flows on a simulator or device.
//
// Run with screenshots (saved to build/screenshots/):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart -d <device>
//
// Or without screenshots: flutter test integration_test -d <device>

import 'dart:io';

import 'package:binpal/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;
  // The binding switches the surface back after every test.
  setUp(() => surfaceConverted = false);

  Future<void> screenshot(WidgetTester tester, String name) async {
    // Screenshots only work under `flutter drive`; skip them under `flutter test`.
    if (!const bool.fromEnvironment('SCREENSHOTS', defaultValue: true)) return;
    // Android draws to a surface that can't be captured until it is switched
    // to an image once per test; that switch only completes after a new frame.
    if (Platform.isAndroid && !surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
      await tester.pumpAndSettle();
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    await binding.takeScreenshot('${platform}_$name');
  }

  Future<void> useLocale(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  group('navigation', () {
    for (final locale in const [Locale('en'), Locale('ja')]) {
      testWidgets('Today, Search and Settings (${locale.languageCode})', (
        tester,
      ) async {
        await useLocale(tester, locale);
        final ja = locale.languageCode == 'ja';

        await tester.pumpWidget(const BinPalApp());
        await tester.pumpAndSettle();
        expect(find.text(ja ? '地域が未設定です' : 'No area yet'), findsOneWidget);
        await screenshot(tester, '${locale.languageCode}_today');

        await tester.tap(find.text(ja ? '検索' : 'Search'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '傘');
        await tester.pumpAndSettle();
        expect(find.text('傘'), findsOneWidget);
        await screenshot(tester, '${locale.languageCode}_search');

        await tester.tap(find.byTooltip(ja ? '設定' : 'Settings').last);
        await tester.pumpAndSettle();
        expect(find.text(ja ? 'リマインダー' : 'Reminders'), findsOneWidget);
        await screenshot(tester, '${locale.languageCode}_settings');

        await tester.tap(find.text(ja ? 'BinPalについて' : 'About BinPal'));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(ja ? 'BinPalのロゴ' : 'BinPal logo'),
          findsOneWidget,
        );
        await screenshot(tester, '${locale.languageCode}_about');

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        // Back on Search, and the tab kept its text.
        expect(find.text('傘'), findsOneWidget);
      });
    }
  });
}
