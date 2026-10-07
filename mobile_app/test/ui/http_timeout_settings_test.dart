import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/http_timeout_settings_repository.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/services/http_timeout_configuration.dart';
import 'package:nutri_mobile_app/core/state/http_timeout_settings_controller.dart';
import 'package:nutri_mobile_app/ui/molecules/settings_panel.dart';

class _MemoryTimeoutRepository implements HttpTimeoutSettingsRepository {
  int seconds = HttpTimeoutConfiguration.defaultSeconds;

  @override
  Future<int> loadTimeoutSeconds() async => seconds;

  @override
  Future<void> saveTimeoutSeconds(int value) async => seconds = value;
}

void main() {
  testWidgets('settings slider changes and persists the request timeout', (
    tester,
  ) async {
    HttpTimeoutConfiguration.reset();
    final repository = _MemoryTimeoutRepository();
    final controller = HttpTimeoutSettingsController(repository: repository);
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: LocalizationScope(
          language: AppLanguage.spanish,
          child: Scaffold(
            body: SettingsPanel(timeoutSettingsController: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tiempo de espera de conexión: 60 s'), findsOneWidget);
    final slider = tester.widget<Slider>(
      find.byKey(const Key('settings_request_timeout_slider')),
    );
    slider.onChanged!(35);
    await tester.pump();
    tester
        .widget<Slider>(
          find.byKey(const Key('settings_request_timeout_slider')),
        )
        .onChangeEnd!(35);
    await tester.pumpAndSettle();

    expect(controller.timeoutSeconds, 35);
    expect(HttpTimeoutConfiguration.currentTimeout.inSeconds, 35);
    expect(repository.seconds, 35);
    expect(find.text('Tiempo de espera de conexión: 35 s'), findsOneWidget);
  });
}
