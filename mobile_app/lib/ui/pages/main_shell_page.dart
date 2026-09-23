import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/data/notification_prefs_repository.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/domain/notifications/exercise_check_in.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/ai_chat_controller.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/state/daily_log_controller.dart';
import '../../core/state/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/notification_navigation_controller.dart';
import '../../core/state/nutrition_controller.dart';
import '../../core/state/projection_controller.dart';
import '../../core/state/schedule_controller.dart';
import '../../core/state/symptom_controller.dart';
import '../../core/state/user_profile_controller.dart';
import '../../core/state/workout_completion_controller.dart';
import '../atoms/neumorphic_fab.dart';
import '../atoms/typography.dart';
import '../molecules/ai_chat_sheet.dart';
import '../molecules/daily_log_sheet.dart';
import '../molecules/exercise_completion_sheet.dart';
import '../organisms/bottom_nav_bar.dart';
import '../organisms/calendar_history_dialog.dart';
import '../organisms/weekly_stats_sheet.dart';
import 'nutrition_page.dart';
import 'profile_page.dart';
import 'routines_page.dart';
import 'schedule_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.profileController,
    required this.scheduleController,
    required this.nutritionController,
    required this.projectionController,
    required this.bodyDetailController,
    required this.aiChatController,
    required this.notificationNav,
    required this.dailyLogController,
    this.workoutCompletionController,
    this.dailyEntryRepository,
    this.notificationService,
    this.languageController,
    this.symptomController,
    this.notificationPrefsRepository,
    this.syncExerciseReminderPayload = false,
  });

  final UserProfileController profileController;
  final ScheduleController scheduleController;
  final NutritionController nutritionController;
  final ProjectionController projectionController;
  final BodyDetailController bodyDetailController;
  final AiChatController? aiChatController;
  final NotificationNavigationController notificationNav;
  final DailyLogController dailyLogController;
  final WorkoutCompletionController? workoutCompletionController;
  final DailyEntryRepository? dailyEntryRepository;
  final NotificationService? notificationService;

  /// Optional language controller; enables the Profile language switcher.
  final LanguageController? languageController;

  /// Optional symptom controller; enables the daily symptom tracker.
  final SymptomController? symptomController;

  /// Optional prefs store; enables the Profile Settings accordion.
  final NotificationPrefsRepository? notificationPrefsRepository;

  /// When true, the 9 PM reminder is rescheduled with the planned-exercise
  /// payload once the blueprint overview has loaded.
  final bool syncExerciseReminderPayload;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    RoutinesPage(
      controller: widget.projectionController,
      detailController: widget.bodyDetailController,
      workoutCompletionController: widget.workoutCompletionController,
      dailyEntryRepository: widget.dailyEntryRepository,
    ),
    NutritionPage(
      controller: widget.nutritionController,
      dailyEntryRepository: widget.dailyEntryRepository,
      notificationService: widget.notificationService,
      bodyDetailController: widget.bodyDetailController,
    ),
    SchedulePage(
      controller: widget.scheduleController,
      symptomController: widget.symptomController,
    ),
    ProfilePage(
      controller: widget.profileController,
      languageController: widget.languageController,
      symptomController: widget.symptomController,
      notificationPrefsRepository: widget.notificationPrefsRepository,
      notificationService: widget.notificationService,
      dailyEntryRepository: widget.dailyEntryRepository,
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.notificationNav.addListener(_onNotificationAction);
    if (widget.syncExerciseReminderPayload) {
      widget.bodyDetailController.addListener(_syncExerciseReminder);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingAction());
  }

  @override
  void dispose() {
    widget.notificationNav.removeListener(_onNotificationAction);
    widget.bodyDetailController.removeListener(_syncExerciseReminder);
    super.dispose();
  }

  void _onNotificationAction() {
    final action = widget.notificationNav.pending;
    if (action == NotificationAction.openDailyLog) {
      widget.notificationNav.consume();
      showDailyLogSheet(context, widget.dailyLogController);
    } else if (action == NotificationAction.exerciseCompleted) {
      final payload = widget.notificationNav.exercisePayload;
      widget.notificationNav.consume();
      _confirmWorkout(payload: payload);
    } else if (action == NotificationAction.openSymptoms) {
      widget.notificationNav.consume();
      setState(() => _currentIndex = 2);
    }
  }

  void _handlePendingAction() {
    final action = widget.notificationNav.pending;
    if (action == NotificationAction.openDailyLog ||
        action == NotificationAction.exerciseCompleted ||
        action == NotificationAction.openSymptoms) {
      _onNotificationAction();
    }
  }

  bool _exerciseReminderSynced = false;

  /// Reschedules the 9 PM reminder with the planned-exercise payload once the
  /// blueprint overview has loaded, giving the notification full parity with
  /// the manual check-in.
  void _syncExerciseReminder() {
    if (_exerciseReminderSynced) return;
    final service = widget.notificationService;
    if (service == null || widget.bodyDetailController.workouts.isEmpty) return;

    _exerciseReminderSynced = true;
    // Notifications are non-critical: rescheduling must never crash the UI
    // (e.g. when the platform channel is unavailable under test).
    service
        .scheduleDailyExerciseReminder(
          payload: widget.bodyDetailController.exerciseCheckInPayload(),
        )
        .catchError((Object _) {});
  }

  /// Confirms the workout and opens the post-workout summary popup.
  ///
  /// A structured [payload] from the notification is confirmed directly; when
  /// absent, already-persisted records are presented, or the planned workout is
  /// confirmed as a manual check-in fallback.
  Future<void> _confirmWorkout({String? payload}) async {
    final completion = widget.workoutCompletionController;
    if (completion == null) return;

    final checkIn = ExerciseCheckIn.tryParse(payload);
    if (checkIn != null && !checkIn.isEmpty) {
      await completion.confirm(checkIn.exercises);
    } else {
      final persisted = await widget.bodyDetailController.completedExercises();
      if (persisted.isEmpty) {
        await completion
            .confirm(widget.bodyDetailController.plannedExercises());
      } else {
        completion.present(persisted);
      }
    }

    final summary = completion.summary;
    if (!mounted || summary == null) return;
    await showExerciseCompletionSheet(context, summary);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: AppHeading(strings.appTitle, size: AppHeadingSize.h3),
        actions: [
          if (widget.dailyEntryRepository != null) ...[
            IconButton(
              key: const Key('weekly_stats_action'),
              icon: const Icon(
                Icons.bar_chart_outlined,
                color: AppColors.textMedium,
              ),
              tooltip: strings.weeklyStats,
              onPressed: () => showWeeklyStatsSheet(
                context,
                repository: widget.dailyEntryRepository!,
              ),
            ),
            IconButton(
              key: const Key('history_action'),
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textMedium,
              ),
              tooltip: strings.history,
              onPressed: () => showCalendarHistoryDialog(
                context,
                repository: widget.dailyEntryRepository!,
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(child: _tabs[_currentIndex]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            key: const Key('daily_log_fab'),
            onPressed: () =>
                showDailyLogSheet(context, widget.dailyLogController),
            backgroundColor: AppColors.primary500,
            foregroundColor: AppColors.textHigh,
            icon: const Icon(Icons.edit_note),
            label: Text(strings.dailyLogFabLabel),
            tooltip: strings.dailyLogFabLabel,
          ),
          if (widget.aiChatController != null) ...[
            const SizedBox(height: AppSpacing.md),
            NeumorphicFab(
              onPressed: () =>
                  showAiChatSheet(context, widget.aiChatController!),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
