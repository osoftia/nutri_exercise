import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_projection_forecaster.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';

class _FakeAdvisor implements MuscleGapAdvisor {
  _FakeAdvisor(this.text);

  final String text;
  MuscleGapContext? lastContext;

  @override
  Future<String> advise(MuscleGapContext context) async {
    lastContext = context;
    return text;
  }
}

class _ThrowingRepository implements BodyDetailRepository {
  @override
  Future<DailyFoodLog> loadTodayFoodLog() async => throw Exception('boom');

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) async {}

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async =>
      throw Exception('boom');

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async =>
      throw Exception('boom');

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {}
}

class _FakeForecaster implements BodyProjectionForecaster {
  const _FakeForecaster();

  @override
  Future<BodyProjectionForecast> forecast(
    ProjectionForecastRequest request,
  ) async {
    return BodyProjectionForecast(
      month: request.month,
      scaleFactors: {
        BodySegment.chest: request.month == 6 ? 2.0 : 1.0,
      },
      statuses: {
        BodySegment.chest: request.month == 6
            ? SegmentStatus.critical
            : SegmentStatus.balanced,
      },
    );
  }
}

class _ThrowingForecaster implements BodyProjectionForecaster {
  const _ThrowingForecaster();

  @override
  Future<BodyProjectionForecast> forecast(
    ProjectionForecastRequest request,
  ) async =>
      throw Exception('boom');
}

class _CountingForecaster implements BodyProjectionForecaster {
  int calls = 0;

  @override
  Future<BodyProjectionForecast> forecast(
    ProjectionForecastRequest request,
  ) async {
    calls++;
    return BodyProjectionForecast(
      month: request.month,
      scaleFactors: const {},
      statuses: const {},
    );
  }
}

DailyFoodLog _foodLog() => const DailyFoodLog(
      date: '2026-09-18',
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
      ],
    );

MuscleWorkoutLog _workout() => const MuscleWorkoutLog(
      segment: BodySegment.rightThigh,
      periodLabel: 'This week',
      entries: [
        MuscleExerciseLog(
          name: 'Squat',
          plannedSets: 4,
          reps: 10,
          loadKg: 60,
          completedSets: 3,
        ),
      ],
    );

BodyDetailController _controller({
  MuscleGapAdvisor? advisor,
  BodyProjectionForecaster? forecaster,
}) =>
    BodyDetailController(
      repository: MockBodyDetailRepository(
        foodLog: _foodLog(),
        workouts: {BodySegment.rightThigh: _workout()},
      ),
      advisor: advisor ?? _FakeAdvisor('Add one more set of squats.'),
      forecaster: forecaster,
    );

