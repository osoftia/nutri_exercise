import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/environment_config.dart';
import '../../core/constants/muscle_group_map.dart';
import '../../core/constants/tamagotchi_groups.dart';
import '../../core/data/daily_entry_repository.dart';
import '../../core/data/daily_log_repository.dart';
import '../../core/data/diet_repository.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/daily_entry.dart';
import '../../core/models/log_parse_response.dart';
import '../../core/models/user_profile.dart';
import '../../core/state/body_proportions.dart';
import '../../core/state/daily_log_controller.dart';
import '../../core/state/daily_nutrition_state.dart';
import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/providers/environment_provider.dart';
import '../../core/providers/routine_provider.dart';
import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/share_progress_controller.dart';
import '../../core/utils/exercise_muscle_mapper.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/daily_log_sheet.dart';
import '../molecules/daily_totals_card.dart';
import '../molecules/exercise_card.dart';
import '../organisms/bottom_nav_bar.dart';
import '../organisms/calendar_history_dialog.dart';
import '../organisms/muscle_group_visualizer.dart';
import '../organisms/social_share_card.dart';
import 'wizard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dietRepository,
    required this.routineRepository,
    this.profile,
    this.dailyEntryRepository,
    this.dailyLogRepository,
    this.dailyLogController,
    this.shareController,
    this.tamagotchiState,
  });

  final DietRepository dietRepository;
  final RoutineRepository routineRepository;

  /// The user's profile; drives the avatar's baseline width via BMI.
  final UserProfile? profile;

  /// Optional SQLite-backed history; enables the AppBar History action.
  final DailyEntryRepository? dailyEntryRepository;

  /// Optional streak source for the share card.
  final DailyLogRepository? dailyLogRepository;

  /// Optional daily check-in controller; enables the "Daily Log" section.
  final DailyLogController? dailyLogController;

  /// Optional share orchestrator (injectable for tests).
  final ShareProgressController? shareController;

  /// M36 Task 1: single source of truth. When null, [HomePage] watches the
  /// global [sharedMuscleTamagotchiState] so every mount paints/mutates the
  /// exact same instance instead of forking a per-widget duplicate. Tests
  /// may inject their own instance for isolation.
  final MuscleTamagotchiState? tamagotchiState;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<DailyMenu>> _menus;
  // M36 Task 1: no per-widget duplicate — resolved via [tamagotchi] getter.
  final DailyNutritionState _nutrition = DailyNutritionState();
  final GlobalKey _shareCardKey = GlobalKey();
  late final ShareProgressController _shareController;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _menus = widget.dietRepository.getDailyMenus();
    _shareController = widget.shareController ?? ShareProgressController();
    _loadStreak();
  }

  /// Reloads the share-card streak from the log repository.
  ///
  /// M36 Task 2: also fired via the calendar history `onChanged` hook so a
  /// day deleted (or saved) in the calendar instantly updates the
  /// Tamagotchi/stats state instead of leaving a stale count.
  void _loadStreak() {
    widget.dailyLogRepository?.currentStreak().then((streak) {
      if (mounted) setState(() => _streak = streak);
    });
  }

  /// Opens the calendar history; any save/delete inside refreshes the streak.
  void _openHistory() {
    final repository = widget.dailyEntryRepository;
    if (repository == null) return;
    showCalendarHistoryDialog(
      context,
      repository: repository,
      onChanged: _loadStreak,
    );
  }

  @override
  void dispose() {
    // M36 Task 1: the tamagotchi instance is shared/injected, never owned
    // here — disposing it would kill the global singleton for the next mount.
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

  /// M36 Task 1: the single watched instance. Injected state wins (tests),
  /// otherwise the global [sharedMuscleTamagotchiState]. Every handler and
  /// every painted subtree below must go through this getter — never a
  /// second `MuscleTamagotchiState()` or dummy/mock.
  MuscleTamagotchiState get tamagotchi =>
      widget.tamagotchiState ?? sharedMuscleTamagotchiState;

  void _simulateCoreWorkout() {
    tamagotchi.applyGrowth([MuscleTamagotchiGroup.core]);
  }

  void _simulateMeal() {
    const meal = LogParseResponse(calories: 650, protein: 45, fat: 18);
    _nutrition.add(meal);
    tamagotchi.applyMeal(meal);
  }

  /// Logs a default quick meal into the nutrition totals and applies the
  /// tamagotchi food-quality effect (healthy → muscle, unhealthy → bloat).
  /// Used by the "Quick Add" button. Also persists today's entry to SQLite so
  /// the calendar reflects it instantly.
  void _quickAdd() {
    const meal = LogParseResponse(calories: 650, protein: 45, fat: 18);
    _nutrition.add(meal);
    tamagotchi.applyMeal(meal);
    _persistTodayEntry(
      (entry) => entry.copyWith(
        calories: entry.calories + meal.calories,
        healthyMeals: entry.healthyMeals + (meal.isHealthy ? 1 : 0),
      ),
    );
  }

  /// Upserts today's entry in the history repository (when available),
  /// applying [update] to the existing value.
  Future<void> _persistTodayEntry(
    DailyEntry Function(DailyEntry current) update,
  ) async {
    final repository = widget.dailyEntryRepository;
    if (repository == null) return;
    final today = DailyEntry.dateKey(DateTime.now());
    final existing = await repository.getByDate(today);
    await repository.save(update(existing ?? DailyEntry(date: today)));
  }

  void _launchWizard() {
    context.read<RoutineWizardProvider>().reset();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WizardPage()),
    );
  }

  /// Opens the quick daily check-in logging sheet. After it closes, the logged
  /// summary (or its parsed calories) is mirrored into today's SQLite entry so
  /// the calendar reflects it instantly.
  Future<void> _openDailyLog() async {
    final controller = widget.dailyLogController;
    if (controller == null) return;
    await showDailyLogSheet(context, controller);
    await _persistTodayEntry(
      (entry) => entry.copyWith(
        calories: controller.parseResult?.calories ?? entry.calories,
      ),
    );
  }

  void _navigateToProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing is available on the Profile tab.')),
    );
  }

  /// Captures the hidden [SocialShareCard] and opens the native share sheet.
  Future<void> _shareProgress() async {
    try {
      await _shareController.shareCard(
        _shareCardKey,
        text: '🔥 $_streak días de racha en NutriExercise',
      );
    } catch (_) {
      // Sharing is non-critical; never crash the dashboard.
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const AppHeading('Admin Dashboard', size: AppHeadingSize.h2),
        actions: [
          IconButton(
            key: const Key('share_progress_button'),
            icon: const Icon(
              Icons.ios_share,
              color: AppColors.textMedium,
            ),
            tooltip: 'Share Progress',
            onPressed: _shareProgress,
          ),
          if (widget.dailyEntryRepository != null)
            IconButton(
              key: const Key('history_action'),
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textMedium,
              ),
              tooltip: 'History',
              onPressed: _openHistory,
            ),
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
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(provider)),
          _buildHiddenShareCard(),
        ],
      ),
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

  /// The hidden [SocialShareCard] used for image capture. Painted at full
  /// opacity behind an [Opacity] layer so its RepaintBoundary rasterizes
  /// cleanly while staying invisible to the user.
  Widget _buildHiddenShareCard() {
    return Positioned(
      top: 0,
      left: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: SizedBox(
            width: SocialShareCard.width,
            height: SocialShareCard.height,
            child: SocialShareCard(
              repaintKey: _shareCardKey,
              tamagotchiState: tamagotchi,
              streak: _streak,
            ),
          ),
        ),
      ),
    );
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
        if (widget.dailyLogController != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppHeading('Daily Log', size: AppHeadingSize.h2),
              IconButton(
                key: const Key('daily_log_action'),
                icon: const Icon(
                  Icons.edit_note,
                  color: AppColors.primary400,
                ),
                tooltip: 'Quick log today',
                onPressed: _openDailyLog,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Daily Totals'),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DailyTotalsCard(state: _nutrition),
            ),
            const SizedBox(width: AppSpacing.md),
            _ProfileInfoCard(
              profile: widget.profile,
              onEdit: _navigateToProfile,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Muscle Map'),
        const SizedBox(height: AppSpacing.md),
        // M34 Task 1: explicit avatar rebuild trigger. Every tamagotchi
        // mutation (log exercise, 9 PM "Yes" slimming, quick-add meal)
        // calls notifyListeners(); this ListenableBuilder forces the
        // avatar subtree to rebuild with the latest state instead of
        // relying solely on InteractiveBodyMap's internal listener.
        ListenableBuilder(
          listenable: tamagotchi,
          builder: (context, _) {
            return MuscleGroupVisualizer(
              tamagotchiState: tamagotchi,
              bodyWidthFactor: _bodyWidthFactor,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                key: const Key('quick_add_button'),
                label: 'Quick Add',
                onPressed: _quickAdd,
              ),
            ),
          ],
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
              isLogged: provider.isExerciseLogged(exercise.name),
              onLog: () {
                provider.toggleExerciseLog(exercise.name);
                if (provider.isExerciseLogged(exercise.name)) {
                  final regionId =
                      muscleGroupToRegion[exercise.muscleGroup];
                  final group = regionId == null
                      ? null
                      : tamagotchiGroupForRegion(regionId);
                  if (group != null) {
                    tamagotchi.applyGrowth([group]);
                  }
                  tamagotchi.applySlimming();
                }
              },
              onTap: () {
                final regionId =
                    muscleGroupToRegion[exercise.muscleGroup];
                if (regionId != null) {
                  provider.selectMuscleRegion(regionId);
                }
                tamagotchi.setOverrides(
                  ExerciseMuscleMapper.getColorsForExercise(exercise.name),
                );
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

/// Compact profile summary shown beside the avatar: weight/height with an edit
/// (pencil) icon. Falls back to the 60 kg / 1.70 m defaults when no profile has
/// been saved.
class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.profile, required this.onEdit});

  final UserProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final weight = profile?.weightKg ?? 60;
    final height = profile?.heightCm ?? 170;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('profile_edit_icon'),
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${weight.toStringAsFixed(0)} kg'),
          Text('${height.toStringAsFixed(0)} cm'),
        ],
      ),
    );
  }
}
