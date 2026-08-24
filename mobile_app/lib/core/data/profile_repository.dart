import '../models/user_profile.dart';

/// Contract for reading and persisting the single user profile.
abstract interface class ProfileRepository {
  /// Returns the saved profile, or `null` when none has been saved yet.
  Future<UserProfile?> getProfile();

  /// Persists (upserts) the given profile.
  Future<void> saveProfile(UserProfile profile);
}