import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_projection_forecaster.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_diagram.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_geometry.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

class _FakeAdvisor implements MuscleGapAdvisor {
  const _FakeAdvisor();

  @override
  Future<String> advise(MuscleGapContext context) async =>
      'Add one more set of squats to close the gap.';
}

class _ProjectionForecaster implements BodyProjectionForecaster {
  const _ProjectionForecaster();

  @override
  Future<BodyProjectionForecast> forecast(
    ProjectionForecastRequest request,
  ) async {
    final scale = switch (request.month) {
      6 => 2.0,
      1 => 1.2,
      _ => 1.0,
    };
    return BodyProjectionForecast(
      month: request.month,
      scaleFactors: {BodySegment.chest: scale},
      statuses: {
        BodySegment.chest: request.month == 6
            ? SegmentStatus.critical
            : SegmentStatus.balanced,
      },
    );
  }
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

const _chestWorkout = MuscleWorkoutLog(
  segment: BodySegment.chest,
  periodLabel: 'This week',
  entries: [
    MuscleExerciseLog(
      name: 'Bench Press',
      plannedSets: 4,
      reps: 8,
      loadKg: 60,
      completedSets: 2,
    ),
  ],
);

BodyDetailController _detailController({
  BodyProjectionForecaster? forecaster,
}) =>
    BodyDetailController(
      repository: MockBodyDetailRepository(
        foodLog: _foods,
        workouts: const {BodySegment.chest: _chestWorkout},
      ),
      advisor: const _FakeAdvisor(),
      forecaster: forecaster,
    );

Future<void> _pumpRoutines(
  WidgetTester tester,
  BodyDetailController detailController,
) async {
  tester.view.physicalSize = const Size(1000, 2400);
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
          detailController: detailController,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('M37 body diagram wiring on the Routines tab', () {
    testWidgets('mounts the blueprint diagram', (tester) async {
      await _pumpRoutines(tester, _detailController());

      expect(find.byType(BodyBlueprintDiagram), findsOneWidget);
      expect(find.byKey(const Key('callout_abdomen')), findsOneWidget);
      expect(find.byKey(const Key('callout_chest')), findsOneWidget);
    });

    testWidgets('tapping the stomach callout opens the food sheet', (
      tester,
    ) async {
      await _pumpRoutines(tester, _detailController());

      await tester.tap(find.byKey(const Key('callout_abdomen')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_food_sheet')), findsOneWidget);
      expect(find.text('Oatmeal'), findsOneWidget);
    });

    testWidgets('tapping the chest callout opens the exercise sheet', (
      tester,
    ) async {
      await _pumpRoutines(tester, _detailController());

      await tester.tap(find.byKey(const Key('callout_chest')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_exercise_sheet')), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('tapping the abdomen segment opens the food sheet', (
      tester,
    ) async {
      await _pumpRoutines(tester, _detailController());

      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('body_blueprint_canvas')),
      );
      final local =
          BodySegmentGeometry.interiorPoint(BodySegment.abdomen, box.size);
      await tester.tapAt(box.localToGlobal(local));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_food_sheet')), findsOneWidget);
    });

    testWidgets('selecting the 6m chip applies the projected forecast', (
      tester,
    ) async {
      await _pumpRoutines(
        tester,
        _detailController(forecaster: const _ProjectionForecaster()),
      );

      await tester.tap(find.byKey(const Key('timeline_6')));
      await tester.pumpAndSettle();

      final viewModel = tester
          .widget<BodyBlueprintDiagram>(find.byType(BodyBlueprintDiagram))
          .viewModel;
      expect(viewModel.scaleFor(BodySegment.chest), 2.0);
      expect(viewModel.statusFor(BodySegment.chest), SegmentStatus.critical);
    });

    testWidgets('selecting the 1m chip applies its projected forecast', (
      tester,
    ) async {
      await _pumpRoutines(
        tester,
        _detailController(forecaster: const _ProjectionForecaster()),
      );

      await tester.tap(find.byKey(const Key('timeline_1')));
      await tester.pumpAndSettle();

      final viewModel = tester
          .widget<BodyBlueprintDiagram>(find.byType(BodyBlueprintDiagram))
          .viewModel;
      expect(viewModel.scaleFor(BodySegment.chest), 1.2);
      expect(viewModel.statusFor(BodySegment.chest), SegmentStatus.balanced);
    });
  });
}
