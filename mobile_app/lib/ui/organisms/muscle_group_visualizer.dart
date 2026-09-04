import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/muscle_vectors.dart';
import '../../core/providers/routine_provider.dart';
import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/theme/app_theme.dart';
import 'interactive_body_map.dart';

class MuscleGroupVisualizer extends StatelessWidget {
  const MuscleGroupVisualizer({
    super.key,
    this.onMuscleTap,
    this.tamagotchiState,
    this.bodyWidthFactor = 1.0,
  });

  final ValueChanged<String?>? onMuscleTap;
  final MuscleTamagotchiState? tamagotchiState;

  /// Baseline body width factor (from BMI) forwarded to the avatar.
  final double bodyWidthFactor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    return Column(
      children: [
        InteractiveBodyMap(
          activeRegions: provider.activeMuscleRegions,
          selectedMuscle: provider.selectedMuscleRegion,
          tamagotchiState: tamagotchiState,
          bodyWidthFactor: bodyWidthFactor,
          onMuscleSelected: (id) {
            provider.selectMuscleRegion(id);
            onMuscleTap?.call(id);
          },
        ),
        if (provider.activeMuscleRegions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _MuscleLegendRow(
            activeRegions: provider.activeMuscleRegions,
            selectedRegion: provider.selectedMuscleRegion,
          ),
        ],
      ],
    );
  }
}

class _MuscleLegendRow extends StatelessWidget {
  const _MuscleLegendRow({
    required this.activeRegions,
    this.selectedRegion,
  });

  final Set<String> activeRegions;
  final String? selectedRegion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final regionId in activeRegions)
          _LegendItem(
            label: muscleLabel(regionId),
            color: regionId == selectedRegion
                ? AppColors.accent
                : AppColors.primary400,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
