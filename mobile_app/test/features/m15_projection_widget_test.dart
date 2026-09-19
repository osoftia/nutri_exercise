import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_diagram.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

void main() {
  Future<ProjectionController> pumpRoutines(
    WidgetTester tester, {
    FitnessGoal goal = FitnessGoal.muscleGain,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ProjectionController(
      repository: MockProjectionRepository(goal: goal),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RoutinesPage(
            controller: controller,
            detailController: BodyDetailController(
              repository: MockBodyDetailRepository(),
              advisor: const RuleBasedMuscleGapAdvisor(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  BodyBlueprintDiagram diagram(WidgetTester tester) =>
      tester.widget<BodyBlueprintDiagram>(find.byType(BodyBlueprintDiagram));

  group('Body projection (Routines tab)', () {
    testWidgets('shows the timeline with four milestones', (tester) async {
      await pumpRoutines(tester);

      expect(find.byKey(const Key('timeline_0')), findsOneWidget);
      expect(find.byKey(const Key('timeline_1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_3')), findsOneWidget);
      expect(find.byKey(const Key('timeline_6')), findsOneWidget);
    });

    testWidgets('baseline renders the neutral body build', (tester) async {
      await pumpRoutines(tester);

      expect(diagram(tester).viewModel.scaleFor(BodySegment.chest), 1.0);
      expect(diagram(tester).viewModel.scaleFor(BodySegment.abdomen), 1.0);
    });

    testWidgets('selecting 1m updates the summary and morphs the diagram', (
      tester,
    ) async {
      await pumpRoutines(tester);

      await tester.tap(find.byKey(const Key('timeline_1')));
      await tester.pumpAndSettle();

      expect(find.text('71.5 kg · Foundation'), findsOneWidget);
      expect(
        diagram(tester).viewModel.scaleFor(BodySegment.chest),
        greaterThan(1.0),
      );
    });

    testWidgets('selecting 6m shows the broadest shoulders for muscle gain', (
      tester,
    ) async {
      await pumpRoutines(tester);

      await tester.tap(find.byKey(const Key('timeline_6')));
      await tester.pumpAndSettle();

      expect(
        diagram(tester).viewModel.scaleFor(BodySegment.chest),
        closeTo(1.3, 0.0001),
      );
      expect(
        diagram(tester).viewModel.scaleFor(BodySegment.abdomen),
        lessThan(1.0),
      );
      expect(find.text('76.0 kg · Peak Build'), findsOneWidget);
    });

    testWidgets('fat loss plan slims the abdomen the most at 6m', (tester) async {
      await pumpRoutines(tester, goal: FitnessGoal.fatLoss);

      await tester.tap(find.byKey(const Key('timeline_6')));
      await tester.pumpAndSettle();

      expect(
        diagram(tester).viewModel.scaleFor(BodySegment.abdomen),
        closeTo(0.85, 0.0001),
      );
      expect(
        diagram(tester).viewModel.scaleFor(BodySegment.abdomen),
        lessThan(1.0),
      );
    });
  });
}