void main() {
  group('M37 BodyDetailController', () {
    test('loadFoodLog populates the log and notifies', () async {
      final controller = _controller();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.loadFoodLog();

      expect(controller.foodLog.entries, hasLength(2));
      expect(controller.foodLog.totalCalories, 1070);
      expect(controller.isLoadingFood, isFalse);
      expect(controller.foodError, isNull);
      expect(notifications, greaterThan(0));
    });

    test('addQuickFood appends an entry and raises the total', () async {
      final controller = _controller();
      await controller.loadFoodLog();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.addQuickFood();

      expect(controller.foodLog.entries, hasLength(3));
      expect(controller.foodLog.totalCalories, greaterThan(1070));
      expect(notifications, 1);
    });

    test('loadWorkout loads the log and the AI suggestion', () async {
      final advisor = _FakeAdvisor('Add one more set of squats.');
      final controller = _controller(advisor: advisor);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.loadWorkout(BodySegment.rightThigh);

      expect(controller.workoutLog, isNotNull);
      expect(controller.workoutLog!.completedSets, 3);
      expect(controller.workoutLog!.plannedSets, 4);
      expect(controller.suggestion, 'Add one more set of squats.');
      expect(controller.isLoadingWorkout, isFalse);
      expect(controller.isLoadingSuggestion, isFalse);
      expect(advisor.lastContext?.volumeGap, greaterThan(0));
      expect(notifications, greaterThan(0));
    });

    test('surfaces repository failures without throwing', () async {
      final controller = BodyDetailController(
        repository: _ThrowingRepository(),
        advisor: _FakeAdvisor('n/a'),
      );

      await controller.loadFoodLog();
      await controller.loadWorkout(BodySegment.chest);

      expect(controller.foodError, isNotNull);
      expect(controller.workoutError, isNotNull);
      expect(controller.foodLog.isEmpty, isTrue);
      expect(controller.workoutLog, isNull);
    });

    test('loadOverview loads food and every callout segment', () async {
      final controller = _controller();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.loadOverview();

      expect(controller.foodLog.entries, hasLength(2));
      expect(controller.workouts.keys, contains(BodySegment.rightThigh));
      expect(controller.isLoadingOverview, isFalse);
      expect(controller.overviewError, isNull);
      expect(notifications, greaterThan(0));
    });

    test('loadOverview surfaces failures', () async {
      final controller = BodyDetailController(
        repository: _ThrowingRepository(),
        advisor: _FakeAdvisor('n/a'),
      );

      await controller.loadOverview();

      expect(controller.overviewError, isNotNull);
      expect(controller.isLoadingOverview, isFalse);
    });

    test('setNutritionTargets updates the plan and notifies', () {
      final controller = _controller();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setNutritionTargets(
        calorieTarget: 2500,
        macroTargets: const MacroTargets(protein: 180, carbs: 300, fat: 80),
      );

      expect(controller.calorieTarget, 2500);
      expect(controller.macroTargets.protein, 180);
      expect(notifications, 1);

      controller.setNutritionTargets();
      expect(controller.calorieTarget, 2500);
    });

    test('buildViewModel reflects a caloric surplus as a critical abdomen',
        () async {
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(
          foodLog: const DailyFoodLog(
            entries: [
              LoggedFood(
                name: 'Big meal',
                portion: '1 tray',
                calories: 2900,
                time: '12:00',
              ),
            ],
          ),
          workouts: const {},
        ),
        advisor: _FakeAdvisor('n/a'),
      );
      await controller.loadOverview();

      final viewModel = controller.buildViewModel(
        selectedSegment: BodySegment.chest,
      );

      expect(viewModel.statusFor(BodySegment.abdomen), SegmentStatus.critical);
      expect(viewModel.selectedSegment, BodySegment.chest);
    });

    test('applyProjection updates the diagram scales and statuses', () async {
      final controller = _controller(forecaster: const _FakeForecaster());
      await controller.loadOverview();

      await controller.applyProjection(
        month: 6,
        shoulderFactor: 1.0,
        waistFactor: 0.4,
      );

      final viewModel = controller.buildViewModel();
      expect(viewModel.scaleFor(BodySegment.chest), 2.0);
      expect(viewModel.statusFor(BodySegment.chest), SegmentStatus.critical);
      expect(controller.forecast?.month, 6);
      expect(controller.forecastError, isNull);
      expect(controller.isLoadingForecast, isFalse);
    });

    test('applyProjection keeps the current body when the forecaster fails',
        () async {
      final controller = _controller(forecaster: const _ThrowingForecaster());
      await controller.loadOverview();

      await controller.applyProjection(
        month: 6,
        shoulderFactor: 1.0,
        waistFactor: 0.4,
      );

      expect(controller.forecastError, isNotNull);
      expect(controller.forecast, isNull);
      expect(controller.buildViewModel().scaleFor(BodySegment.chest), 1.0);
    });

    test('loadOverview re-runs an active projection', () async {
      final forecaster = _CountingForecaster();
      final controller = _controller(forecaster: forecaster);
      await controller.loadOverview();
      await controller.applyProjection(
        month: 1,
        shoulderFactor: 0.6,
        waistFactor: 0.5,
      );
      final before = forecaster.calls;

      await controller.loadOverview();

      expect(forecaster.calls, greaterThan(before));
    });

    test('addQuickFood cycles through the presets', () async {
      final controller = _controller();
      await controller.loadFoodLog();

      for (var i = 0; i < 4; i++) {
        controller.addQuickFood();
      }

      expect(controller.foodLog.entries, hasLength(6));
      expect(
        controller.foodLog.entries.last.name,
        BodyDetailController.quickFoods.first.name,
      );
    });
  });
}
