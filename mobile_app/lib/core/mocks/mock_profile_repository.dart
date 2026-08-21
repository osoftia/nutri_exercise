import '../data/profile_repository.dart';
import '../models/user_profile.dart';

/// In-memory test double for [ProfileRepository].
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({UserProfile? profile}) : _profile = profile;

  UserProfile? _profile;

  @override
  Future<UserProfile?> getProfile() async => _profile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
  }
}