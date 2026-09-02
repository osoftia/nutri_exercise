import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/constants/api_constants.dart';
import 'core/data/local_profile_repository.dart';
import 'core/data/local_projection_repository.dart';
import 'core/data/nutrition_repository.dart';
import 'core/data/profile_repository.dart';
import 'core/data/projection_repository.dart';
import 'core/data/schedule_repository.dart';
import 'core/mocks/mock_nutrition_repository.dart';
import 'core/mocks/mock_profile_repository.dart';
import 'core/mocks/mock_projection_repository.dart';
import 'core/mocks/mock_schedule_repository.dart';
import 'core/services/ai_chat_service.dart';
import 'core/state/ai_chat_controller.dart';
import 'core/state/nutrition_controller.dart';
import 'core/state/projection_controller.dart';
import 'core/state/schedule_controller.dart';
import 'core/state/user_profile_controller.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/main_shell_page.dart';

class NutriApp extends StatelessWidget {
  const NutriApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final ProfileRepository profileRepository = config.useMocks
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
    final ProjectionRepository projectionRepository = config.useMocks
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
      title: 'NutriExercise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MainShellPage(
        profileController: profileController,
        scheduleController: scheduleController,
        nutritionController: nutritionController,
        projectionController: projectionController,
        aiChatController: aiChatController,
      ),
    );
  }
}