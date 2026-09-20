import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_painter.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

BodyDetailController _detailWithHighProteinSurplus() => BodyDetailController(
      repository: MockBodyDetailRepository(
        foodLog: const DailyFoodLog(
          entries: [
            LoggedFood(
              name: 'Protein feast',
              portion: '1 plate',
              calories: 2600,
              proteinG: 210,
              carbsG: 260,
              fatG: 75,
              time: '12:00',
            ),
          ],
        ),
      ),
      advisor: const RuleBasedMuscleGapAdvisor(),
    );

void main() {
  testWidgets('M44 both tabs paint the blueprint grid', (tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RoutinesPage(
            controller: ProjectionController(
              repository: MockProjectionRepository(),
            ),
            detailController: BodyDetailController(
              repository: MockBodyDetailRepository(),
              advisor: const RuleBasedMuscleGapAdvisor(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body_blueprint_grid')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: NutritionPage(
          controller: NutritionController(
            repository: MockNutritionRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body_blueprint_grid')), findsOneWidget);
  });

  testWidgets('M44 the Nutrition blueprint paints a healthy green abdomen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final detail = _detailWithHighProteinSurplus();
    await detail.loadOverview();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: NutritionPage(
          controller: NutritionController(
            repository: MockNutritionRepository(),
          ),
          bodyDetailController: detail,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('body_blueprint_paint')),
    );
    final painter = paint.painter! as BodyBlueprintPainter;
    expect(
      painter.viewModel.statusFor(BodySegment.abdomen),
      SegmentStatus.healthy,
    );
    expect(detail.buildViewModel().statusFor(BodySegment.abdomen),
        SegmentStatus.healthy);
  });
}
