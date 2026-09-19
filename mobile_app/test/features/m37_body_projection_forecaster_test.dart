import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_projection_forecaster.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';
import 'package:nutri_mobile_app/core/services/rule_based_body_projection_forecaster.dart';

MuscleWorkoutLog _thigh(int completed, int planned) => MuscleWorkoutLog(
      segment: BodySegment.rightThigh,
      periodLabel: 'This week',
      entries: [
        MuscleExerciseLog(
          name: 'Squat',
          plannedSets: planned,
          reps: 10,
          loadKg: 60,
          completedSets: completed,
        ),
      ],
    );

ProjectionForecastRequest _request({
  int month = 0,
  double shoulder = 0.5,
  double waist = 0.5,
  DailyFoodLog? foodLog,
  Map<BodySegment, MuscleWorkoutLog>? workouts,
}) {
  return ProjectionForecastRequest(
    month: month,
    shoulderFactor: shoulder,
    waistFactor: waist,
    foodLog: foodLog ?? const DailyFoodLog(),
    workouts: workouts ?? const {},
    calorieTarget: 2000,
    macroTargets: MacroTargets.daily,
  );
}

void main() {
  const forecaster = RuleBasedBodyProjectionForecaster();

  group('M37 rule-based body projection forecaster', () {
    test('baseline morph factors render the default build', () {
      final scales = RuleBasedBodyProjectionForecaster.scaleFactorsFor(
        shoulderFactor: 0.5,
        waistFactor: 0.5,
      );

      expect(scales[BodySegment.chest], closeTo(1.0, 0.0001));
      expect(scales[BodySegment.abdomen], closeTo(1.0, 0.0001));
      expect(scales[BodySegment.leftUpperArm], closeTo(1.0, 0.0001));
      expect(scales[BodySegment.leftThigh], closeTo(1.0, 0.0001));
    });

    test('muscle-gain 6 month morph factors widen chest and slim abdomen', () {
      final scales = RuleBasedBodyProjectionForecaster.scaleFactorsFor(
        shoulderFactor: 1.0,
        waistFactor: 0.4,
      );

      expect(scales[BodySegment.chest], closeTo(1.3, 0.0001));
      expect(scales[BodySegment.abdomen], closeTo(0.94, 0.0001));
      expect(scales[BodySegment.leftUpperArm], closeTo(1.2, 0.0001));
    });

    test('month 0 mirrors the current logged status', () async {
      final forecast = await forecaster.forecast(
        _request(
          month: 0,
          workouts: {BodySegment.rightThigh: _thigh(2, 12)},
        ),
      );

      expect(forecast.month, 0);
      expect(
        forecast.statusFor(BodySegment.rightThigh),
        SegmentStatus.critical,
      );
    });

    test('later months damp the imbalance toward balanced', () async {
      final now = await forecaster.forecast(
        _request(month: 0, workouts: {BodySegment.rightThigh: _thigh(2, 12)}),
      );
      final later = await forecaster.forecast(
        _request(month: 6, workouts: {BodySegment.rightThigh: _thigh(2, 12)}),
      );

      expect(now.statusFor(BodySegment.rightThigh), SegmentStatus.critical);
      expect(later.statusFor(BodySegment.rightThigh), SegmentStatus.warning);
      expect(
        later.statusFor(BodySegment.rightThigh),
        isNot(now.statusFor(BodySegment.rightThigh)),
      );
    });

    test('the abdomen reflects a projected caloric surplus', () async {
      final forecast = await forecaster.forecast(
        _request(
          month: 6,
          foodLog: const DailyFoodLog(
            entries: [
              LoggedFood(
                name: 'Feast',
                portion: '1 tray',
                calories: 4000,
                time: '12:00',
              ),
            ],
          ),
        ),
      );

      expect(forecast.statusFor(BodySegment.abdomen), SegmentStatus.critical);
      expect(forecast.scaleFor(BodySegment.abdomen), closeTo(1.0, 0.0001));
    });
  });

  group('M37 projection forecast value objects', () {
    test('forecast exposes defaults and value equality', () {
      const forecast = BodyProjectionForecast(
        month: 3,
        scaleFactors: {BodySegment.chest: 1.2},
        statuses: {BodySegment.chest: SegmentStatus.balanced},
      );
      const same = BodyProjectionForecast(
        month: 3,
        scaleFactors: {BodySegment.chest: 1.2},
        statuses: {BodySegment.chest: SegmentStatus.balanced},
      );

      expect(forecast, equals(same));
      expect(forecast.hashCode, equals(same.hashCode));
      expect(forecast.scaleFor(BodySegment.chest), 1.2);
      expect(forecast.scaleFor(BodySegment.head), 1.0);
      expect(forecast.statusFor(BodySegment.chest), SegmentStatus.balanced);
      expect(forecast.statusFor(BodySegment.head), SegmentStatus.noData);
      expect(forecast.toString(), contains('BodyProjectionForecast'));
      expect(
        forecast.copyWith(month: 6).month,
        6,
      );
      expect(
        forecast.copyWith(scaleFactors: const {BodySegment.abdomen: 0.8})
            .scaleFor(BodySegment.abdomen),
        0.8,
      );
      expect(
        forecast.copyWith(statuses: const {BodySegment.chest: SegmentStatus.critical})
            .statusFor(BodySegment.chest),
        SegmentStatus.critical,
      );
      expect(forecast, isNot(equals(forecast.copyWith(month: 6))));
    });

    test('request copies and compares', () {
      final request = _request(month: 1, shoulder: 0.6, waist: 0.45);
      expect(request, equals(request.copyWith()));
      expect(request.hashCode, equals(request.copyWith().hashCode));
      expect(request.copyWith(month: 6).month, 6);
      expect(request.copyWith(shoulderFactor: 0.9).shoulderFactor, 0.9);
      expect(request.copyWith(waistFactor: 0.1).waistFactor, 0.1);
      expect(request.copyWith(calorieTarget: 2500).calorieTarget, 2500);
      expect(
        request.copyWith(foodLog: const DailyFoodLog(date: 'x')).foodLog.date,
        'x',
      );
      expect(
        request.copyWith(
          macroTargets: const MacroTargets(protein: 1, carbs: 1, fat: 1),
        ).macroTargets.protein,
        1,
      );
      expect(request.copyWith(workouts: const {}).workouts, isEmpty);
      expect(request.toString(), contains('ProjectionForecastRequest'));
      expect(request, isNot(equals(request.copyWith(month: 6))));
    });
  });
}
