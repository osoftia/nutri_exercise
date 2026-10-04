import 'dart:async';

import 'package:flutter/material.dart';

import 'core/config/ai_chat_factory.dart';
import 'core/config/app_config.dart';
import 'core/constants/api_constants.dart';
import 'core/data/body_detail_repository.dart';
import 'core/data/clinical_profile_repository.dart';
import 'core/data/clinical_profile_repository.dart';
import 'core/data/daily_entry_repository.dart';
import 'core/data/daily_log_repository.dart';
import 'core/data/local_body_detail_repository.dart';
import 'core/data/local_clinical_profile_repository.dart';
import 'core/data/local_clinical_profile_repository.dart';
import 'core/data/local_daily_entry_repository.dart';
import 'core/data/local_daily_log_repository.dart';
import 'core/data/local_profile_repository.dart';
import 'core/data/local_language_repository.dart';
import 'core/data/local_notification_prefs_repository.dart';
import 'core/data/local_projection_repository.dart';
import 'core/data/local_symptom_repository.dart';
import 'core/data/local_tamagotchi_progress_repository.dart';
import 'core/data/nutrition_repository.dart';
import 'core/data/notification_prefs_repository.dart';
import 'core/data/profile_repository.dart';
import 'core/data/projection_repository.dart';
import 'core/data/language_repository.dart';
import 'core/data/schedule_repository.dart';
import 'core/data/symptom_repository.dart';
import 'core/domain/i18n/localization_scope.dart';
import 'core/mocks/mock_daily_entry_repository.dart';
import 'core/mocks/mock_language_repository.dart';
import 'core/mocks/mock_daily_log_repository.dart';
import 'core/mocks/mock_body_detail_repository.dart';
import 'core/mocks/mock_clinical_profile_repository.dart';
import 'core/mocks/mock_clinical_profile_repository.dart';
import 'core/mocks/mock_nutrition_repository.dart';
import 'core/mocks/mock_notification_prefs_repository.dart';
import 'core/mocks/mock_profile_repository.dart';
import 'core/mocks/mock_projection_repository.dart';
import 'core/mocks/mock_schedule_repository.dart';
import 'core/mocks/mock_symptom_repository.dart';
import 'core/services/log_parse_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/rule_based_body_projection_forecaster.dart';
import 'core/services/rule_based_muscle_gap_advisor.dart';
import 'core/services/smart_logger.dart';
import 'core/state/body_detail_controller.dart';
import 'core/state/clinical_profile_controller.dart';
import 'core/state/clinical_profile_controller.dart';
import 'core/state/daily_log_controller.dart';
import 'core/state/language_controller.dart';
import 'core/state/notification_navigation_controller.dart';
import 'core/state/nutrition_controller.dart';
import 'core/state/projection_controller.dart';
import 'core/state/schedule_controller.dart';
import 'core/state/symptom_controller.dart';
import 'core/state/user_profile_controller.dart';
import 'core/state/workout_completion_controller.dart';
import 'core/state/muscle_tamagotchi_state.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/main_shell_page.dart';

class NutriApp extends StatefulWidget {
  const NutriApp({
    super.key,
    required this.config,
    this.notificationService,
  });

  final AppConfig config;

  /// A pre-initialized notification service (e.g. created in `main` so OS
  /// permissions are requested before the UI runs). When `null`, the app
  /// creates and initializes its own.
  final NotificationService? notificationService;

  @override
  State<NutriApp> createState() => _NutriAppState();
}

