import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/services/workout_summary_calculator.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/exercise_completion_sheet.dart';

ExerciseCompletionSummary _summary(List<CompletedExercise> exercises) =>
    const WorkoutSummaryCalculator()
        .summarize(date: '2026-09-18', exercises: exercises);

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SizedBox(height: 600, child: child)),
    );

void main() {
  group('M38 exercise completion sheet', () {
    testWidgets('lists exercises, burn and recovery statuses', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExerciseCompletionSheet(
            summary: _summary(const [
              CompletedExercise(
                name: 'Bench Press',
                plannedSets: 4,
                completedSets: 4,
                reps: 8,
                loadKg: 60,
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_completion_sheet')), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.byKey(const Key('burned_calories_row')), findsOneWidget);
      expect(find.text('250 kcal'), findsOneWidget);
      expect(find.textContaining('RECOVERED'), findsWidgets);
    });

    testWidgets('shows an empty state when nothing was completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ExerciseCompletionSheet(summary: _summary(const []))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_completion_empty')), findsOneWidget);
      expect(find.text('0 kcal'), findsOneWidget);
    });
  });
}
