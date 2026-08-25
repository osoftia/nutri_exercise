import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';

void main() {
  testWidgets('NutriApp dev config uses mocks and applies theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const NutriApp(config: AppConfig(name: 'dev', useMocks: true)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF0F172A));
  });
}
