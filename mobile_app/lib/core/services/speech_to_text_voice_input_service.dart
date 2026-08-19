import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nutri_mobile_app/core/services/voice_input_service.dart';

/// Real implementation of [VoiceInputService] backed by the `speech_to_text`
/// plugin.
///
/// This is the only class that talks to the platform channel; widget tests
/// must never reach it (they inject [MockVoiceInputService] instead).
class SpeechToTextVoiceInputService implements VoiceInputService {
  SpeechToTextVoiceInputService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  final StreamController<VoiceInputStatus> _statusController =
      StreamController<VoiceInputStatus>.broadcast();
  String _lastWords = '';

  @override
  bool get isListening => _speech.isListening;

  @override
  Stream<VoiceInputStatus> get status => _statusController.stream;

  @override
  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onStatus: _mapStatus,
      onError: (_) => _statusController.add(VoiceInputStatus.unavailable),
    );
    return available;
  }

  void _mapStatus(String status) {
    if (status == stt.SpeechToText.listeningStatus) {
      _statusController.add(VoiceInputStatus.listening);
    } else if (status == stt.SpeechToText.doneStatus) {
      _statusController.add(VoiceInputStatus.done);
    } else if (status == stt.SpeechToText.notListeningStatus) {
      _statusController.add(VoiceInputStatus.notListening);
    }
  }

  @override
  Future<void> startListening({ValueChanged<String>? onPartial}) async {
    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (_lastWords.isNotEmpty) {
            onPartial?.call(_lastWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      _statusController.add(VoiceInputStatus.unavailable);
    }
  }

  @override
  Future<String?> stopListening() async {
    await _speech.stop();
    if (_lastWords.isNotEmpty) {
      return _lastWords;
    }
    return null;
  }
}