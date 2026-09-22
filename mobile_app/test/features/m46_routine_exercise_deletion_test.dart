import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/routine_summary_sheet.dart';

const _benchPress = CompletedExercise(
  name: 'Bench Press',
  plannedSets: 4,
  completedSets: 4,
  reps: 8,
  loadKg: 60,
);

const _squat = CompletedExercise(
  name: 'Squat',
  plannedSets: 4,
  completedSets: 4,
  reps: 10,
  loadKg: 70,
);

void main() {
  group('M46 individual exercise deletion (controller)', () {
    test('removes one completion and re-syncs the calendar entry', () async {
      final repo = MockBodyDetailRepository();
      final entries = MockDailyEntryRepository();
      final controller = WorkoutCompletionController(
        repository: repo,
        dailyEntries: entries,
      );

      await controller.confirm(const [_benchPress, _squat]);
      final removed = await controller.removeExercise('Bench Press');

      expect(removed, isTrue);
      expect(
        (await repo.loadCompletedExercises()).map((e) => e.name),
        ['Squat'],
      );

      final today = DailyEntry.dateKey(DateTime.now());
      final entry = await entries.getByDate(today);
      expect(entry!.exercises, ['Squat']);
      expect(entry.burned, 250);
    });

    test('is a no-op for an unknown exercise', () async {
      final controller = WorkoutCompletionController(
        repository: MockBodyDetailRepository(),
      );
      await controller.confirm(const [_benchPress]);

      expect(await controller.removeExercise('Nope'), isFalse);
      expect(controller.isConfirmed, isTrue);
    });
  });

  group('M46 individual exercise deletion (routine summary widget)', () {
    testWidgets('each exercise exposes a delete control that removes it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = MockBodyDetailRepository();
      final detail = BodyDetailController(
        repository: repo,
        advisor: const RuleBasedMuscleGapAdvisor(),
      );
      final completion = WorkoutCompletionController(repository: repo);

      await detail.loadOverview();
      await completion.confirm(detail.plannedExercises());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RoutineSummarySheet(
              controller: detail,
              completion: completion,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteButton = find.byKey(
        const Key('routine_delete_Bench Press'),
      );
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(
        (await repo.loadCompletedExercises()).map((e) => e.name),
        isNot(contains('Bench Press')),
      );
    });
  });
}
