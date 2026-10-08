import 'package:flutter/foundation.dart';

import '../data/app_theme_mode_repository.dart';
import '../theme/app_theme_mode.dart';

/// Loads and persists the app's active design language.
class AppThemeModeController extends ChangeNotifier {
  AppThemeModeController({required AppThemeModeRepository repository})
      : _repository = repository;

  final AppThemeModeRepository _repository;
  AppThemeMode _mode = AppThemeMode.technicalBlueprint;
  bool _isLoaded = false;

  AppThemeMode get mode => _mode;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _mode = await _repository.loadMode();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _repository.saveMode(mode);
  }
}
