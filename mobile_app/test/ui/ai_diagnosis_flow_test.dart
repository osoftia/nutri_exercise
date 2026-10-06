import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/data/ai_diagnosis_repository.dart';
import 'package:nutri_mobile_app/core/data/ai_diagnosis_store.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition_profile.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/mocks/mock_clinical_profile_repository.dart';
import 'package:nutri_mobile_app/core/models/ai_diagnosis.dart';
import 'package:nutri_mobile_app/core/state/clinical_profile_controller.dart';
import 'package:nutri_mobile_app/ui/molecules/clinical_conditions_panel.dart';

class _MemoryStore implements AiDiagnosisStore {
  AiDiagnosisReport? report;
  String preferences = '';

  @override
  Future<List<AiDiagnosisReport>> all() async =>
      report == null ? [] : [report!];

  @override
  Future<AiDiagnosisReport?> latest() async => report;

  @override
  Future<String> loadFoodPreferences() async => preferences;

  @override
  Future<void> save(AiDiagnosisReport value) async => report = value;

  @override
  Future<void> saveFoodPreferences(String value) async => preferences = value;
}

void main() {
  const responseBody = {
    'title': 'Plan nutricional personalizado',
    'summary': 'Un patrón equilibrado puede apoyar tus objetivos.',
    'considerations': ['Consulta tus cambios con un profesional de salud.'],
    'menus': [
      {
        'name': 'Lunes',
        'day': 'Lunes',
        'meals': ['Avena con frutos rojos'],
      },
    ],
  };

  Future<({ClinicalProfileController controller, _MemoryStore store})>
      pumpPanel(
    WidgetTester tester, {
    http.Client? client,
    String preferences = '',
  }) async {
    final store = _MemoryStore()..preferences = preferences;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: store,
      client: client ??
          MockClient((_) async => http.Response(jsonEncode(responseBody), 200)),
    );
    final controller = ClinicalProfileController(
      repository: MockClinicalProfileRepository(),
      initialProfile: const ClinicalConditionProfile(
        conditions: {ClinicalCondition.diabetes: ClinicalSeverity.moderate},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LocalizationScope(
          language: AppLanguage.spanish,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClinicalConditionsPanel(
                controller: controller,
                aiDiagnosisRepository: repository,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (controller: controller, store: store);
  }

  testWidgets('generates, persists, and opens the diagnosis and menus', (
    tester,
  ) async {
    final state = await pumpPanel(tester);
    addTearDown(state.controller.dispose);

    expect(find.text('Obtener diagnóstico'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai_diagnosis_generate_button')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('ai_diagnosis_success_banner')), findsOneWidget);
    expect(state.store.report?.title, responseBody['title']);
    expect(find.text('Ver informe guardado'), findsOneWidget);

    final viewButton = find.byKey(const Key('ai_diagnosis_view_saved_button'));
    await tester.ensureVisible(viewButton);
    await tester.tap(viewButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_diagnosis_result_sheet')), findsOneWidget);
    await tester.ensureVisible(find.text('Avena con frutos rojos'));
    expect(find.text('Avena con frutos rojos'), findsOneWidget);
    await tester.ensureVisible(
      find.textContaining('no constituye un diagnóstico médico'),
    );
    expect(find.textContaining('no constituye un diagnóstico médico'),
        findsOneWidget);
  });

  testWidgets('shows loading state and disables duplicate generation', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final state = await pumpPanel(
      tester,
      client: MockClient((_) => response.future),
    );
    addTearDown(state.controller.dispose);

    await tester.tap(find.byKey(const Key('ai_diagnosis_generate_button')));
    await tester.pump();
    expect(find.text('Generando…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('ai_diagnosis_generate_button')),
          )
          .onPressed,
      isNull,
    );

    response.complete(http.Response(jsonEncode(responseBody), 200));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('ai_diagnosis_success_banner')), findsOneWidget);
  });
}
