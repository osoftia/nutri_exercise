/// Persistence contract for the user's global HTTP request timeout.
abstract interface class HttpTimeoutSettingsRepository {
  Future<int> loadTimeoutSeconds();

  Future<void> saveTimeoutSeconds(int seconds);
}
