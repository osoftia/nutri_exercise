import '../data/app_theme_mode_repository.dart';
import '../theme/app_theme_mode.dart';

/// In-memory theme choice for mock flavors and widget tests.
class MockAppThemeModeRepository implements AppThemeModeRepository {
  MockAppThemeModeRepository({
    this.mode = AppThemeMode.technicalBlueprint,
  });

  AppThemeMode mode;

  @override
  Future<AppThemeMode> loadMode() async => mode;

  @override
  Future<void> saveMode(AppThemeMode value) async => mode = value;
}
