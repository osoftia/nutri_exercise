import '../database/database_helper.dart';
import '../domain/clinical/clinical_condition_profile.dart';
import 'clinical_profile_repository.dart';

/// Stores the user's clinical conditions in the existing key-value settings
/// table, so no additional table or migration is required.
class LocalClinicalProfileRepository implements ClinicalProfileRepository {
  LocalClinicalProfileRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const String settingKey = 'clinical_condition_profile';

  final DatabaseHelper _databaseHelper;

  @override
  Future<ClinicalConditionProfile> load() async {
    final raw = await _databaseHelper.getSetting(settingKey);
    if (raw == null) return const ClinicalConditionProfile();
    try {
      return ClinicalConditionProfile.decode(raw);
    } on FormatException {
      return const ClinicalConditionProfile();
    }
  }

  @override
  Future<void> save(ClinicalConditionProfile profile) =>
      _databaseHelper.upsertSetting(settingKey, profile.encode());
}
