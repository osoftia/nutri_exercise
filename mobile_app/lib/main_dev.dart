import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  runApp(const NutriApp(config: AppConfig(name: 'dev', useMocks: true)));
}
