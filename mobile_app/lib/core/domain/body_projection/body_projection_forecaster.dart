import '../../models/food_entry.dart';
import 'body_segment.dart';
import 'muscle_workout_log.dart';
import 'nutrition_log.dart';
import 'segment_status.dart';

/// Immutable input for a [BodyProjectionForecaster].
class ProjectionForecastRequest {
  /// Creates a forecast request.
  const ProjectionForecastRequest({
    required this.month,
    required this.shoulderFactor,
    required this.waistFactor,
    required this.foodLog,
    required this.workouts,
    required this.calorieTarget,
    required this.macroTargets,
  });

  /// Months from now (`0`, `1`, `3` or `6`).
  final int month;

  /// Shoulder morph factor of the selected milestone (`0..1`, `0.5` baseline).
  final double shoulderFactor;

  /// Waist morph factor of the selected milestone (`0..1`, `0.5` baseline).
  final double waistFactor;

  /// Today's food log (drives the projected abdomen status).
  final DailyFoodLog foodLog;

  /// Today's per-segment workout logs.
  final Map<BodySegment, MuscleWorkoutLog> workouts;

  /// Daily calorie target.
  final int calorieTarget;

  /// Daily macro targets.
  final MacroTargets macroTargets;

  /// Returns a copy with the provided fields replaced.
  ProjectionForecastRequest copyWith({
    int? month,
    double? shoulderFactor,
    double? waistFactor,
    DailyFoodLog? foodLog,
    Map<BodySegment, MuscleWorkoutLog>? workouts,
    int? calorieTarget,
    MacroTargets? macroTargets,
  }) {
    return ProjectionForecastRequest(
      month: month ?? this.month,
      shoulderFactor: shoulderFactor ?? this.shoulderFactor,
      waistFactor: waistFactor ?? this.waistFactor,
      foodLog: foodLog ?? this.foodLog,
      workouts: workouts ?? this.workouts,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      macroTargets: macroTargets ?? this.macroTargets,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectionForecastRequest &&
      other.month == month &&
      other.shoulderFactor == shoulderFactor &&
      other.waistFactor == waistFactor &&
      other.foodLog == foodLog &&
      _mapEquals(other.workouts, workouts) &&
      other.calorieTarget == calorieTarget &&
      other.macroTargets == macroTargets;

  @override
  int get hashCode => Object.hash(
        month,
        shoulderFactor,
        waistFactor,
        foodLog,
        _mapHash(workouts),
        calorieTarget,
        macroTargets,
      );

  @override
  String toString() =>
      'ProjectionForecastRequest(month: $month, shoulder: $shoulderFactor, '
      'waist: $waistFactor)';
}

/// Structured projection returned by a [BodyProjectionForecaster].
///
/// Carries both the per-segment thickness multipliers (body composition) and
/// the estimated per-segment statuses, so the painter never has to know how a
/// projection is produced.
class BodyProjectionForecast {
  /// Creates a forecast for [month].
  const BodyProjectionForecast({
    required this.month,
    this.scaleFactors = const {},
    this.statuses = const {},
  });

  /// Months from now this forecast describes.
  final int month;

  /// Per-segment thickness multipliers; missing segments default to `1.0`.
  final Map<BodySegment, double> scaleFactors;

  /// Estimated per-segment statuses; missing segments default to `noData`.
  final Map<BodySegment, SegmentStatus> statuses;

  /// Thickness multiplier for [segment], defaulting to `1.0`.
  double scaleFor(BodySegment segment) => scaleFactors[segment] ?? 1.0;

  /// Estimated status for [segment], defaulting to [SegmentStatus.noData].
  SegmentStatus statusFor(BodySegment segment) =>
      statuses[segment] ?? SegmentStatus.noData;

  /// Returns a copy with the provided fields replaced.
  BodyProjectionForecast copyWith({
    int? month,
    Map<BodySegment, double>? scaleFactors,
    Map<BodySegment, SegmentStatus>? statuses,
  }) {
    return BodyProjectionForecast(
      month: month ?? this.month,
      scaleFactors: scaleFactors ?? this.scaleFactors,
      statuses: statuses ?? this.statuses,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BodyProjectionForecast &&
      other.month == month &&
      _mapEquals(other.scaleFactors, scaleFactors) &&
      _mapEquals(other.statuses, statuses);

  @override
  int get hashCode => Object.hash(month, _mapHash(scaleFactors), _mapHash(statuses));

  @override
  String toString() =>
      'BodyProjectionForecast(month: $month, '
      'scales: ${scaleFactors.length}, statuses: ${statuses.length})';
}

/// Abstract local-AI forecaster for a projection milestone.
///
/// Returning a structured value object keeps the UI decoupled from the model
/// and lets tests inject a fake without ever loading a model.
abstract interface class BodyProjectionForecaster {
  /// Returns the projected body for [request].
  Future<BodyProjectionForecast> forecast(ProjectionForecastRequest request);
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) =>
    Object.hashAllUnordered(map.entries.map((e) => Object.hash(e.key, e.value)));
