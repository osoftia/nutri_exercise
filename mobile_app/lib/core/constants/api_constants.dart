import 'dart:io';

import 'package:flutter/foundation.dart';

/// Central configuration for the NutriExercise backend API.
class ApiConstants {
  ApiConstants._();

  /// Port used by the local .NET API (see backend launchSettings.json).
  static const int defaultPort = 5039;

  /// Optional override at build time, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5039`.
  static const String _dartDefine = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the C# backend.
  ///
  /// Milestone 5 targets the Mac hosting the backend + Ollama on the LAN.
  /// Set the Mac's local IP at build/run time, e.g.:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.42:5039`.
  ///
  /// Fallbacks when no override is provided:
  /// - Android emulators reach the host machine through `10.0.2.2`.
  /// - iOS simulators and web run on `localhost`.
  /// - A physical device should pass its Mac host via `--dart-define=API_BASE_URL`.
  static String get baseUrl {
    if (_dartDefine.isNotEmpty) return _dartDefine;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://192.168.1.2:$defaultPort';
    }
    return 'http://localhost:$defaultPort';
  }

  /// Endpoint that generates (and persists) an AI workout routine.
  static String get generateRoutinePath => '/api/routine/generate';

  /// Endpoint that returns the list of stored routines.
  static String get routinesPath => '/api/routine';
}
