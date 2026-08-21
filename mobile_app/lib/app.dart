import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/data/local_profile_repository.dart';
import 'core/data/profile_repository.dart';
import 'core/mocks/mock_profile_repository.dart';
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

    return MaterialApp(
      title: 'NutriExercise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MainShellPage(profileController: profileController),
    );
  }
}