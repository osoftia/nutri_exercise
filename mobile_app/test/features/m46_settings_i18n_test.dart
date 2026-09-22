import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_settings_repository.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/settings_page.dart';

void main() {
  Widget wrap(AppLanguage language) => MaterialApp(
    theme: AppTheme.dark,
    home: LocalizationScope(
      language: language,
      child: SettingsPage(
        settingsRepository: MockSettingsRepository(),
        prefsRepository: MockNotificationPrefsRepository(),
      ),
    ),
  );

  group('M46 settings i18n sweep', () {
    testWidgets('renders English labels by default', (tester) async {
      await tester.pumpWidget(wrap(AppLanguage.english));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Saved Records'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Exercise alerts'), findsOneWidget);
      expect(find.text('Food alerts'), findsOneWidget);
      expect(find.text('Daily intake reminders'), findsOneWidget);
    });

    testWidgets('renders Spanish labels when the language is Spanish', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(AppLanguage.spanish));
      await tester.pumpAndSettle();

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Registros guardados'), findsOneWidget);
      expect(find.text('Preferencias de notificaciones'), findsOneWidget);
      expect(find.text('Alertas de ejercicio'), findsOneWidget);
      expect(find.text('Alertas de comida'), findsOneWidget);
      expect(find.text('Recordatorios de ingesta diaria'), findsOneWidget);
    });

    testWidgets('the delete dialog is localized in Spanish', (tester) async {
      await tester.pumpWidget(wrap(AppLanguage.spanish));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.text('Eliminar registro'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });
}
