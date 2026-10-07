import '../data/http_timeout_settings_repository.dart';
import '../services/http_timeout_configuration.dart';

/// In-memory timeout preference store for mock flavors.
class MockHttpTimeoutSettingsRepository
    implements HttpTimeoutSettingsRepository {
  MockHttpTimeoutSettingsRepository({
    this.seconds = HttpTimeoutConfiguration.defaultSeconds,
  });

  int seconds;

  @override
  Future<int> loadTimeoutSeconds() async => seconds;

  @override
  Future<void> saveTimeoutSeconds(int value) async => seconds = value;
}
