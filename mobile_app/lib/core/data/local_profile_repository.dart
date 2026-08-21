import '../database/database_helper.dart';
import '../models/user_profile.dart';
import 'profile_repository.dart';

/// SQLite-backed [ProfileRepository] storing the profile in a single row.
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<UserProfile?> getProfile() async {
    final row = await _databaseHelper.getProfile();
    return row == null ? null : UserProfile.fromMap(row);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _databaseHelper.upsertProfile(profile);
  }
}