import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nutri_mobile_app/core/services/voice_input_service.dart';

/// Test double for [VoiceInputService].
///
/// Simulates the platform recognizer deterministically so widget tests can
/// run without real microphone hardware, mirroring the
/// `MockDietRepository` / `MockRoutineRepository` convention.
class MockVoiceInputService implements VoiceInputService {
  MockVoiceInputService({
    this.denyPermission = false,
    this.transcript,
    this.unrecognized = false,
    this.throwOnListen = false,
  });

  /// When `true`, [initialize] reports that permission was denied.
  final bool denyPermission;

  /// Scripted recognized words returned on [stopListening].
  final String? transcript;

  /// When `true`, [stopListening] behaves as if nothing was recognized.
  final bool unrecognized;

  /// When `true`, [stopListening] throws a recognition error.
  final bool throwOnListen;

  /// Number of times [initialize] was called (used to verify permission
  /// caching in the widget).
  int initializeCalls = 0;

  bool _isListening = false;
  final StreamController<VoiceInputStatus> _statusController =
      StreamController<VoiceInputStatus>.broadcast();

  @override
  bool get isListening => _isListening;

  @override
  Stream<VoiceInputStatus> get status => _statusController.stream;

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return !denyPermission;
  }

  @override
  Future<void> startListening({ValueChanged<String>? onPartial}) async {
    _isListening = true;
    _statusController.add(VoiceInputStatus.listening);
    final t = transcript;
    if (t != null && t.isNotEmpty) {
      onPartial?.call(t);
    }
  }

  @override
  Future<String?> stopListening() async {
    _isListening = false;
    if (throwOnListen) {
      _statusController.add(VoiceInputStatus.unavailable);
      throw StateError('recognition failed');
    }
    if (unrecognized || transcript == null) {
      _statusController.add(VoiceInputStatus.notListening);
      return null;
    }
    _statusController.add(VoiceInputStatus.done);
    return transcript;
  }
}