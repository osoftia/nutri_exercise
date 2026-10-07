import 'package:flutter/foundation.dart';

import '../data/http_timeout_settings_repository.dart';
import '../services/http_timeout_configuration.dart';

/// Reactive settings state shared by the Profile UI and HTTP clients.
class HttpTimeoutSettingsController extends ChangeNotifier {
  HttpTimeoutSettingsController({
    required HttpTimeoutSettingsRepository repository,
  }) : _repository = repository;

  final HttpTimeoutSettingsRepository _repository;
  int _timeoutSeconds = HttpTimeoutConfiguration.defaultSeconds;
  bool _isLoaded = false;

  int get timeoutSeconds => _timeoutSeconds;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final saved = await _repository.loadTimeoutSeconds();
    _timeoutSeconds = saved
        .clamp(
          HttpTimeoutConfiguration.minimumSeconds,
          HttpTimeoutConfiguration.maximumSeconds,
        )
        .toInt();
    HttpTimeoutConfiguration.setSeconds(_timeoutSeconds);
    _isLoaded = true;
    notifyListeners();
  }

  /// Applies a slider value immediately, before its final value is persisted.
  void previewTimeoutSeconds(int seconds) {
    HttpTimeoutConfiguration.setSeconds(seconds);
    _timeoutSeconds = seconds;
    notifyListeners();
  }

  Future<void> saveTimeoutSeconds() =>
      _repository.saveTimeoutSeconds(_timeoutSeconds);

  Future<void> setTimeoutSeconds(int seconds) async {
    HttpTimeoutConfiguration.setSeconds(seconds);
    _timeoutSeconds = seconds;
    notifyListeners();
    await _repository.saveTimeoutSeconds(seconds);
  }
}
