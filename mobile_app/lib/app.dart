import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/constants/api_constants.dart';
import 'core/data/daily_log_repository.dart';
import 'core/data/local_daily_log_repository.dart';
import 'core/data/local_profile_repository.dart';
import 'core/data/local_projection_repository.dart';
import 'core/data/nutrition_repository.dart';
import 'core/data/profile_repository.dart';
import 'core/data/projection_repository.dart';
import 'core/data/schedule_repository.dart';
import 'core/mocks/mock_daily_log_repository.dart';
import 'core/mocks/mock_nutrition_repository.dart';
import 'core/mocks/mock_profile_repository.dart';
import 'core/mocks/mock_projection_repository.dart';
import 'core/mocks/mock_schedule_repository.dart';
import 'core/services/ai_chat_service.dart';
import 'core/services/notification_service.dart';
import 'core/state/ai_chat_controller.dart';
import 'core/state/daily_log_controller.dart';
import 'core/state/notification_navigation_controller.dart';
import 'core/state/nutrition_controller.dart';
import 'core/state/projection_controller.dart';
import 'core/state/schedule_controller.dart';
import 'core/state/user_profile_controller.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/main_shell_page.dart';

class NutriApp extends StatefulWidget {
  const NutriApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<NutriApp> createState() => _NutriAppState();
}

class _NutriAppState extends State<NutriApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final NotificationNavigationController _notificationNav =
      NotificationNavigationController();

  late final DailyLogController _dailyLogController;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    configureLocalTimeZone();
    _dailyLogController = DailyLogController(
      repository: _dailyLogRepository(),
    );
    _notificationService = NotificationService(
      onTap: (_) => _notificationNav.requestDailyLog(),
    );
    _bootstrapNotifications();
  }

  DailyLogRepository _dailyLogRepository() => widget.config.useMockApi
      ? MockDailyLogRepository()
      : LocalDailyLogRepository();

  Future<void> _bootstrapNotifications() async {
    try {
      await _notificationService.initialize();
      if (widget.config.enableNotifications) {
        await _notificationService.scheduleDailyReminder();
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

    // Schedule events are mock-seeded for M13; persistence is a follow-up.
    final ScheduleRepository scheduleRepository = MockScheduleRepository();
    final scheduleController = ScheduleController(
      repository: scheduleRepository,
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

    // The AI assistant reaches the C# .NET API (and, through it, local
    // Ollama) over HTTP. See ApiConstants.baseUrl for the host/port rules.
    final aiChatController = AiChatController(
      service: AiChatService(baseUrl: ApiConstants.baseUrl),
    );

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'NutriExercise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MainShellPage(
        profileController: profileController,
        scheduleController: scheduleController,
        nutritionController: nutritionController,
        projectionController: projectionController,
        aiChatController: aiChatController,
        notificationNav: _notificationNav,
        dailyLogController: _dailyLogController,
      ),
    );
  }
}
