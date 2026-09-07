import 'package:flutter/material.dart';

/// The per-region activation breakdown of an exercise.
///
/// [primaryRegions] are the main movers (resolve to red), [secondaryRegions]
/// the supporting muscles (resolve to orange). Region ids match the
/// muscle-vector registry (`chest`, `abs`, `upper_arms`, `forearms`,
/// `thighs`, `calves`, `shoulders`, `back`).
class MuscleActivation {
  const MuscleActivation({
    this.primaryRegions = const [],
    this.secondaryRegions = const [],
  });

  final List<String> primaryRegions;
  final List<String> secondaryRegions;

  bool get isEmpty =>
      primaryRegions.isEmpty && secondaryRegions.isEmpty;
}

/// Maps common exercise names to per-region activation colors.
///
/// Unknown exercises resolve to an empty activation / color map.
class ExerciseMuscleMapper {
  const ExerciseMuscleMapper._();

  /// The exercise names that have a known activation mapping.
  static const List<String> knownExercises = [
    'Bench Press',
    'Overhead Press',
    'Biceps Curl',
    'Triceps Pushdown',
    'Back Row',
    'Squat',
    'Deadlift',
    'Crunch',
  ];

  /// Returns the region activation breakdown for [exercise].
  ///
  /// Lookup is case-insensitive and trims surrounding whitespace.
  static MuscleActivation activationFor(String exercise) {
    final key = exercise.trim().toLowerCase();
    switch (key) {
      case 'bench press':
        return const MuscleActivation(
          primaryRegions: ['chest'],
          secondaryRegions: ['upper_arms', 'shoulders'],
        );
      case 'overhead press':
        return const MuscleActivation(
          primaryRegions: ['shoulders'],
          secondaryRegions: ['upper_arms', 'chest'],
        );
      case 'biceps curl':
        return const MuscleActivation(primaryRegions: ['upper_arms']);
      case 'triceps pushdown':
        return const MuscleActivation(
          primaryRegions: ['upper_arms'],
          secondaryRegions: ['chest'],
        );
      case 'back row':
        return const MuscleActivation(
          primaryRegions: ['back'],
          secondaryRegions: ['upper_arms'],
        );
      case 'squat':
        return const MuscleActivation(
          primaryRegions: ['thighs'],
          secondaryRegions: ['calves', 'back'],
        );
      case 'deadlift':
        return const MuscleActivation(
          primaryRegions: ['thighs', 'calves'],
          secondaryRegions: ['back', 'upper_arms'],
        );
      case 'crunch':
        return const MuscleActivation(primaryRegions: ['abs']);
      default:
        return const MuscleActivation();
    }
  }

  /// Returns region-id → activation-color overrides for [exercise].
  ///
  /// Primary movers resolve to red, secondary movers to orange. Unknown
  /// exercises resolve to an empty map.
  static Map<String, Color> getColorsForExercise(String exercise) {
    final activation = activationFor(exercise);
    if (activation.isEmpty) return {};
    return {
      for (final id in activation.primaryRegions) id: Colors.red,
      for (final id in activation.secondaryRegions) id: Colors.orange,
    };
  }
}