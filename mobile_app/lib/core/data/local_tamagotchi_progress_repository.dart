import '../database/database_helper.dart';
import '../models/tamagotchi_progress.dart';
import 'tamagotchi_progress_repository.dart';

/// SQLite-backed [TamagotchiProgressRepository] storing a single progress row.
class LocalTamagotchiProgressRepository implements TamagotchiProgressRepository {
  LocalTamagotchiProgressRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<TamagotchiProgress?> get() async {
    final row = await _databaseHelper.getTamagotchiProgress();
    return row == null ? null : TamagotchiProgress.fromMap(row);
  }

  @override
  Future<void> save(TamagotchiProgress progress) =>
      _databaseHelper.upsertTamagotchiProgress(progress);
}