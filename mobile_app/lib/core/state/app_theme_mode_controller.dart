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
  bool _isDisposed = false;

  AppThemeMode get mode => _mode;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final savedMode = await _repository.loadMode();
    if (_isDisposed) return;
    _mode = savedMode;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_isDisposed || _mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _repository.saveMode(mode);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
