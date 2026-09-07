import '../models/tamagotchi_progress.dart';

/// Contract for reading and persisting the tamagotchi core progress, usable
/// from the notification background isolate.
abstract interface class TamagotchiProgressRepository {
  /// Returns the stored progress, or `null` when nothing has been saved.
  Future<TamagotchiProgress?> get();

  /// Persists (upserts) [progress].
  Future<void> save(TamagotchiProgress progress);
}