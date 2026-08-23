import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/molecules/generated_routine_dialog.dart';

void main() {
  testWidgets('renders the generated routine text and closes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GeneratedRoutineDialog(text: 'Day 1 - Push')),
    );

    expect(find.text('Generated Routine'), findsOneWidget);
    expect(find.text('Day 1 - Push'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('showGeneratedRoutineDialog opens the dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

    showGeneratedRoutineDialog(tester.element(find.byType(SizedBox)), 'text');
    await tester.pumpAndSettle();

    expect(find.text('Generated Routine'), findsOneWidget);
    expect(find.text('text'), findsOneWidget);
  });
}
