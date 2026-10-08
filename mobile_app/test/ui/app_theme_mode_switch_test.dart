import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/app_theme_mode_repository.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/core/theme/app_theme_mode.dart';
import 'package:nutri_mobile_app/core/theme/apple_theme.dart';
import 'package:nutri_mobile_app/core/state/app_theme_mode_controller.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_container.dart';
import 'package:nutri_mobile_app/ui/molecules/settings_panel.dart';

class _MemoryThemeModeRepository implements AppThemeModeRepository {
  AppThemeMode mode = AppThemeMode.technicalBlueprint;

  @override
  Future<AppThemeMode> loadMode() async => mode;

  @override
  Future<void> saveMode(AppThemeMode value) async => mode = value;
}

void main() {
  testWidgets('switch updates global theme and key surfaces immediately', (
    tester,
  ) async {
    final repository = _MemoryThemeModeRepository();
    final controller = AppThemeModeController(repository: repository);
    await controller.load();
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.forMode(controller.mode),
          home: LocalizationScope(
            language: AppLanguage.english,
            child: Scaffold(
              body: ListView(
                children: [
                  SettingsPanel(themeModeController: controller),
                  const NeumorphicContainer(
                    key: Key('theme_probe_card'),
                    child: Text('Theme probe'),
                  ),
                  Builder(
                    builder: (context) => Text(
                      Theme.of(context).brightness.name,
                      key: const Key('theme_brightness_probe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('dark'), findsOneWidget);
    final technicalCard = tester.widget<NeumorphicContainer>(
      find.byKey(const Key('theme_probe_card')),
    );
    expect(technicalCard, isNotNull);
    final technicalSurface = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('theme_probe_card')),
            matching: find.byType(Container),
          )
          .first,
    );
    final technicalDecoration = technicalSurface.decoration! as BoxDecoration;
    expect(technicalDecoration.boxShadow, hasLength(2));

    await tester.tap(find.byKey(const Key('settings_theme_apple_toggle')));
    await tester.pumpAndSettle();

    expect(controller.mode, AppThemeMode.appleMinimalist);
    expect(repository.mode, AppThemeMode.appleMinimalist);
    expect(find.text('light'), findsOneWidget);
    final appleTheme = AppTheme.forMode(controller.mode);
    expect(appleTheme.cardTheme.color, isNot(AppTheme.dark.cardTheme.color));
    final appleSurface = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('theme_probe_card')),
            matching: find.byType(Container),
          )
          .first,
    );
    final appleDecoration = appleSurface.decoration! as BoxDecoration;
    expect(appleDecoration.color, AppleTheme.surface);
    expect(appleDecoration.border, isNotNull);
    expect(appleDecoration.borderRadius, AppleTheme.cardBorderRadius);
  });
}
