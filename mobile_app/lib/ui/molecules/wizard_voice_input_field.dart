import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nutri_mobile_app/core/services/voice_input_service.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';

/// Wizard input field with voice-to-text support.
///
/// Shows a microphone icon that triggers permission request, a pulsing
/// "Listening..." state while capturing, and fills the field with the
/// recognized transcript. Errors (permission denied, unrecognized speech,
/// recognition failures) are surfaced inline without clearing the field.
class WizardVoiceInputField extends StatefulWidget {
  const WizardVoiceInputField({
    super.key,
    required this.service,
    this.label = 'Training goal',
  });

  final VoiceInputService service;
  final String label;

  @override
  State<WizardVoiceInputField> createState() => _WizardVoiceInputFieldState();
}

class _WizardVoiceInputFieldState extends State<WizardVoiceInputField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;
  StreamSubscription<VoiceInputStatus>? _statusSub;
  bool _initialized = false;
  bool _listening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _statusSub = widget.service.status.listen(_onStatus);
  }

  void _onStatus(VoiceInputStatus status) {
    if (!mounted) return;
    if (status == VoiceInputStatus.listening) {
      setState(() {
        _listening = true;
        _error = null;
      });
      _pulse.repeat(reverse: true);
    } else if (status == VoiceInputStatus.done ||
        status == VoiceInputStatus.notListening ||
        status == VoiceInputStatus.unavailable) {
      setState(() => _listening = false);
      _pulse.stop();
    }
  }

  Future<void> _onMicTap() async {
    setState(() => _error = null);

    if (_listening) {
      try {
        final transcript = await widget.service.stopListening();
        if (!mounted) return;
        setState(() {
          _listening = false;
          if (transcript != null && transcript.isNotEmpty) {
            _controller.text = transcript;
          } else {
            _error = 'Sorry, I did not understand that. Please try again.';
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _error = 'Voice input failed. Please try again.';
        });
      }
      _pulse.stop();
      return;
    }

    if (!_initialized) {
      final granted = await widget.service.initialize();
      if (!mounted) return;
      if (!granted) {
        setState(
          () => _error = 'Microphone permission is required to use voice input',
        );
        return;
      }
      _initialized = true;
    }

    setState(() {
      _listening = true;
      _error = null;
    });
    _pulse.repeat(reverse: true);
    await widget.service.startListening(onPartial: (partial) {
      if (mounted && partial.isNotEmpty) {
        setState(() => _controller.text = partial);
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final micIcon = IconButton(
      key: const Key('mic_button'),
      icon: Icon(_listening ? Icons.mic : Icons.mic_none),
      color: _listening ? AppColors.primary300 : AppColors.textLow,
      tooltip: 'Voice input',
      onPressed: _onMicTap,
    );

    final mic = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _listening
            ? AppColors.primary500.withOpacity(0.25)
            : Colors.transparent,
        boxShadow: _listening
            ? [
                BoxShadow(
                  color: AppColors.primary300,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: micIcon,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          readOnly: _listening,
          decoration: InputDecoration(
            hintText: _listening ? 'Listening...' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 140),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_listening) ...[
                  const Text(
                    'Listening...',
                    key: Key('listening_label'),
                    style: TextStyle(color: AppColors.primary300),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                ScaleTransition(
                  key: _listening ? const Key('mic_pulsing') : null,
                  scale: _pulseScale,
                  child: mic,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            key: const Key('voice_error'),
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}