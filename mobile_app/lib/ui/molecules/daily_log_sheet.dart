import 'package:flutter/material.dart';

import '../../core/models/log_parse_response.dart';
import '../../core/state/daily_log_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Opens the daily check-in summary sheet as a modal bottom sheet, fetching
/// historical suggestions for the autocomplete input.
Future<void> showDailyLogSheet(
  BuildContext context,
  DailyLogController controller,
) async {
  final suggestions = await controller.loadSuggestions();
  if (!context.mounted) return;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DailyLogSheet(
      controller: controller,
      suggestions: suggestions,
    ),
  );
}

/// Neumorphic text-input surface for the daily "what did you eat and train"
/// summary.
///
/// The input is an [Autocomplete] backed by [suggestions] (historical logs).
/// Submitting persists the summary through the injected [DailyLogController]
/// and, when a parser is configured, resolves it through the cache-first
/// [SmartLogger] whose calories/macros are shown in a success [SnackBar].
class DailyLogSheet extends StatefulWidget {
  const DailyLogSheet({
    super.key,
    required this.controller,
    this.suggestions = const [],
  });

  final DailyLogController controller;

  /// Historical raw texts used for autocomplete suggestions.
  final List<String> suggestions;

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
  TextEditingController? _fieldController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.controller.load();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fieldController?.text = widget.controller.text;
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await widget.controller.submit(_fieldController?.text ?? '');
    if (!saved || !mounted) return;

    final result = widget.controller.parseResult;
    final parseError = widget.controller.parseError;

    navigator.pop();

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Saved — ${_formatResult(result)}')),
      );
    } else if (parseError != null) {
      messenger.showSnackBar(SnackBar(content: Text(parseError)));
    }
  }

  String _formatResult(LogParseResponse result) {
    final parts = <String>['${result.calories} kcal'];
    if (result.protein != null) parts.add('P ${result.protein}g');
    if (result.carbs != null) parts.add('C ${result.carbs}g');
    if (result.fat != null) parts.add('F ${result.fat}g');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: NeumorphicContainer(
        key: const Key('daily_log_sheet'),
        color: AppColors.surface900,
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final isParsing = widget.controller.isParsing;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppHeading('Daily Check-in', size: AppHeadingSize.h3),
                    const SizedBox(height: AppSpacing.xs),
                    const AppCaption('What did you eat and train today?'),
                    const SizedBox(height: AppSpacing.lg),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final query = value.text.toLowerCase();
                        return widget.suggestions
                            .where(
                              (s) => s.toLowerCase().contains(query),
                            )
                            .toList();
                      },
                      onSelected: (String selection) {
                        _fieldController?.text = selection;
                      },
                      fieldViewBuilder: (
                        context,
                        textController,
                        focusNode,
                        onSubmitted,
                      ) {
                        _fieldController = textController;
                        return TextField(
                          key: const Key('daily_log_input'),
                          controller: textController,
                          focusNode: focusNode,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Type your summary…',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          label: 'Cancel',
                          variant: CustomButtonVariant.ghost,
                          onPressed: isParsing
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        CustomButton(
                          key: const Key('daily_log_save'),
                          label: isParsing ? 'Analyzing…' : 'Save',
                          disabled: isParsing,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}