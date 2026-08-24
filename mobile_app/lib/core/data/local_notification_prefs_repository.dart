import '../database/database_helper.dart';
import '../models/notification_pref.dart';
import 'notification_prefs_repository.dart';

/// SQLite-backed [NotificationPrefsRepository].
///
/// Persists each preference as a row in the `notification_prefs` table keyed
/// by [NotificationPrefType.key]. Missing rows are treated as disabled.
class LocalNotificationPrefsRepository implements NotificationPrefsRepository {
  LocalNotificationPrefsRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<bool> isEnabled(NotificationPrefType type) async {
    final rows = await _databaseHelper.getNotificationPrefs();
    for (final row in rows) {
      if (row['pref_key'] == type.key) {
        return (row['enabled'] as int) == 1;
      }
    }
    return false;
  }

  @override
  Future<void> setEnabled(NotificationPrefType type, bool value) async {
    await _databaseHelper.upsertNotificationPref(type.key, value);
  }
}
