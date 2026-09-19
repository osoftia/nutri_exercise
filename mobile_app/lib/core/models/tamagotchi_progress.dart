import 'dart:convert';

/// Persisted tamagotchi progress, allowing the background notification
/// isolate to run the core bloat/slimming math without the UI state.
class TamagotchiProgress {
  const TamagotchiProgress({
    this.coreFullness = 0.0,
    this.mass = const {},
    this.updatedAt,
  });

  /// Normalised `[0.0, 1.0]` core fullness driving the avatar's settled width.
  final double coreFullness;

  /// Per-group muscle mass keyed by [MuscleTamagotchiGroup] name (e.g.
  /// `chest`), so the notification isolate can persist the weights without
  /// depending on the UI state enum.
  final Map<String, double> mass;

  final DateTime? updatedAt;

  /// Serializes to a SQLite row map (single row, id = 1).
  Map<String, Object?> toMap() => {
    'id': 1,
    'core_fullness': coreFullness,
    'mass_json': jsonEncode(mass),
    'updated_at': updatedAt?.toIso8601String() ?? '',
  };

  static TamagotchiProgress fromMap(Map<String, Object?> map) {
    final rawMass = map['mass_json'] as String?;
    final mass = <String, double>{};
    if (rawMass != null && rawMass.isNotEmpty) {
      final decoded = jsonDecode(rawMass);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is num) {
            mass[entry.key as String] = value.toDouble();
          }
        }
      }
    }
    return TamagotchiProgress(
      coreFullness: ((map['core_fullness'] as num?) ?? 0).toDouble(),
      mass: mass,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}
