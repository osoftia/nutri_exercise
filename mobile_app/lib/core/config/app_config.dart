import 'environment_config.dart';

/// Bridges the legacy [AppConfig] constructor style with the new
/// [EnvironmentConfig] / [Flavor] matrix.
///
/// Prefer [EnvironmentConfig.fromFlavor] in new code.
class AppConfig extends EnvironmentConfig {
  const AppConfig({
    required super.name,
    bool? useMocks,
    bool? useMockApi,
    super.useLocalDatabase,
    String apiUrl = '',
  }) : super(
          useMockApi: useMockApi ?? useMocks ?? false,
          apiBaseUrl: apiUrl,
        );

  String get apiUrl => apiBaseUrl;

  @Deprecated('Use useMockApi instead.')
  bool get useMocks => useMockApi;
}
