import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notesheet_tracker/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Counter decrements when "-" icon is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Increment first to avoid negative values if not allowed
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    // Tap the '-' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Counter does not go below zero', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Try to decrement at zero
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    // Counter should still be zero
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Multiple increments work correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }

    expect(find.text('5'), findsOneWidget);
  });
}
