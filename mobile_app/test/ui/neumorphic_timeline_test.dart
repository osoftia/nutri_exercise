import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_timeline.dart';

void main() {
  group('NeumorphicTimeline', () {
    testWidgets('shows the Now, 1m, 3m and 6m milestones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicTimeline(selectedMonth: 0, onSelected: (_) {}),
          ),
        ),
      );

      expect(find.byKey(const Key('timeline_0')), findsOneWidget);
      expect(find.byKey(const Key('timeline_1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_3')), findsOneWidget);
      expect(find.byKey(const Key('timeline_6')), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('1m'), findsOneWidget);
      expect(find.text('3m'), findsOneWidget);
      expect(find.text('6m'), findsOneWidget);
    });

    testWidgets('tapping a milestone reports its month', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicTimeline(
              selectedMonth: 0,
              onSelected: (month) => selected = month,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('timeline_6')));
      expect(selected, 6);
    });
  });
}
