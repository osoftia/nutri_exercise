/// Central configuration for the NutriExercise backend API.
class ApiConstants {
  ApiConstants._();

  /// Port used by the local .NET API (see backend launchSettings.json).
  static const int defaultPort = 5039;

  /// Optional override at build time, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5039`.
  static const String _dartDefine = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the C# backend (the Mac hosting the backend + Ollama on the
  /// LAN, port 5039).
  ///
  /// The default points at the Mac's LAN IP. Override at build/run time when
  /// the Mac's IP changes or when testing on an emulator, e.g.:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.6:5039`
  /// (Android emulators reach the host through `10.0.2.2`).
  static String get baseUrl {
    if (_dartDefine.isNotEmpty) return _dartDefine;
    return 'http://192.168.1.6:$defaultPort';
  }

  /// Endpoint that generates (and persists) an AI workout routine.
  static String get generateRoutinePath => '/api/routine/generate';

  /// Endpoint that returns the list of stored routines.
  static String get routinesPath => '/api/routine';

  /// Endpoint that bridges a chat message to the local Ollama model.
  static String get aiChatPath => '/api/ai/chat';

  /// Endpoint that parses a free-text daily log into structured
  /// nutrition/workout data (calories, macros, muscle groups).
  static String get logParsePath => '/api/log/parse';
}
