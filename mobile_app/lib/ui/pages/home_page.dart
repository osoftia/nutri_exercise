import 'package:flutter/material.dart';

import '../../core/constants/muscle_vectors.dart';
import '../../core/data/diet_repository.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/routine_models.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/stat_card.dart';
import '../organisms/bottom_nav_bar.dart';
import '../organisms/interactive_body_map.dart';
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
  late Future<List<WorkoutDay>> _routines;
  late Future<List<DailyMenu>> _menus;
  String? _selectedMuscle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _routines = widget.routineRepository.getWeeklyRoutine();
    _menus = widget.dietRepository.getDailyMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppHeading('Admin Dashboard', size: AppHeadingSize.h2),
      ),
      body: FutureBuilder<List<WorkoutDay>>(
        future: _routines,
        builder: (context, routinesSnapshot) {
          return FutureBuilder<List<DailyMenu>>(
            future: _menus,
            builder: (context, menusSnapshot) {
              if (!routinesSnapshot.hasData || !menusSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildContent(routinesSnapshot.data!, menusSnapshot.data!);
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildContent(List<WorkoutDay> routines, List<DailyMenu> menus) {
    final totalMeals = menus.fold<int>(
      0,
      (sum, menu) => sum + menu.meals.length,
    );
    final totalCalories = menus.fold<int>(
      0,
      (sum, menu) => sum + menu.totalCalories,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton(
            label: 'Refresh',
            variant: CustomButtonVariant.ghost,
            onPressed: () => setState(_load),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Active Routines',
                value: '${routines.length}',
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
        InteractiveBodyMap(
          selectedMuscle: _selectedMuscle,
          onMuscleSelected: (id) => setState(() => _selectedMuscle = id),
        ),
        const SizedBox(height: AppSpacing.md),
        AppText(
          _selectedMuscle == null
              ? 'Tap a muscle group to highlight it'
              : 'Selected: ${muscleLabel(_selectedMuscle!)}',
        ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Weekly Routines'),
        const SizedBox(height: AppSpacing.md),
        RoutineList(routines: routines),
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
