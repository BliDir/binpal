import 'package:binpal/app/app.dart';
import 'package:binpal/data/bundle_sync.dart';
import 'package:binpal/data/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/services.dart';

void main() {
  testWidgets('starts on Today and switches to Search', (tester) async {
    await tester.pumpWidget(BinPalApp(services: testServices()));
    await tester.pumpAndSettle();

    expect(find.text('No area yet'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('How do I sort this item?'), findsOneWidget);
  });

  testWidgets('opens settings from the gear', (tester) async {
    await tester.pumpWidget(BinPalApp(services: testServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();

    expect(find.text('Reminders'), findsOneWidget);
  });

  testWidgets('About shows the logo', (tester) async {
    await tester.pumpWidget(BinPalApp(services: testServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('About BinPal'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('BinPal logo'), findsOneWidget);
    expect(find.text('Open-source licences'), findsOneWidget);
  });

  testWidgets('shows Japanese when the device is in Japanese', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(BinPalApp(services: testServices()));
    await tester.pumpAndSettle();

    expect(find.text('今日'), findsWidgets);
    expect(find.text('検索'), findsOneWidget);
  });

  testWidgets('settings shows which data is on the device', (tester) async {
    final services = testServices();
    await tester.pumpWidget(BinPalApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Not downloaded yet'), findsOneWidget);

    services.sync
      ..bundle = StoredBundle(
        municipalityId: '14100',
        bundleVersion: 3,
        sha256: 'x',
        generatedAt: '2026-11-12T10:00:00+09:00',
        nameJa: '横浜市',
        nameKana: 'よこはまし',
        nameEn: 'Yokohama City',
        attribution: '[]',
        importedAt: DateTime(2026, 11, 12),
      )
      ..notifyListeners();
    await tester.pump();
    expect(find.text('Yokohama City · version 3'), findsOneWidget);

    services.sync
      ..lastResult = const SyncResult(SyncOutcome.failed, error: 'offline')
      ..notifyListeners();
    await tester.pump();
    expect(find.textContaining("Couldn't check for updates"), findsOneWidget);
  });
}
