import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/main_shell_page.dart';

class NutriApp extends StatelessWidget {
  const NutriApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriExercise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShellPage(),
    );
  }
}