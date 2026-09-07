import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  runApp(
    NutriApp(
      config: const AppConfig(
        name: 'local',
        useMocks: false,
        useLocalDatabase: true,
      ),
    ),
  );
}
