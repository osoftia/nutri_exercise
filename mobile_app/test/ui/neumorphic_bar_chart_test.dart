import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_bar_chart.dart';

void main() {
  group('NeumorphicBarChart', () {
    testWidgets('renders seven bars with normalized heights', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicBarChart(
              values: const [100, 50, 25, 0, 75, 200, 150],
              labels: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
            ),
          ),
        ),
      );

      for (var i = 0; i < 7; i++) {
        expect(find.byKey(Key('weekly_bar_$i')), findsOneWidget);
      }

      // Max value (200) renders full height, others are proportional.
      final maxHeight = tester.getSize(
        find.byKey(const Key('weekly_bar_5')),
      ).height;
      final halfHeight = tester.getSize(
        find.byKey(const Key('weekly_bar_0')),
      ).height;
      final zeroHeight = tester.getSize(
        find.byKey(const Key('weekly_bar_3')),
      ).height;

      expect(maxHeight, greaterThan(halfHeight));
      expect(halfHeight, closeTo(maxHeight / 2, 0.001));
      expect(zeroHeight, 0.0);
    });
  });
}
