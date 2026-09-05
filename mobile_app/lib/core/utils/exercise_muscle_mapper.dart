import 'package:flutter/material.dart';

/// Maps common exercise names to per-region activation colors.
///
/// Primary movers resolve to red, secondary movers to orange. Region ids
/// match the muscle-vector registry (`chest`, `abs`, `arms`, `legs`,
/// `shoulders`, `back`). Unknown exercises resolve to an empty map.
class ExerciseMuscleMapper {
  const ExerciseMuscleMapper._();

  /// Returns region-id → activation-color overrides for [exercise].
  ///
  /// Lookup is case-insensitive and trims surrounding whitespace.
  static Map<String, Color> getColorsForExercise(String exercise) {
    final key = exercise.trim().toLowerCase();
    switch (key) {
      case 'bench press':
        return {
          'chest': Colors.red,
          'arms': Colors.orange,
          'shoulders': Colors.orange,
        };
      case 'overhead press':
        return {
          'shoulders': Colors.red,
          'arms': Colors.orange,
          'chest': Colors.orange,
        };
      case 'biceps curl':
        return {
          'arms': Colors.red,
        };
      case 'triceps pushdown':
        return {
          'arms': Colors.red,
          'chest': Colors.orange,
        };
      case 'back row':
        return {
          'back': Colors.red,
          'arms': Colors.orange,
        };
      case 'squat':
        return {
          'legs': Colors.red,
          'back': Colors.orange,
        };
      case 'deadlift':
        return {
          'back': Colors.red,
          'legs': Colors.red,
          'arms': Colors.orange,
        };
      case 'crunch':
        return {
          'abs': Colors.red,
        };
      default:
        return {};
    }
  }
}
