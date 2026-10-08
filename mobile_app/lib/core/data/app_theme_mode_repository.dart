import '../theme/app_theme_mode.dart';

/// Persistence contract for the selected application design language.
abstract interface class AppThemeModeRepository {
  Future<AppThemeMode> loadMode();

  Future<void> saveMode(AppThemeMode mode);
}
