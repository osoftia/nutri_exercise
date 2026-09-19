import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/body_food_detail_sheet.dart';

const _foods = DailyFoodLog(
  entries: [
    LoggedFood(
      name: 'Oatmeal',
      portion: '1 bowl',
      calories: 420,
      proteinG: 12,
      carbsG: 60,
      fatG: 12,
      time: '08:10',
    ),
    LoggedFood(
      name: 'Chicken',
      portion: '200 g',
      calories: 650,
      proteinG: 45,
      carbsG: 55,
      fatG: 18,
      time: '13:20',
    ),
    LoggedFood(
      name: 'Yogurt',
      portion: '150 g',
      calories: 240,
      proteinG: 18,
      carbsG: 18,
      fatG: 10,
      time: '17:00',
    ),
  ],
);

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SizedBox(height: 700, child: child)),
    );

void main() {
  group('M38 nutrition consumption list', () {
    testWidgets('shows a sticky total row and inline delete controls', (
      tester,
    ) async {
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(foodLog: _foods),
        advisor: const RuleBasedMuscleGapAdvisor(),
      );

      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nutrition_total_row')), findsOneWidget);
      expect(find.text('1310 kcal'), findsOneWidget);
      expect(find.byKey(const Key('food_delete_0')), findsOneWidget);
      expect(find.byKey(const Key('food_delete_1')), findsOneWidget);
    });

    testWidgets('removing a food updates the total and the avatar', (
      tester,
    ) async {
      final tamagotchi = MuscleTamagotchiState()..applyNutrition(1000);
      final fullnessBefore = tamagotchi.coreFullness;
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(foodLog: _foods),
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );

      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: controller)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('food_delete_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('food_delete_1')));
      await tester.pumpAndSettle();

      expect(controller.foodLog.entries, hasLength(2));
      expect(find.text('660 kcal'), findsOneWidget);
      expect(tamagotchi.coreFullness, lessThan(fullnessBefore));
    });

    testWidgets('restricts the sheet to deletion only (no add action)', (
      tester,
    ) async {
      final tamagotchi = MuscleTamagotchiState();
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(foodLog: _foods),
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );

      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_add_food')), findsNothing);
      expect(find.byKey(const Key('food_delete_0')), findsOneWidget);
      expect(controller.foodLog.entries, hasLength(3));
    });
  });
}
