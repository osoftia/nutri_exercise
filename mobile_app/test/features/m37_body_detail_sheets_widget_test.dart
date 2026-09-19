import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/body_exercise_detail_sheet.dart';
import 'package:nutri_mobile_app/ui/molecules/body_food_detail_sheet.dart';

class _FakeAdvisor implements MuscleGapAdvisor {
  const _FakeAdvisor();

  @override
  Future<String> advise(MuscleGapContext context) async =>
      'Add one more set of squats to close the gap.';
}

class _PendingFoodRepository implements BodyDetailRepository {
  final Completer<DailyFoodLog> completer = Completer<DailyFoodLog>();

  @override
  Future<DailyFoodLog> loadTodayFoodLog() => completer.future;

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) async {}

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async =>
      MuscleWorkoutLog(segment: segment, periodLabel: 'This week');

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async => const [];

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {}
}

class _ThrowingFoodRepository implements BodyDetailRepository {
  @override
  Future<DailyFoodLog> loadTodayFoodLog() async => throw Exception('boom');

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) async {}

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async =>
      MuscleWorkoutLog(segment: segment, periodLabel: 'This week');

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async => const [];

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {}
}

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

const _thighWorkout = MuscleWorkoutLog(
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
    MuscleExerciseLog(
      name: 'Leg Press',
      plannedSets: 3,
      reps: 12,
      loadKg: 80,
      completedSets: 1,
    ),
  ],
);

BodyDetailController _controller({
  DailyFoodLog foodLog = _foods,
  Map<BodySegment, MuscleWorkoutLog> workouts = const {
    BodySegment.rightThigh: _thighWorkout,
  },
}) {
  return BodyDetailController(
    repository: MockBodyDetailRepository(foodLog: foodLog, workouts: workouts),
    advisor: const _FakeAdvisor(),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SizedBox(height: 700, child: child)),
    );

void main() {
  group('M37 food detail sheet', () {
    testWidgets('lists every food item and the summed total', (tester) async {
      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: _controller())));
      await tester.pumpAndSettle();

      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Yogurt'), findsOneWidget);
      expect(find.textContaining('1 bowl'), findsOneWidget);
      expect(find.text('1310 kcal'), findsOneWidget);
      expect(find.byKey(const Key('body_add_food')), findsOneWidget);
    });

    testWidgets('the Add food action appends an item and updates the total', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: controller)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('body_add_food')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('body_add_food')));
      await tester.pumpAndSettle();

      expect(controller.foodLog.entries, hasLength(4));
      expect(find.text('1460 kcal'), findsOneWidget);
      expect(find.text('1310 kcal'), findsNothing);
    });

    testWidgets('shows an empty state when nothing was logged', (tester) async {
      await tester.pumpWidget(
        _wrap(BodyFoodDetailSheet(controller: _controller(foodLog: const DailyFoodLog()))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('food_empty_state')), findsOneWidget);
      expect(find.byKey(const Key('body_add_food')), findsOneWidget);
    });

    testWidgets('shows a spinner while the log is loading', (tester) async {
      final repository = _PendingFoodRepository();
      final controller = BodyDetailController(
        repository: repository,
        advisor: const _FakeAdvisor(),
      );

      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: controller)));
      await tester.pump();

      expect(find.byKey(const Key('food_loading')), findsOneWidget);

      repository.completer.complete(const DailyFoodLog());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('food_empty_state')), findsOneWidget);
    });

    testWidgets('shows an error message when loading fails', (tester) async {
      final controller = BodyDetailController(
        repository: _ThrowingFoodRepository(),
        advisor: const _FakeAdvisor(),
      );

      await tester.pumpWidget(_wrap(BodyFoodDetailSheet(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load'), findsOneWidget);
    });
  });

  group('M37 exercise detail sheet', () {
    testWidgets('lists exercises, progress and the AI suggestion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BodyExerciseDetailSheet(
            controller: _controller(),
            segment: BodySegment.rightThigh,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Leg Press'), findsOneWidget);
      expect(find.text('3 / 4 sets'), findsOneWidget);
      expect(find.byKey(const Key('exercise_progress_row')), findsOneWidget);
      expect(find.byKey(const Key('body_ai_suggestion')), findsOneWidget);
      expect(
        find.text('Add one more set of squats to close the gap.'),
        findsOneWidget,
      );
    });

    testWidgets('shows an empty state when nothing is planned', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BodyExerciseDetailSheet(
            controller: _controller(workouts: const {}),
            segment: BodySegment.chest,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_empty_state')), findsOneWidget);
    });

    testWidgets('renders a completed exercise with a decimal load', (
      tester,
    ) async {
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(
          workouts: const {
            BodySegment.chest: MuscleWorkoutLog(
              segment: BodySegment.chest,
              periodLabel: 'This week',
              entries: [
                MuscleExerciseLog(
                  name: 'Incline Press',
                  plannedSets: 4,
                  reps: 8,
                  loadKg: 22.5,
                  completedSets: 4,
                ),
              ],
            ),
          },
        ),
        advisor: const _FakeAdvisor(),
      );

      await tester.pumpWidget(
        _wrap(
          BodyExerciseDetailSheet(
            controller: controller,
            segment: BodySegment.chest,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4×8 · 22.5kg'), findsOneWidget);
      expect(find.text('✓ 4/4 sets'), findsOneWidget);
    });
  });
}
