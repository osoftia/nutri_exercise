import 'package:flutter/material.dart';

import '../../core/data/routine_repository.dart';
import '../../core/services/ai_interceptor.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

/// End-to-end verification screen that calls the real backend
/// `POST /api/routine/generate` endpoint and renders the AI result.
class AiRoutineTestScreen extends StatefulWidget {
  const AiRoutineTestScreen({
    super.key,
    required this.routineRepository,
    this.aiService,
  });

  final RoutineRepository routineRepository;
  final AiService? aiService;

  @override
  State<AiRoutineTestScreen> createState() => _AiRoutineTestScreenState();
}

class _AiRoutineTestScreenState extends State<AiRoutineTestScreen> {
  final TextEditingController _preferencesController = TextEditingController(
    text: '3 days a week, focus on back and biceps',
  );
  late final AiService _aiService = widget.aiService ?? AiService();

  bool _loading = false;
  String? _result;
  String? _error;
  bool _offlineFallback = false;

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final preferences = _preferencesController.text.trim();
    if (preferences.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
      _offlineFallback = false;
    });

    bool offline = false;
    try {
      await _aiService.ensureOnline();
    } catch (_) {
      offline = true;
    }
    if (!mounted) return;
    setState(() => _offlineFallback = offline);

    try {
      final routine = await widget.routineRepository.generateRoutine(
        preferences,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = routine;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Generation failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppHeading('AI Routine E2E', size: AppHeadingSize.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const AppText(
            'Describe your training preferences and generate a routine via '
            'POST /api/routine/generate.',
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _preferencesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Preferences',
              hintText: 'e.g. 3 days a week, focus on back and biceps',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            label: 'Generate Routine with AI',
            disabled: _loading,
            onPressed: _generate,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_result != null)
            _ResultCard(result: _result!, offline: _offlineFallback)
          else if (_error != null)
            _ErrorCard(message: _error!),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.offline});

  final String result;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                const AppHeading('Generated Routine', size: AppHeadingSize.h3),
                const Spacer(),
                if (offline)
                  const Chip(
                    backgroundColor: AppColors.surface700,
                    label: AppCaption('Offline fallback'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(result, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppText(
                message,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
