import '../domain/body_projection/muscle_gap_advisor.dart';

/// Deterministic, fully local [MuscleGapAdvisor].
///
/// It turns the measured volume gap into a short coaching sentence and never
/// touches the network, so it stays available offline and in tests.
class RuleBasedMuscleGapAdvisor implements MuscleGapAdvisor {
  /// Creates the (stateless) advisor.
  const RuleBasedMuscleGapAdvisor();

  @override
  Future<String> advise(MuscleGapContext context) async {
    final label = context.segment.name;
    if (context.workout.isEmpty) {
      return 'No $label work is planned yet — add one push and one pull '
          'movement to start tracking this muscle.';
    }
    if (context.completionRatio >= 1) {
      return 'On target for $label this ${context.workout.periodLabel
          .toLowerCase()} — keep the load and add a rep next time.';
    }
    final sets = context.remainingSets;
    return 'Finish $sets more ${sets == 1 ? 'set' : 'sets'} for $label to '
        'close the gap, and add 2.5 kg once you complete every set.';
  }
}
