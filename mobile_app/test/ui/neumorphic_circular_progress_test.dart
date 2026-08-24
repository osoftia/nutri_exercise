import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_circular_progress.dart';

void main() {
  group('CircularProgressPainter', () {
    test('sweeps 2*pi*progress starting at the 12 position', () {
      final painter = CircularProgressPainter(progress: 0.25);
      expect(painter.sweepAngle, closeTo(math.pi / 2, 0.0001));
      expect(painter.startAngle, closeTo(-math.pi / 2, 0.0001));
    });

    test('sweeps zero for zero progress and a full circle for one', () {
      expect(
        CircularProgressPainter(progress: 0.0).sweepAngle,
        closeTo(0.0, 0.0001),
      );
      expect(
        CircularProgressPainter(progress: 1.0).sweepAngle,
        closeTo(2 * math.pi, 0.0001),
      );
    });
  });

  group('NeumorphicCircularProgress', () {
    testWidgets('renders the title and value label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicCircularProgress(
              title: 'Protein',
              progress: 0.2,
              valueLabel: '30 / 150g',
            ),
          ),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('30 / 150g'), findsOneWidget);
    });
  });
}
