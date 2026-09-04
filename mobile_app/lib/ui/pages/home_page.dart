import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/environment_config.dart';
import '../../core/constants/muscle_group_map.dart';
import '../../core/data/diet_repository.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/log_parse_response.dart';
import '../../core/models/user_profile.dart';
import '../../core/state/body_proportions.dart';
import '../../core/state/daily_nutrition_state.dart';
import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/providers/environment_provider.dart';
import '../../core/providers/routine_provider.dart';
import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/daily_totals_card.dart';
import '../molecules/exercise_card.dart';
import '../organisms/bottom_nav_bar.dart';
import '../organisms/muscle_group_visualizer.dart';
import 'wizard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dietRepository,
    required this.routineRepository,
    this.profile,
  });

  final DietRepository dietRepository;
  final RoutineRepository routineRepository;

  /// The user's profile; drives the avatar's baseline width via BMI.
  final UserProfile? profile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<DailyMenu>> _menus;
  final MuscleTamagotchiState _tamagotchi = MuscleTamagotchiState();
  final DailyNutritionState _nutrition = DailyNutritionState();

  @override
  void initState() {
    super.initState();
    _menus = widget.dietRepository.getDailyMenus();
  }

  @override
  void dispose() {
    _tamagotchi.dispose();
    _nutrition.dispose();
    super.dispose();
  }

  double get _bodyWidthFactor {
    final profile = widget.profile;
    if (profile == null ||
        profile.heightCm <= 0 ||
        profile.weightKg <= 0) {
      return 1.0;
    }
    return widthFactorForBmi(bmi(profile.heightCm, profile.weightKg));
  }

  void _simulateCoreWorkout() {
    _tamagotchi.applyGrowth([MuscleTamagotchiGroup.core]);
  }

  void _simulateMeal() {
    const meal = LogParseResponse(calories: 650, protein: 45, fat: 18);
    _nutrition.add(meal);
    _tamagotchi.applyNutrition(meal.calories);
  }

  void _launchWizard() {
    context.read<RoutineWizardProvider>().reset();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WizardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const AppHeading('Admin Dashboard', size: AppHeadingSize.h2),
        actions: [
          PopupMenuButton<Flavor>(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMedium,
            ),
            onSelected: (flavor) {
              context.read<EnvironmentProvider>().setFlavor(flavor);
            },
            itemBuilder: (_) => [
              for (final flavor in Flavor.values)
                PopupMenuItem(value: flavor, child: Text(flavor.name)),
            ],
          ),
        ],
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
        return _buildDashboard(provider, menus);
      },
    );
  }

  Widget _buildDashboard(
    RoutineProvider provider,
    List<DailyMenu> menus,
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
        const SizedBox.shrink(),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Daily Totals'),
        const SizedBox(height: AppSpacing.md),
        DailyTotalsCard(state: _nutrition),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Muscle Map'),
        const SizedBox(height: AppSpacing.md),
        MuscleGroupVisualizer(
          tamagotchiState: _tamagotchi,
          bodyWidthFactor: _bodyWidthFactor,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'Simulate Workout (Core)',
                onPressed: _simulateCoreWorkout,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CustomButton(
                label: 'Simulate Meal (650 kcal)',
                onPressed: _simulateMeal,
              ),
            ),
          ],
        ),
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
        const SizedBox.shrink(),
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
