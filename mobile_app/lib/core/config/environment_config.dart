enum Flavor { dev, local, qa, prod }

/// Encapsulates every configuration factor that varies per [Flavor].
class FlavorFactors {
  const FlavorFactors({
    required this.useMockApi,
    required this.useLocalDatabase,
    required this.apiBaseUrl,
    this.mockLatency = const Duration(milliseconds: 500),
    this.enableNotifications = true,
    this.enableAI = true,
    this.logLevel = 'info',
  });

  final bool useMockApi;
  final bool useLocalDatabase;
  final String apiBaseUrl;
  final Duration mockLatency;
  final bool enableNotifications;
  final bool enableAI;
  final String logLevel;
}

/// Central, immutable configuration resolved at startup.
///
/// The canonical source of truth is [flavorMatrix], which maps every
/// [Flavor] to its corresponding [FlavorFactors].  At run-time the
/// app reads [current] – a singleton set once by [initialize].
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.name,
    required this.useMockApi,
    this.useLocalDatabase = false,
    this.apiBaseUrl = '',
    this.mockLatency = const Duration(milliseconds: 500),
    this.enableNotifications = true,
    this.enableAI = true,
    this.logLevel = 'info',
  });

  final String name;
  final bool useMockApi;
  final bool useLocalDatabase;
  final String apiBaseUrl;
  final Duration mockLatency;
  final bool enableNotifications;
  final bool enableAI;
  final String logLevel;

  /// Resolved [Flavor] derived from [name].
  Flavor get flavor => Flavor.values.firstWhere(
        (f) => f.name == name,
        orElse: () => Flavor.dev,
      );

  /// Convenience accessor that bundles all factors into a [FlavorFactors].
  FlavorFactors get factors => FlavorFactors(
        useMockApi: useMockApi,
        useLocalDatabase: useLocalDatabase,
        apiBaseUrl: apiBaseUrl,
        mockLatency: mockLatency,
        enableNotifications: enableNotifications,
        enableAI: enableAI,
        logLevel: logLevel,
      );

  // ── Flavor matrix (single source of truth) ─────────────────────
  static const Map<Flavor, FlavorFactors> flavorMatrix = {
    Flavor.dev: FlavorFactors(
      useMockApi: true,
      useLocalDatabase: false,
      apiBaseUrl: '',
      mockLatency: Duration(milliseconds: 500),
      enableNotifications: true,
      enableAI: true,
      logLevel: 'debug',
    ),
    Flavor.local: FlavorFactors(
      useMockApi: false,
      useLocalDatabase: true,
      apiBaseUrl: '',
      mockLatency: Duration(milliseconds: 200),
      enableNotifications: false,
      enableAI: false,
      logLevel: 'debug',
    ),
    Flavor.qa: FlavorFactors(
      useMockApi: false,
      useLocalDatabase: false,
      apiBaseUrl: 'https://qa-api.example.com',
      mockLatency: Duration(milliseconds: 300),
      enableNotifications: true,
      enableAI: true,
      logLevel: 'info',
    ),
    Flavor.prod: FlavorFactors(
      useMockApi: false,
      useLocalDatabase: false,
      apiBaseUrl: 'https://api.example.com',
      mockLatency: Duration(milliseconds: 0),
      enableNotifications: true,
      enableAI: true,
      logLevel: 'warning',
    ),
  };

  // ── dart-define overrides ──────────────────────────────────────
  /// Returns a new [EnvironmentConfig] with any `--dart-define` values
  /// (USE_MOCK_API, API_BASE_URL) applied on top of the current config.
  EnvironmentConfig withDartDefineOverrides() {
    const mockOverride = String.fromEnvironment('USE_MOCK_API');
    const apiOverride = String.fromEnvironment('API_BASE_URL');

    return EnvironmentConfig(
      name: name,
      useMockApi: mockOverride.isEmpty
          ? useMockApi
          : mockOverride.toLowerCase() == 'true',
      useLocalDatabase: useLocalDatabase,
      apiBaseUrl: apiOverride.isEmpty ? apiBaseUrl : apiOverride,
      mockLatency: mockLatency,
      enableNotifications: enableNotifications,
      enableAI: enableAI,
      logLevel: logLevel,
    );
  }

  // ── factory helpers ────────────────────────────────────────────
  /// Creates an [EnvironmentConfig] for the given [flavor].
  factory EnvironmentConfig.fromFlavor(Flavor flavor) {
    final f = flavorMatrix[flavor]!;
    return EnvironmentConfig(
      name: flavor.name,
      useMockApi: f.useMockApi,
      useLocalDatabase: f.useLocalDatabase,
      apiBaseUrl: f.apiBaseUrl,
      mockLatency: f.mockLatency,
      enableNotifications: f.enableNotifications,
      enableAI: f.enableAI,
      logLevel: f.logLevel,
    );
  }

  // ── static singleton (set once at startup) ─────────────────────
  static EnvironmentConfig? _current;

  static EnvironmentConfig get current {
    assert(_current != null, 'Call EnvironmentConfig.initialize first.');
    return _current!;
  }

  /// Call exactly once in `main()` before `runApp`.
  static void initialize(Flavor flavor) {
    _current = EnvironmentConfig.fromFlavor(flavor);
  }

  // ── backwards-compatible static constructors ───────────────────
  @Deprecated('Use EnvironmentConfig.fromFlavor(Flavor.dev) instead.')
  static EnvironmentConfig dev() => EnvironmentConfig.fromFlavor(Flavor.dev);

  @Deprecated('Use EnvironmentConfig.fromFlavor(Flavor.local) instead.')
  static EnvironmentConfig local() =>
      EnvironmentConfig.fromFlavor(Flavor.local);

  @Deprecated('Use EnvironmentConfig.fromFlavor(Flavor.qa) instead.')
  static EnvironmentConfig qa({String apiBaseUrl = ''}) {
    final base = flavorMatrix[Flavor.qa]!;
    return EnvironmentConfig(
      name: 'qa',
      useMockApi: base.useMockApi,
      useLocalDatabase: base.useLocalDatabase,
      apiBaseUrl: apiBaseUrl.isEmpty ? base.apiBaseUrl : apiBaseUrl,
      mockLatency: base.mockLatency,
      enableNotifications: base.enableNotifications,
      enableAI: base.enableAI,
      logLevel: base.logLevel,
    );
  }

  @Deprecated('Use EnvironmentConfig.fromFlavor(Flavor.prod) instead.')
  static EnvironmentConfig prod({String apiBaseUrl = ''}) {
    final base = flavorMatrix[Flavor.prod]!;
    return EnvironmentConfig(
      name: 'prod',
      useMockApi: base.useMockApi,
      useLocalDatabase: base.useLocalDatabase,
      apiBaseUrl: apiBaseUrl.isEmpty ? base.apiBaseUrl : apiBaseUrl,
      mockLatency: base.mockLatency,
      enableNotifications: base.enableNotifications,
      enableAI: base.enableAI,
      logLevel: base.logLevel,
    );
  }

  @override
  String toString() =>
      'EnvironmentConfig(flavor=${flavor.name}, useMockApi=$useMockApi, '
      'useLocalDatabase=$useLocalDatabase, apiBaseUrl=$apiBaseUrl)';
}
