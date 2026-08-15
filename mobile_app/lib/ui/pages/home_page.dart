import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/muscle_group_map.dart';
import '../../core/data/diet_repository.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/routine_models.dart';
import '../../core/providers/routine_provider.dart';
import '../../core/providers/wizard_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/exercise_card.dart';
import '../molecules/stat_card.dart';
import '../organisms/bottom_nav_bar.dart';
import '../organisms/muscle_group_visualizer.dart';
import '../organisms/routine_list.dart';
import 'wizard_page.dart';

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
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _menus = widget.dietRepository.getDailyMenus();
  }

  void _launchWizard() {
    context.read<RoutineWizardProvider>().reset();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WizardPage()),
    );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textHigh,
        onPressed: _launchWizard,
        tooltip: 'Generate Routine',
        child: const Icon(Icons.auto_awesome),
      ),
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
            CustomButton(label: 'Ask AI', onPressed: _launchWizard),
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
