import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/domain/nutrition/portion_scaler.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

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
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _QuickAddGramsDialog(food: food, initialGrams: initialGrams),
  );
}

class _QuickAddGramsDialog extends StatefulWidget {
  const _QuickAddGramsDialog({required this.food, required this.initialGrams});

  final FoodEntry food;
  final double initialGrams;

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: NeumorphicContainer(
        key: const Key('quick_add_grams_dialog'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeading('Add ${widget.food.name}', size: AppHeadingSize.h3),
            const SizedBox(height: AppSpacing.sm),
            AppCaption(
              '${widget.food.calories} kcal · '
              'P${widget.food.proteinG} C${widget.food.carbsG} '
              'F${widget.food.fatG} per ${PortionScaler.baseGrams.toInt()} g',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('quick_add_grams_field'),
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Portion (g)',
                hintText: '100',
                suffixText: 'g',
                errorText: _error,
              ),
              onSubmitted: (_) => _confirm(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  key: const Key('quick_add_cancel'),
                  label: 'Cancel',
                  variant: CustomButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                CustomButton(
                  key: const Key('quick_add_confirm'),
                  label: 'Add',
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
