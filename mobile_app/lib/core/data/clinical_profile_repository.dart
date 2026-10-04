import '../domain/clinical/clinical_condition_profile.dart';

/// Persistence contract for a user's active clinical guidance profile.
abstract interface class ClinicalProfileRepository {
  Future<ClinicalConditionProfile> load();

  Future<void> save(ClinicalConditionProfile profile);
}
