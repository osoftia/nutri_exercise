import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/muscle_group_map.dart';
import '../../core/data/diet_repository.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/routine_models.dart';
import '../../core/providers/routine_provider.dart';
import '../../core/services/ai_interceptor.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/exercise_card.dart';
import '../molecules/generated_routine_dialog.dart';
import '../molecules/offline_ai_dialog.dart';
import '../molecules/stat_card.dart';
import '../organisms/bottom_nav_bar.dart';
import '../organisms/muscle_group_visualizer.dart';
import '../organisms/routine_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dietRepository,
    required this.routineRepository,
  });

  final DietRepository dietRepository;
  final RoutineRepository routineRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<DailyMenu>> _menus;
  final AiService _aiService = AiService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _menus = widget.dietRepository.getDailyMenus();
  }

  Future<void> _askAi() async {
    final preferences = await _promptForPreferences();
    if (preferences == null) return;

    try {
      await _aiService.ensureOnline();
    } on OfflineException {
      if (!mounted) return;
      await showOfflineAiDialog(context);
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI service unavailable right now.')),
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final routine = await widget.routineRepository.generateRoutine(
        preferences,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await showGeneratedRoutineDialog(context, routine);
      if (!mounted) return;
      setState(() {
        _menus = widget.dietRepository.getDailyMenus();
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate the routine.')),
      );
    }
  }

  Future<String?> _promptForPreferences() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const AppHeading('Ask AI', size: AppHeadingSize.h3),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g. Push/pull 4 days, focus on chest and back',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const AppText('Cancel'),
            ),
            CustomButton(
              label: 'Generate',
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(dialogContext).pop(value.isEmpty ? null : value);
              },
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _scheduleRoutineNotification(WorkoutDay day) async {
    try {
      await _notificationService.scheduleWeeklyRoutine(
        day.id,
        _dayOfWeek(day.weekday),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weekly reminder scheduled for ${day.weekday}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are not available on this device.'),
        ),
      );
    }
  }

  int _dayOfWeek(String weekday) {
    return switch (weekday) {
      'Monday' => 1,
      'Tuesday' => 2,
      'Wednesday' => 3,
      'Thursday' => 4,
      'Friday' => 5,
      'Saturday' => 6,
      'Sunday' => 7,
      _ => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const AppHeading('Admin Dashboard', size: AppHeadingSize.h2),
      ),
      body: _buildBody(provider),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildBody(RoutineProvider provider) {
    if (provider.status == RoutineStatus.loading ||
        provider.status == RoutineStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.status == RoutineStatus.error) {
      return Center(
        child: AppText(provider.error ?? 'Failed to load routines.'),
      );
    }
    return _buildContent(provider);
  }

  Widget _buildContent(RoutineProvider provider) {
    return FutureBuilder<List<DailyMenu>>(
      future: _menus,
      builder: (context, menusSnapshot) {
        if (!menusSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final menus = menusSnapshot.data!;
        final totalMeals = menus.fold<int>(
          0,
          (sum, menu) => sum + menu.meals.length,
        );
        final totalCalories = menus.fold<int>(
          0,
          (sum, menu) => sum + menu.totalCalories,
        );
        return _buildDashboard(provider, menus, totalMeals, totalCalories);
      },
    );
  }

  Widget _buildDashboard(
    RoutineProvider provider,
    List<DailyMenu> menus,
    int totalMeals,
    int totalCalories,
  ) {
    final exercises = provider.selectedDayExercises;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomButton(label: 'Ask AI', onPressed: _askAi),
            const SizedBox(width: AppSpacing.md),
            CustomButton(
              label: 'Refresh',
              variant: CustomButtonVariant.ghost,
              onPressed: provider.loadRoutine,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Active Routines',
                value: '${provider.routine.length}',
                unit: 'days',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: StatCard(
                label: 'Meals Planned',
                value: '$totalMeals',
                unit: 'meals',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: StatCard(
                label: 'Calories',
                value: '$totalCalories',
                unit: 'kcal',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Muscle Map'),
        const SizedBox(height: AppSpacing.md),
        const MuscleGroupVisualizer(),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Exercises'),
        const SizedBox(height: AppSpacing.md),
        if (exercises.isEmpty)
          const AppText('Select a day to view exercises.')
        else
          for (final exercise in exercises)
            ExerciseCard(
              exercise: exercise,
              isHighlighted: provider.selectedMuscleRegion != null &&
                  muscleGroupToRegion[exercise.muscleGroup] ==
                      provider.selectedMuscleRegion,
              onTap: () {
                final regionId =
                    muscleGroupToRegion[exercise.muscleGroup];
                if (regionId != null) {
                  provider.selectMuscleRegion(regionId);
                }
              },
            ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Weekly Routines'),
        const SizedBox(height: AppSpacing.md),
        RoutineList(
          routines: provider.routine,
          onRoutineTap: (day) {
            provider.selectDay(day);
            _scheduleRoutineNotification(day);
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Daily Menus'),
        const SizedBox(height: AppSpacing.md),
        ...menus.map(
          (menu) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              title: AppText(menu.date),
              subtitle: AppCaption('${menu.meals.length} meals'),
              trailing: AppText('${menu.totalCalories} kcal'),
            ),
          ),
        ),
      ],
    );
  }
}
