enum Environment { dev, local, qa, prod }

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.name,
    required this.useMockApi,
    this.useLocalDatabase = false,
    this.apiBaseUrl = '',
    this.mockLatency = const Duration(milliseconds: 500),
  });

  final String name;
  final bool useMockApi;
  final bool useLocalDatabase;
  final String apiBaseUrl;
  final Duration mockLatency;

  EnvironmentConfig withDartDefineOverrides() {
    final mockOverride = const String.fromEnvironment('USE_MOCK_API');
    final apiOverride = const String.fromEnvironment('API_BASE_URL');

    return EnvironmentConfig(
      name: name,
      useMockApi: mockOverride.isEmpty
          ? useMockApi
          : mockOverride.toLowerCase() == 'true',
      useLocalDatabase: useLocalDatabase,
      apiBaseUrl: apiOverride.isEmpty ? apiBaseUrl : apiOverride,
      mockLatency: mockLatency,
    );
  }

  static EnvironmentConfig dev() {
    return const EnvironmentConfig(name: 'dev', useMockApi: true);
  }

  static EnvironmentConfig local() {
    return const EnvironmentConfig(
      name: 'local',
      useMockApi: false,
      useLocalDatabase: true,
    );
  }

  static EnvironmentConfig qa({String apiBaseUrl = ''}) {
    return EnvironmentConfig(
      name: 'qa',
      useMockApi: false,
      apiBaseUrl: apiBaseUrl,
    );
  }

  static EnvironmentConfig prod({String apiBaseUrl = ''}) {
    return EnvironmentConfig(
      name: 'prod',
      useMockApi: false,
      apiBaseUrl: apiBaseUrl,
    );
  }
}
