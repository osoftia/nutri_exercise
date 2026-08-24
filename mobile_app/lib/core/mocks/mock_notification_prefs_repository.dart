import '../data/notification_prefs_repository.dart';
import '../models/notification_pref.dart';

/// In-memory test double for [NotificationPrefsRepository].
class MockNotificationPrefsRepository implements NotificationPrefsRepository {
  final Map<NotificationPrefType, bool> _values = {};

  @override
  Future<bool> isEnabled(NotificationPrefType type) async =>
      _values[type] ?? false;

  @override
  Future<void> setEnabled(NotificationPrefType type, bool value) async {
    _values[type] = value;
  }
}
