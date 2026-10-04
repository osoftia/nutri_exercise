import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_safety_verdict.dart';
import 'package:nutri_mobile_app/ui/molecules/clinical_food_safety_badge.dart';

void main() {
  testWidgets('warning verdict receives red outline and explanation', (
    tester,
  ) async {
    const verdict = ClinicalSafetyVerdict(
      level: ClinicalVerdictLevel.warning,
      findings: [
        ClinicalFinding(
          condition: ClinicalCondition.highCholesterol,
          level: ClinicalVerdictLevel.warning,
          reason: 'High saturated fat may work against cholesterol goals.',
        ),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClinicalFoodSafetyBadge(
            verdict: verdict,
            child: Text('Food'),
          ),
        ),
      ),
    );

    final decoration = tester
        .widget<Container>(
          find.byKey(const Key('clinical_food_safety_card')),
        )
        .decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect((decoration.border! as Border).top.color, Colors.redAccent);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.textContaining('saturated fat'), findsOneWidget);
  });

  testWidgets('beneficial verdict receives green support styling', (
    tester,
  ) async {
    const verdict = ClinicalSafetyVerdict(
      level: ClinicalVerdictLevel.beneficial,
      findings: [
        ClinicalFinding(
          condition: ClinicalCondition.highCholesterol,
          level: ClinicalVerdictLevel.beneficial,
          reason: 'Fiber-rich foods can support cholesterol goals.',
        ),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ClinicalFoodSafetyBadge(verdict: verdict)),
      ),
    );

    final decoration = tester
        .widget<Container>(
          find.byKey(const Key('clinical_food_safety_card')),
        )
        .decoration as BoxDecoration;
    expect((decoration.border! as Border).top.color, Colors.greenAccent);
    expect(find.text('Supportive'), findsOneWidget);
  });
}
