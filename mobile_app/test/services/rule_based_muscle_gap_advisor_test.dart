import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';

MuscleGapContext _context({
  BodySegment segment = BodySegment.chest,
  List<MuscleExerciseLog> entries = const [],
}) {
  return MuscleGapContext(
    segment: segment,
    workout: MuscleWorkoutLog(
      segment: segment,
      periodLabel: 'This week',
      entries: entries,
    ),
  );
}

void main() {
  const advisor = RuleBasedMuscleGapAdvisor();

  group('M37 RuleBasedMuscleGapAdvisor', () {
    test('suggests a starting plan when nothing is planned', () async {
      final text = await advisor.advise(_context());
      expect(text, contains('No chest work'));
    });

    test('suggests progression when the plan is already met', () async {
      final text = await advisor.advise(
        _context(
          entries: const [
            MuscleExerciseLog(
              name: 'Bench Press',
              plannedSets: 4,
              reps: 8,
              loadKg: 60,
              completedSets: 4,
            ),
          ],
        ),
      );
      expect(text, contains('On target'));
    });

    test('names the remaining sets to close the gap', () async {
      final one = await advisor.advise(
        _context(
          entries: const [
            MuscleExerciseLog(
              name: 'Bench Press',
              plannedSets: 4,
              reps: 8,
              loadKg: 60,
              completedSets: 3,
            ),
          ],
        ),
      );
      expect(one, contains('1 more set'));

      final many = await advisor.advise(
        _context(
          entries: const [
            MuscleExerciseLog(
              name: 'Bench Press',
              plannedSets: 4,
              reps: 8,
              loadKg: 60,
              completedSets: 1,
            ),
          ],
        ),
      );
      expect(many, contains('3 more sets'));
    });
  });
}
