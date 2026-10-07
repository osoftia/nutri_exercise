import '../database/database_helper.dart';
import '../services/http_timeout_configuration.dart';
import 'http_timeout_settings_repository.dart';

/// Stores the global request timeout in the existing SQLite app settings.
class LocalHttpTimeoutSettingsRepository
    implements HttpTimeoutSettingsRepository {
  LocalHttpTimeoutSettingsRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const String settingKey = 'http_timeout_seconds';

  final DatabaseHelper _databaseHelper;

  @override
  Future<int> loadTimeoutSeconds() async {
    final raw = await _databaseHelper.getSetting(settingKey);
    final seconds = int.tryParse(raw ?? '');
    if (seconds == null ||
        seconds < HttpTimeoutConfiguration.minimumSeconds ||
        seconds > HttpTimeoutConfiguration.maximumSeconds) {
      return HttpTimeoutConfiguration.defaultSeconds;
    }
    return seconds;
  }

  @override
  Future<void> saveTimeoutSeconds(int seconds) => _databaseHelper.upsertSetting(
        settingKey,
        '$seconds',
      );
}
