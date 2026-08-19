import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lifecycle status of the voice input flow.
enum VoiceInputStatus { idle, listening, done, notListening, unavailable }

/// Contract for voice-to-text input.
///
/// Concrete implementations either wrap the `speech_to_text` plugin
/// ([SpeechToTextVoiceInputService]) or simulate the platform for widget
/// tests ([MockVoiceInputService]), mirroring the constructor-based DI
/// pattern used by the repository layer.
abstract class VoiceInputService {
  /// Warms up the recognizer and requests microphone permission.
  ///
  /// Returns `true` when permission was granted and the recognizer is ready.
  Future<bool> initialize();

  /// Starts listening for speech.
  ///
  /// [onPartial] is invoked with partial transcripts as words are recognized.
  Future<void> startListening({ValueChanged<String>? onPartial});

  /// Stops listening and returns the final transcript, or `null` when no
  /// words were recognized.
  Future<String?> stopListening();

  /// Whether a listen session is currently active.
  bool get isListening;

  /// Stream of [VoiceInputStatus] changes emitted by the recognizer.
  Stream<VoiceInputStatus> get status;
}