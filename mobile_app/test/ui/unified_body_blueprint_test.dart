import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_view_model.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_body_view_model.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_geometry.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/unified_body_blueprint.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

void main() {
  group('M43 nutritionBodyViewModel', () {
    test('scales uniformly and gets wider with the morph factor', () {
      final thin = nutritionBodyViewModel(morph: 0.0, calorieRatio: 0.5);
      final wide = nutritionBodyViewModel(morph: 1.0, calorieRatio: 1.5);

      expect(thin.scaleFor(BodySegment.abdomen), lessThan(1.0));
      expect(wide.scaleFor(BodySegment.abdomen), greaterThan(1.0));
      expect(
        wide.scaleFor(BodySegment.chest),
        equals(wide.scaleFor(BodySegment.abdomen)),
      );
    });

    test('colours every segment by the calorie surplus', () {
      expect(
        nutritionBodyViewModel(morph: 0.5, calorieRatio: 1.0)
            .statusFor(BodySegment.chest),
        SegmentStatus.balanced,
      );
      expect(
        nutritionBodyViewModel(morph: 0.5, calorieRatio: 1.2)
            .statusFor(BodySegment.chest),
        SegmentStatus.warning,
      );
      expect(
        nutritionBodyViewModel(morph: 0.5, calorieRatio: 1.6)
            .statusFor(BodySegment.chest),
        SegmentStatus.critical,
      );
    });
  });

  group('M43 UnifiedBodyBlueprint widget', () {
    testWidgets('renders the shared canvas and reports selected segments', (
      tester,
    ) async {
      BodySegment? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: UnifiedBodyBlueprint(
                viewModel: const BodyDiagramViewModel(),
                showCallouts: false,
                onSegmentSelected: (segment) => selected = segment,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unified_body_blueprint')), findsOneWidget);
      expect(find.byKey(const Key('body_blueprint_paint')), findsOneWidget);
      expect(find.byKey(const Key('callout_abdomen')), findsNothing);

      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('body_blueprint_canvas')),
      );
      final local = BodySegmentGeometry.interiorPoint(
        BodySegment.abdomen,
        box.size,
      );
      await tester.tapAt(box.localToGlobal(local));
      await tester.pump();

      expect(selected, BodySegment.abdomen);
    });

    testWidgets('shows gutter callouts when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: UnifiedBodyBlueprint(
                viewModel: const BodyDiagramViewModel(),
                onSegmentSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('callout_abdomen')), findsOneWidget);
    });
  });

  group('M43 tabs share the unified blueprint', () {
    testWidgets('the Routines tab renders the unified blueprint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 3000);
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

      expect(find.byType(UnifiedBodyBlueprint), findsOneWidget);
    });

    testWidgets('the Nutrition tab renders the unified blueprint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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

      expect(find.byType(UnifiedBodyBlueprint), findsOneWidget);
    });
  });
}
