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
  _MemoryStore(this.report);
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
    'diagnosticReport': 'Nuevo plan personalizado.',
    'mealSuggestions': ['Avena con frutos rojos'],
  };

  AiDiagnosisReport existingReport() => AiDiagnosisReport(
        title: 'Informe previo',
        summary: 'Contenido previamente guardado.',
        considerations: const [],
        conditionIds: const ['diabetes'],
        foodPreferences: '',
        language: 'es',
        menus: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );

  Future<({_MemoryStore store, int Function() requestCount})> pumpPanel(
    WidgetTester tester,
  ) async {
    final store = _MemoryStore(existingReport());
    var requests = 0;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: store,
      client: MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(responseBody), 200);
      }),
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
    return (store: store, requestCount: () => requests);
  }

  testWidgets('asks for confirmation before overwriting a saved diagnosis', (
    tester,
  ) async {
    final state = await pumpPanel(tester);
    final existing = state.store.report;

    await tester.tap(find.byKey(const Key('ai_diagnosis_generate_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('ai_diagnosis_overwrite_dialog')),
      findsOneWidget,
    );
    expect(
      find.text(
        '¿Está seguro de que desea volver a generar el diagnóstico?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ai_diagnosis_overwrite_cancel')));
    await tester.pumpAndSettle();

    expect(state.requestCount(), 0);
    expect(state.store.report, same(existing));
    expect(
      find.byKey(const Key('ai_diagnosis_overwrite_dialog')),
      findsNothing,
    );
  });

  testWidgets('regenerates the diagnosis when the confirmation is accepted', (
    tester,
  ) async {
    final state = await pumpPanel(tester);

    await tester.tap(find.byKey(const Key('ai_diagnosis_generate_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai_diagnosis_overwrite_confirm')));
    await tester.pumpAndSettle();

    expect(state.requestCount(), 1);
    expect(state.store.report?.summary, 'Nuevo plan personalizado.');
    expect(
      find.byKey(const Key('ai_diagnosis_overwrite_dialog')),
      findsNothing,
    );
  });

  testWidgets('generates directly when no saved diagnosis exists', (
    tester,
  ) async {
    final store = _MemoryStore(null);
    var requests = 0;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: store,
      client: MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(responseBody), 200);
      }),
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

    await tester.tap(find.byKey(const Key('ai_diagnosis_generate_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai_diagnosis_overwrite_dialog')), findsNothing);
    expect(requests, 1);
    expect(store.report?.summary, 'Nuevo plan personalizado.');
  });
}
