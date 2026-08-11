import 'package:flutter/material.dart';

import '../../core/constants/muscle_vectors.dart';
import '../../core/data/diet_repository.dart';
import '../../core/data/routine_repository.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/routine_models.dart';
import '../../core/services/ai_interceptor.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/generated_routine_dialog.dart';
import '../molecules/offline_ai_dialog.dart';
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
  final AiService _aiService = AiService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _routines = widget.routineRepository.getWeeklyRoutine();
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
      setState(_load);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomButton(label: 'Ask AI', onPressed: _askAi),
            const SizedBox(width: AppSpacing.md),
            CustomButton(
              label: 'Refresh',
              variant: CustomButtonVariant.ghost,
              onPressed: () => setState(_load),
            ),
          ],
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
        RoutineList(
          routines: routines,
          onRoutineTap: _scheduleRoutineNotification,
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
