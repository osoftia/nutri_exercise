import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

void main() {
  testWidgets('tapping a muscle reports the muscle id and toggles off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 500,
              child: InteractiveBodyMap(
                onMuscleSelected: (id) => selected = id,
              ),
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(InteractiveBodyMap));
    final width = rect.width;
    final height = rect.height;
    final pad = width * 0.03;
    final side = math.min((width - pad * 3) / 2, height - pad * 2);
    final top = (height - side) / 2;
    final left = (width - side * 2 - pad) / 2;
    final tap = rect.topLeft + Offset(left + 0.425 * side, top + 0.27 * side);

    await tester.tapAt(tap);
    await tester.pump();
    expect(selected, 'chest');

    await tester.tapAt(tap);
    await tester.pump();
    expect(selected, isNull);
  });

  testWidgets('tapping empty space reports no muscle', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 500,
              child: InteractiveBodyMap(
                onMuscleSelected: (id) => selected = id,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(selected, isNull);
  });
}
