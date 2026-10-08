import '../database/database_helper.dart';
import '../theme/app_theme_mode.dart';
import 'app_theme_mode_repository.dart';

/// SQLite-backed theme choice stored in `app_settings`.
class LocalAppThemeModeRepository implements AppThemeModeRepository {
  LocalAppThemeModeRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const String settingKey = 'app_theme_mode';

  final DatabaseHelper _databaseHelper;

  @override
  Future<AppThemeMode> loadMode() async {
    final value = await _databaseHelper.getSetting(settingKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.technicalBlueprint,
    );
  }

  @override
  Future<void> saveMode(AppThemeMode mode) =>
      _databaseHelper.upsertSetting(settingKey, mode.name);
}
