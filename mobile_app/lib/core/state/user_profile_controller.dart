import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
import '../models/user_profile.dart';

/// ChangeNotifier that owns the user profile state and notifies listeners
/// whenever the profile is loaded or saved, so the UI reflects changes
/// immediately.
class UserProfileController extends ChangeNotifier {
  UserProfileController({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  UserProfile? _profile;
  bool _isLoading = false;

  /// The current profile, or `null` while loading / never saved.
  UserProfile? get profile => _profile;

  bool get isLoading => _isLoading;

  /// Reads the persisted profile and notifies listeners.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _profile = await _repository.getProfile();
    _isLoading = false;
    notifyListeners();
  }

  /// Persists [profile] and immediately updates the in-memory state.
  Future<void> save(UserProfile profile) async {
    await _repository.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }
}