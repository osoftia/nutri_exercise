/// Resolves the backend base URL used by AI/HTTP services.
///
/// Precedence, highest first:
/// 1. an explicit `--dart-define=API_BASE_URL` override;
/// 2. the active flavor's `apiBaseUrl`;
/// 3. the built-in fallback ([defaultBaseUrl]).
///
/// Kept free of project imports so it can be reused by both the constants
/// layer and the runtime factory without creating an import cycle.
class AiEndpointResolver {
  const AiEndpointResolver._();

  static String resolveBaseUrl({
    required String dartDefineOverride,
    required String flavorBaseUrl,
    required String defaultBaseUrl,
  }) {
    if (dartDefineOverride.isNotEmpty) return dartDefineOverride;
    if (flavorBaseUrl.isNotEmpty) return flavorBaseUrl;
    return defaultBaseUrl;
  }
}
