import 'package:flutter/foundation.dart';

/// The four gamified muscle groups of the tamagotchi avatar.
enum MuscleTamagotchiGroup { core, arms, chest, legs }

/// Tier derived from a group's mass, used for heatmap colouring.
enum MuscleTier { c, b, a, s }

/// Owns the tamagotchi avatar's muscle mass, growth and decay.
///
/// Each group holds a normalised [0.0, 1.0] mass value. Completing a routine
/// [applyGrowth]s the targeted groups; time passing without training
/// [applyDecay]s every group.
class MuscleTamagotchiState extends ChangeNotifier {
  MuscleTamagotchiState({
    Map<MuscleTamagotchiGroup, double> initialMass = const {},
    this.growthDelta = 0.08,
    this.decayPerDay = 0.05,
  }) {
    for (final group in MuscleTamagotchiGroup.values) {
      _mass[group] = (initialMass[group] ?? baseline).clamp(0.0, 1.0);
    }
  }

  /// Neutral starting mass for every group.
  static const double baseline = 0.5;

  /// Mass gained per completed routine targeting the group.
  final double growthDelta;

  /// Mass lost per full day of inactivity.
  final double decayPerDay;

  final Map<MuscleTamagotchiGroup, double> _mass = {};

  /// Current mass of [group], always within `[0.0, 1.0]`.
  double massOf(MuscleTamagotchiGroup group) => _mass[group] ?? baseline;

  /// Tier derived from [group]'s mass.
  MuscleTier tierOf(MuscleTamagotchiGroup group) {
    final mass = massOf(group);
    if (mass >= 0.9) return MuscleTier.s;
    if (mass >= 0.66) return MuscleTier.a;
    if (mass >= 0.33) return MuscleTier.b;
    return MuscleTier.c;
  }

  /// Grows the given groups by [growthDelta], clamped at `1.0`.
  void applyGrowth(Iterable<MuscleTamagotchiGroup> groups) {
    for (final group in groups) {
      _mass[group] = (_mass[group] ?? baseline).clamp(0.0, 1.0);
      _mass[group] = (_mass[group]! + growthDelta).clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  /// Decays every group by [decayPerDay] scaled to [elapsed], clamped at `0.0`.
  void applyDecay(Duration elapsed) {
    final days = elapsed.inMilliseconds / Duration.millisecondsPerDay;
    final amount = decayPerDay * days;
    for (final group in MuscleTamagotchiGroup.values) {
      _mass[group] = ((_mass[group] ?? baseline) - amount).clamp(0.0, 1.0);
    }
    notifyListeners();
  }
}
