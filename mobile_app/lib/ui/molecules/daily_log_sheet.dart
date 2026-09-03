import 'package:flutter/material.dart';

import '../../core/state/daily_log_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Opens the daily check-in summary sheet as a modal bottom sheet.
Future<void> showDailyLogSheet(
  BuildContext context,
  DailyLogController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DailyLogSheet(controller: controller),
  );
}

/// Neumorphic text-input surface for the daily "what did you eat and train"
/// summary.
///
/// Owns and disposes its [TextEditingController] in [State.dispose]. The saved
/// summary lives in the injected [DailyLogController], which persists it.
class DailyLogSheet extends StatefulWidget {
  const DailyLogSheet({super.key, required this.controller});

  final DailyLogController controller;

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await widget.controller.load();
    if (!mounted) return;
    _controller.text = widget.controller.text;
  }

  Future<void> _save() async {
    final saved = await widget.controller.save(_controller.text);
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeading('Daily Check-in', size: AppHeadingSize.h3),
                const SizedBox(height: AppSpacing.xs),
                const AppCaption('What did you eat and train today?'),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('daily_log_input'),
                  controller: _controller,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Type your summary…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      label: 'Cancel',
                      variant: CustomButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    CustomButton(
                      key: const Key('daily_log_save'),
                      label: 'Save',
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
