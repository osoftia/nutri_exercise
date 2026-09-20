import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_builder.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/macro_balance.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_balance_calculator.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_balance_input.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_palette.dart';

const _calculator = SegmentBalanceCalculator();

SegmentBalanceInput _abdomen({
  double calorieBalance = 600,
  double protein = 60,
  double carbs = 10,
  double fat = 5,
}) =>
    SegmentBalanceInput(
      segment: BodySegment.abdomen,
      calorieBalance: calorieBalance,
      macroBalance: MacroBalance(
        proteinDeltaG: protein,
        carbsDeltaG: carbs,
        fatDeltaG: fat,
      ),
    );

void main() {
  group('M44 green stomach palette', () {
    test('maps the healthy status to #10B981', () {
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.healthy),
        const Color(0xFF10B981),
      );
      expect(
        BodySegmentPalette.fillFor(SegmentStatus.healthy),
        const Color(0xFF10B981).withValues(alpha: 0.18),
      );
    });

    test('keeps the pre-existing status colours', () {
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.balanced),
        const Color(0xFF3B82F6),
      );
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.warning),
        const Color(0xFFF59E0B),
      );
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.critical),
        const Color(0xFFEF4444),
      );
    });
  });

  group('M44 healthy protein surplus semantics', () {
    test('a protein-led surplus is healthy', () {
      final result = _calculator.compute(_abdomen());
      expect(result.status, SegmentStatus.healthy);
      expect(_calculator.isHealthySurplus(_abdomen(), result.imbalanceScore), isTrue);
    });

    test('a carb/fat-led surplus stays an imbalance', () {
      final result = _calculator.compute(
        _abdomen(protein: -10, carbs: 70, fat: 20),
      );
      expect(result.status, isNot(SegmentStatus.healthy));
    });

    test('a protein surplus in a deficit is not a healthy surplus', () {
      final result = _calculator.compute(
        _abdomen(calorieBalance: -400, protein: 80, carbs: 10, fat: 10),
      );
      expect(result.status, isNot(SegmentStatus.healthy));
    });

    test('a small protein surplus within the balanced band is not healthy', () {
      final result = _calculator.compute(
        _abdomen(calorieBalance: 40, protein: 20, carbs: 5, fat: 5),
      );
      expect(result.status, isNot(SegmentStatus.healthy));
    });

    test('protein dominance never turns a trained muscle green', () {
      final result = _calculator.compute(
        const SegmentBalanceInput(
          segment: BodySegment.chest,
          trainedVolume: 10,
          targetVolume: 5,
          macroBalance: MacroBalance(proteinDeltaG: 60),
        ),
      );
      expect(result.status, isNot(SegmentStatus.healthy));
    });
  });

  group('M44 diagram builder green abdomen', () {
    test('a high-protein surplus day paints the abdomen healthy', () {
      const builder = BodyDiagramBuilder();
      final viewModel = builder.build(
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
        workouts: const {},
        calorieTarget: 2000,
        macroTargets: const MacroTargets(protein: 150, carbs: 250, fat: 70),
      );

      final status = viewModel.statusFor(BodySegment.abdomen);
      expect(status, SegmentStatus.healthy);
      expect(
        BodySegmentPalette.strokeFor(status),
        const Color(0xFF10B981),
      );
    });

    test('a carb-led surplus day does not paint the abdomen green', () {
      const builder = BodyDiagramBuilder();
      final viewModel = builder.build(
        foodLog: const DailyFoodLog(
          entries: [
            LoggedFood(
              name: 'Carb feast',
              portion: '1 plate',
              calories: 2600,
              proteinG: 140,
              carbsG: 320,
              fatG: 90,
              time: '12:00',
            ),
          ],
        ),
        workouts: const {},
        calorieTarget: 2000,
        macroTargets: const MacroTargets(protein: 150, carbs: 250, fat: 70),
      );

      expect(
        viewModel.statusFor(BodySegment.abdomen),
        isNot(SegmentStatus.healthy),
      );
    });
  });
}
