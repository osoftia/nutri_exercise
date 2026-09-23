import '../config/ai_endpoint_resolver.dart';

/// Central configuration for the NutriExercise backend API.
class ApiConstants {
  ApiConstants._();

  /// Port used by the local .NET API (see backend launchSettings.json).
  static const int defaultPort = 5039;

  /// Explicit `--dart-define=API_BASE_URL=...` override (empty when unset).
  static const String dartDefineBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Built-in fallback (the Mac hosting the backend + Ollama on the LAN),
  /// with no flavor or dart-define applied.
  static String get defaultBaseUrl => 'http://192.168.1.2:$defaultPort';

  /// Fully resolved base URL: `--dart-define` wins over the built-in default.
  /// Override at build/run time, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.2:5039`
  /// (Android emulators reach the host through `10.0.2.2`).
  static String get baseUrl => AiEndpointResolver.resolveBaseUrl(
        dartDefineOverride: dartDefineBaseUrl,
        flavorBaseUrl: '',
        defaultBaseUrl: defaultBaseUrl,
      );

  /// Endpoint that generates (and persists) an AI workout routine.
  static String get generateRoutinePath => '/api/routine/generate';

  /// Endpoint that returns the list of stored routines.
  static String get routinesPath => '/api/routine';

  /// Endpoint that bridges a chat message to the RAG engine + local Ollama
  /// model (`AiProxyController`).
  static String get aiChatPath => '/api/aiproxy/chat';

  /// Endpoint that parses a free-text daily log into structured
  /// nutrition/workout data (calories, macros, muscle groups).
  static String get logParsePath => '/api/log/parse';
}
