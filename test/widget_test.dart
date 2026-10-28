// Smoke test for the indoor-positioning dashboard UI.
//
// Pumps the app, lets the mock telemetry service emit its first sample, and
// scrolls through the dashboard to check that every section renders.

import 'package:flutter/material.dart' as flutter;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Dashboard renders telemetry sections after first tick', (tester) async {
    await tester.pumpWidget(const IndoorTrackerApp());

    // First frame: telemetry hasn't arrived yet.
    expect(find.text('Indoor Tracker'), findsOneWidget);
    expect(find.byType(material_ui.CircularProgressIndicator), findsOneWidget);

    // Let the mock service's first periodic tick fire.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('SIMULATION'), findsOneWidget);
    expect(find.text('Floorplan position'), findsOneWidget);

    final scrollable = find.byType(flutter.Scrollable);
    final scrollableRect = tester.getRect(scrollable);

    Future<void> scrollUntilBuilt(Finder target) async {
      for (var attempt = 0; attempt < 10 && target.evaluate().isEmpty; attempt++) {
        // Start near the viewport's bottom so the drag begins outside the
        // map, whose own pan gesture otherwise consumes a centered drag.
        await tester.dragFrom(
          Offset(scrollableRect.center.dx, scrollableRect.bottom - 10),
          const Offset(0, -250),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(target, findsOneWidget);
    }

    await scrollUntilBuilt(find.text('Anchors'));

    await scrollUntilBuilt(find.text('IMU (MPU6050)'));

    await scrollUntilBuilt(find.text('Estimator'));
  });
}
