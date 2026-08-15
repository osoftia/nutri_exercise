import 'environment_config.dart';

/// Bridges the legacy [AppConfig] constructor style with the new
/// [EnvironmentConfig] / [Flavor] matrix.
///
/// Prefer [EnvironmentConfig.fromFlavor] in new code.
class AppConfig extends EnvironmentConfig {
  const AppConfig({
    required String name,
    bool? useMocks,
    bool? useMockApi,
    bool useLocalDatabase = false,
    String apiUrl = '',
  }) : super(
          name: name,
          useMockApi: useMockApi ?? useMocks ?? false,
          useLocalDatabase: useLocalDatabase,
          apiBaseUrl: apiUrl,
        );

  String get apiUrl => apiBaseUrl;

  @Deprecated('Use useMockApi instead.')
  bool get useMocks => useMockApi;
}
