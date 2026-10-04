import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/domain/i18n/localization_scope.dart';
import '../../core/domain/nutrition/portion_scaler.dart';
import '../../core/models/food_entry.dart';
import '../../core/state/clinical_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import 'clinical_food_safety_badge.dart';

/// Opens a centered confirmation dialog asking for the portion, in grams, of a
/// quick-add [food] before it is logged.
///
/// Returns the entered gram amount, or `null` when dismissed/cancelled. The
/// value defaults to [initialGrams] (100 g), which is the reference weigh
/// portion the presets are authored against.
Future<double?> showQuickAddGramsDialog(
  BuildContext context, {
  required FoodEntry food,
  double initialGrams = PortionScaler.baseGrams,
  ClinicalProfileController? clinicalProfileController,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _QuickAddGramsDialog(
      food: food,
      initialGrams: initialGrams,
      clinicalProfileController: clinicalProfileController,
    ),
  );
}

class _QuickAddGramsDialog extends StatefulWidget {
  const _QuickAddGramsDialog({
    required this.food,
    required this.initialGrams,
    this.clinicalProfileController,
  });

  final FoodEntry food;
  final double initialGrams;
  final ClinicalProfileController? clinicalProfileController;

  @override
  State<_QuickAddGramsDialog> createState() => _QuickAddGramsDialogState();
}

class _QuickAddGramsDialogState extends State<_QuickAddGramsDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: _formatInitial(widget.initialGrams),
  );
  String? _error;

  static String _formatInitial(double grams) =>
      grams == grams.roundToDouble() ? grams.toInt().toString() : '$grams';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final grams = double.tryParse(_controller.text.trim());
    if (grams == null || !grams.isFinite || grams <= 0) {
      setState(() => _error = 'Enter a portion greater than 0 g');
      return;
    }
    Navigator.of(context).pop(grams);
  }

  Widget _clinicalGuidance() {
    final clinical = widget.clinicalProfileController;
    if (clinical == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: clinical,
      builder: (context, _) {
        if (!clinical.hasConditions) return const SizedBox.shrink();
        final grams = double.tryParse(_controller.text.trim());
        final portion = PortionScaler.scaleFood(
          widget.food,
          grams != null && grams.isFinite && grams > 0
              ? grams
              : PortionScaler.baseGrams,
        );
        return ClinicalFoodSafetyBadge(
          cardKey: const Key('quick_add_clinical_guidance'),
          verdict: clinical.evaluate(portion),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: NeumorphicContainer(
        key: const Key('quick_add_grams_dialog'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeading(
              strings.addFoodTitle(widget.food.name),
              size: AppHeadingSize.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCaption(
              '${strings.kcal(widget.food.calories)} · '
              '${strings.macroSummary(
                widget.food.proteinG,
                widget.food.carbsG,
                widget.food.fatG,
              )} '
              'per ${PortionScaler.baseGrams.toInt()} g',
            ),
            if (widget.clinicalProfileController != null) ...[
              const SizedBox(height: AppSpacing.md),
              _clinicalGuidance(),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('quick_add_grams_field'),
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: AppInputDecoration.rounded(
                label: strings.portionLabel,
                hint: '100',
                suffix: 'g',
              ).copyWith(errorText: _error),
              onSubmitted: (_) => _confirm(),
              onChanged: (_) {
                setState(() => _error = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  key: const Key('quick_add_cancel'),
                  label: strings.cancel,
                  variant: CustomButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                CustomButton(
                  key: const Key('quick_add_confirm'),
                  label: strings.add,
                  onPressed: _confirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
