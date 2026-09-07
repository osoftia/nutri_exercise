/// Persisted tamagotchi progress, allowing the background notification
/// isolate to run the core bloat/slimming math without the UI state.
class TamagotchiProgress {
  const TamagotchiProgress({this.coreFullness = 0.0, this.updatedAt});

  /// Normalised `[0.0, 1.0]` core fullness driving the avatar's settled width.
  final double coreFullness;

  final DateTime? updatedAt;

  /// Serializes to a SQLite row map (single row, id = 1).
  Map<String, Object?> toMap() => {
    'id': 1,
    'core_fullness': coreFullness,
    'updated_at': updatedAt?.toIso8601String() ?? '',
  };

  static TamagotchiProgress fromMap(Map<String, Object?> map) =>
      TamagotchiProgress(
        coreFullness: ((map['core_fullness'] as num?) ?? 0).toDouble(),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
      );
}