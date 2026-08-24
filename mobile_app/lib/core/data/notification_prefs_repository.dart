import '../models/notification_pref.dart';

/// Contract for reading/writing notification preferences.
abstract interface class NotificationPrefsRepository {
  /// Whether [type] is currently enabled.
  Future<bool> isEnabled(NotificationPrefType type);

  /// Enables or disables [type].
  Future<void> setEnabled(NotificationPrefType type, bool value);
}
