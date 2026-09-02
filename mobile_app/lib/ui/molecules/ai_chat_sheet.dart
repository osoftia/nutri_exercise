import 'package:flutter/material.dart';

import '../../core/services/ai_interceptor.dart';
import '../../core/state/ai_chat_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/neumorphic_fab.dart';
import '../atoms/typography.dart';
import 'offline_ai_dialog.dart';

/// Opens the neumorphic AI assistant chat in a modal bottom sheet.
Future<void> showAiChatSheet(
  BuildContext context,
  AiChatController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AiChatSheet(controller: controller),
  );
}

/// Neumorphic chat surface for the AI assistant.
///
/// Owns and disposes its [TextEditingController] in [State.dispose], so there
/// is no controller leak when the sheet is dismissed. Chat state lives in the
/// injected [AiChatController], which drives the loading indicator, the
/// assistant reply and any error copy.
class AiChatSheet extends StatefulWidget {
  const AiChatSheet({super.key, required this.controller});

  final AiChatController controller;

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  late final AiService _aiService = AiService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.controller.isLoading) return;
    _controller.clear();

    try {
      await _aiService.ensureOnline();
    } on OfflineException {
      if (!mounted) return;
      widget.controller.appendUserMessage(text);
      await showOfflineAiDialog(context);
      return;
    } catch (_) {
      if (!mounted) return;
      widget.controller.appendUserMessage(text);
      widget.controller.appendErrorMessage('AI service unavailable right now.');
      return;
    }

    await widget.controller.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: NeumorphicContainer(
        color: AppColors.surface900,
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final messages = widget.controller.messages;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: messages.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: AppText(
                              'Ask me to build a workout routine.',
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) =>
                                _buildBubble(messages[index], index),
                          ),
                  ),
                  if (widget.controller.isLoading)
                    const Padding(
                      key: Key('ai_chat_loading'),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                  if (widget.controller.errorMessage != null)
                    Padding(
                      key: const Key('ai_chat_error'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: AppText(
                        widget.controller.errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  _buildInputRow(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppHeading('AI Assistant', size: AppHeadingSize.h3),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: AppColors.textLow),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(AiChatMessage message, int index) {
    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: NeumorphicContainer(
          key: Key('ai_chat_bubble_$index'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          borderRadius: AppRadius.md,
          color: message.isUser ? AppColors.primary500 : AppColors.surface800,
          child: AppText(
            message.text,
            style: TextStyle(
              color: message.isUser ? AppColors.textHigh : AppColors.textMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: NeumorphicContainer(
              inset: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              borderRadius: AppRadius.md,
              child: TextField(
                key: const Key('ai_chat_input'),
                controller: _controller,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Ask for a workout routine…',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          NeumorphicFab(
            tooltip: 'Send',
            icon: Icons.send,
            size: 48,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