class _NutriAppState extends State<NutriApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final NotificationNavigationController _notificationNav =
      NotificationNavigationController();

  late final DailyLogController _dailyLogController;
  late final NotificationService _notificationService;
  late final LanguageController _languageController;

  @override
  void initState() {
    super.initState();
    configureLocalTimeZone();

    // Restore the persisted language before the first frame so the app opens in
    // the user's chosen language (falling back to English).
    final LanguageRepository languageRepository = widget.config.useMockApi
        ? MockLanguageRepository()
        : LocalLanguageRepository();
    _languageController = LanguageController(repository: languageRepository);
    unawaited(_languageController.restore());
    final dailyLogRepository = _dailyLogRepository();
    _dailyLogController = DailyLogController(
      repository: dailyLogRepository,
      smartLogger: SmartLogger(
        repository: dailyLogRepository,
        parseService: LogParseService(baseUrl: ApiConstants.baseUrl),
      ),
    );
    _notificationService = widget.notificationService ?? NotificationService();
    _notificationService.setOnResponse((actionId, payload) {
      if (actionId == NotificationService.exerciseYesActionId) {
        _notificationNav.requestExerciseCompletion(payload: payload);
      } else if (actionId == NotificationService.symptomCheckInActionId) {
        _notificationNav.requestSymptoms();
      } else {
        _notificationNav.requestDailyLog();
      }
    });
    _notificationService.setDailyLogRepository(_dailyLogRepository());
    _bootstrapNotifications();

    // Rehydrate the shared Tamagotchi (muscle mass + core fullness) from
    // SQLite so the blueprint avatar survives app restarts. Dev/mock flavors
    // stay in-memory for test isolation.
    final tamagotchiRepository =
        widget.config.useMockApi ? null : LocalTamagotchiProgressRepository();
    sharedMuscleTamagotchiState.attachRepository(tamagotchiRepository);
    if (tamagotchiRepository != null) {
      unawaited(sharedMuscleTamagotchiState.restore());
    }
  }

  DailyLogRepository _dailyLogRepository() => widget.config.useMockApi
      ? MockDailyLogRepository()
      : LocalDailyLogRepository();

  DailyEntryRepository? _dailyEntryRepositoryInstance;

  /// Returns the single shared calendar/weekly-summary repository.
  ///
  /// Cached so the calendar view, the Weekly Stats view and the workout
  /// confirmation all read and write the *same* store (in dev/mock flavors a
  /// per-call instance would otherwise leave the calendar empty).
  DailyEntryRepository _dailyEntryRepository() =>
      _dailyEntryRepositoryInstance ??= (widget.config.useMockApi
          ? MockDailyEntryRepository()
          : LocalDailyEntryRepository());

  SymptomRepository? _symptomRepositoryInstance;

  /// Returns the single shared symptom repository (SQLite in real flavors,
  /// in-memory in dev/mock flavors).
  SymptomRepository _symptomRepository() =>
      _symptomRepositoryInstance ??= (widget.config.useMockApi
          ? MockSymptomRepository()
          : LocalSymptomRepository());

  NotificationPrefsRepository? _notificationPrefsRepositoryInstance;

  /// Returns the single shared notification-preferences repository.
  NotificationPrefsRepository _notificationPrefsRepository() =>
      _notificationPrefsRepositoryInstance ??= (widget.config.useMockApi
          ? MockNotificationPrefsRepository()
          : LocalNotificationPrefsRepository());

  Future<void> _bootstrapNotifications() async {
    try {
      await _notificationService.initialize();
      if (widget.config.enableNotifications) {
        await _notificationService.scheduleDailyReminder();
        await _notificationService.scheduleDailyMealReminders();
        await _notificationService.scheduleDailyExerciseReminder();
        await _notificationService.scheduleNightlyCheckIn(
          symptomRepository: _symptomRepository(),
          entryRepository: _dailyEntryRepository(),
        );
      }
      final launch = await _notificationService.launchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        _notificationNav.requestDailyLog();
      }
    } catch (_) {
      // Notifications are non-critical: never crash startup when the platform
      // channel is unavailable (e.g. in tests without a registered plugin).
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProfileRepository profileRepository = widget.config.useMockApi
        ? MockProfileRepository()
        : LocalProfileRepository();
    final profileController = UserProfileController(
      repository: profileRepository,
    );
    final ClinicalProfileRepository clinicalProfileRepository =
        widget.config.useMockApi
            ? MockClinicalProfileRepository()
            : LocalClinicalProfileRepository();
    final clinicalProfileController = ClinicalProfileController(
      repository: clinicalProfileRepository,
    );
    final ClinicalProfileRepository clinicalProfileRepository =
        widget.config.useMockApi
            ? MockClinicalProfileRepository()
            : LocalClinicalProfileRepository();
    final clinicalProfileController = ClinicalProfileController(
      repository: clinicalProfileRepository,
    );

    // Schedule events are mock-seeded for M13; persistence is a follow-up.
    final ScheduleRepository scheduleRepository = MockScheduleRepository();
    final scheduleController = ScheduleController(
      repository: scheduleRepository,
    );

    // Daily symptom severities are SQLite-backed (in-memory in dev/mock).
    final symptomController = SymptomController(
      repository: _symptomRepository(),
    );

    // Nutrition is mock-seeded for M14; SQLite persistence is a follow-up.
    final NutritionRepository nutritionRepository = MockNutritionRepository();
    final nutritionController = NutritionController(
      repository: nutritionRepository,
    );

    // Long-term body projection plan is SQLite-backed (or mock-seeded in tests).
    final ProjectionRepository projectionRepository = widget.config.useMockApi
        ? MockProjectionRepository()
        : LocalProjectionRepository();
    final projectionController = ProjectionController(
      repository: projectionRepository,
    );

    // Blueprint detail data: SQLite-backed in real flavors, mock-seeded in dev.
    final BodyDetailRepository bodyDetailRepository = widget.config.useMockApi
        ? MockBodyDetailRepository()
        : LocalBodyDetailRepository();
    final bodyDetailController = BodyDetailController(
      repository: bodyDetailRepository,
      advisor: const RuleBasedMuscleGapAdvisor(),
      forecaster: const RuleBasedBodyProjectionForecaster(),
      tamagotchi: sharedMuscleTamagotchiState,
    );

    // Confirms workouts, persists the completions and mutates the shared
    // Tamagotchi so the avatar reflects the recovery immediately. It also
    // upserts today's calendar entry so the Weekly Stats and calendar markers
    // reflect the workout.
    final dailyEntryRepository = _dailyEntryRepository();
    final workoutCompletionController = WorkoutCompletionController(
      tamagotchi: sharedMuscleTamagotchiState,
      repository: bodyDetailRepository,
      dailyEntries: dailyEntryRepository,
    );

    // The AI assistant reaches the C# .NET API (and, through it, the RAG
    // engine + local Ollama) over HTTP. Flavors with `enableAI == false`
    // return null so no chat entry point is built.
    final aiChatController = buildAiChatController(widget.config);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'NutriExercise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: ListenableBuilder(
        listenable: _languageController,
        builder: (context, _) => LocalizationScope(
          language: _languageController.language,
          child: MainShellPage(
            profileController: profileController,
            clinicalProfileController: clinicalProfileController,
            clinicalProfileController: clinicalProfileController,
            scheduleController: scheduleController,
            symptomController: symptomController,
            nutritionController: nutritionController,
            projectionController: projectionController,
            bodyDetailController: bodyDetailController,
            workoutCompletionController: workoutCompletionController,
            aiChatController: aiChatController,
            notificationNav: _notificationNav,
            dailyLogController: _dailyLogController,
            dailyEntryRepository: dailyEntryRepository,
            notificationService: _notificationService,
            languageController: _languageController,
            notificationPrefsRepository: _notificationPrefsRepository(),
            syncExerciseReminderPayload: widget.config.enableNotifications,
          ),
        ),
      ),
    );
  }
}
