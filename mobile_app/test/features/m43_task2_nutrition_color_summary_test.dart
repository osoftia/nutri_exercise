import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_palette.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

BodyDetailController _controller() => BodyDetailController(
      repository: MockBodyDetailRepository(),
      advisor: const RuleBasedMuscleGapAdvisor(),
    );

void main() {
  group('M43 abdomen status semantics', () {
    test('adding food moves the abdomen out of noData and colours it', () async {
      final controller = _controller();
      expect(
        controller.buildViewModel().statusFor(BodySegment.abdomen),
        SegmentStatus.noData,
      );

      await controller.addFood(
        const LoggedFood(
          name: 'Oatmeal & Berries',
          portion: '200 g',
          calories: 840,
          proteinG: 20,
          carbsG: 120,
          fatG: 24,
          time: '08:10',
        ),
      );

      final status = controller.buildViewModel().statusFor(BodySegment.abdomen);
      expect(status, isNot(SegmentStatus.noData));
      expect(
        BodySegmentPalette.strokeFor(status),
        isNot(BodySegmentPalette.strokeFor(SegmentStatus.noData)),
      );
    });

    test('removing the added food returns the abdomen to noData', () async {
      final controller = _controller();
      await controller.addFood(
        const LoggedFood(
          name: 'Oatmeal & Berries',
          portion: '100 g',
          calories: 420,
          time: '08:10',
        ),
      );

      await controller.removeFood(0);

      expect(
        controller.buildViewModel().statusFor(BodySegment.abdomen),
        SegmentStatus.noData,
      );
    });
  });

  group('M43 nutrition summary aggregation', () {
    testWidgets('the summary aggregates items added on the Nutrition tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final detail = _controller();
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

      await tester.ensureVisible(
        find.byKey(const Key('quick_add_Oatmeal & Berries')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_Oatmeal & Berries')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('quick_add_grams_field')),
        '200',
      );
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('nutrition_action_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nutrition_action_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_food_sheet')), findsOneWidget);
      expect(find.text('2150 kcal'), findsOneWidget);
      expect(find.text('4 items'), findsOneWidget);
      expect(find.text('P 93g · C 253g · F 64g'), findsOneWidget);
    });
  });
}
