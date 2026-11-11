import 'package:binpal/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on Today and switches to Search', (tester) async {
    await tester.pumpWidget(const BinPalApp());
    await tester.pumpAndSettle();

    expect(find.text('No area yet'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('How do I sort this item?'), findsOneWidget);
  });

  testWidgets('opens settings from the gear', (tester) async {
    await tester.pumpWidget(const BinPalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();

    expect(find.text('Reminders'), findsOneWidget);
  });

  testWidgets('About shows the logo', (tester) async {
    await tester.pumpWidget(const BinPalApp());
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

    await tester.pumpWidget(const BinPalApp());
    await tester.pumpAndSettle();

    expect(find.text('今日'), findsWidgets);
    expect(find.text('検索'), findsOneWidget);
  });
}
