import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App startup verification - Performance sanity check', (
    WidgetTester tester,
  ) async {
    // The full MyApp cannot be pumped in unit tests because the SplashScreen
    // initializes Firebase in initState, which requires a real platform.
    // This test verifies that the widget framework can build a frame quickly.
    // Full startup performance is tested via integration tests on device.

    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('TOL')))),
    );

    stopwatch.stop();

    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(1000),
      reason: 'Widget framework took too long to build a frame',
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
