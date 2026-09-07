import '../data/tamagotchi_progress_repository.dart';
import '../models/tamagotchi_progress.dart';

/// In-memory [TamagotchiProgressRepository] for tests.
class MockTamagotchiProgressRepository implements TamagotchiProgressRepository {
  MockTamagotchiProgressRepository([this._progress]);

  TamagotchiProgress? _progress;

  @override
  Future<TamagotchiProgress?> get() async => _progress;

  @override
  Future<void> save(TamagotchiProgress progress) async {
    _progress = progress;
  }
}