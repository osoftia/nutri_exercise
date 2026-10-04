import '../data/clinical_profile_repository.dart';
import '../domain/clinical/clinical_condition_profile.dart';

/// In-memory repository for demo and widget-test clinical profiles.
class MockClinicalProfileRepository implements ClinicalProfileRepository {
  MockClinicalProfileRepository({
    ClinicalConditionProfile initialProfile = const ClinicalConditionProfile(),
  }) : _profile = initialProfile;

  ClinicalConditionProfile _profile;

  @override
  Future<ClinicalConditionProfile> load() async => _profile;

  @override
  Future<void> save(ClinicalConditionProfile profile) async {
    _profile = profile;
  }
}
