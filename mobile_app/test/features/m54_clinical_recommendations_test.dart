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
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/models/ai_diagnosis.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/services/http_timeout_configuration.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

class _CachedDiagnosisStore implements AiDiagnosisStore {
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
  testWidgets('generates, caches and logs a localized clinical meal', (
    tester,
  ) async {
    HttpTimeoutConfiguration.reset();
    HttpTimeoutConfiguration.setSeconds(35);
    addTearDown(HttpTimeoutConfiguration.reset);
    const rawResponse = {
      'title': 'Menú para diabetes',
      'summary': 'Opciones equilibradas para la semana.',
      'considerations': ['Consulta los cambios con tu profesional de salud.'],
      'menus': [
        {
          'name': 'Lunes',
          'day': 'Lunes',
          'meals': [
            {
              'name': 'Avena con frutos rojos',
              'description': 'Avena integral con arándanos.',
              'calories': 320,
              'protein': 12,
              'carbs': 48,
              'fat': 8,
            },
          ],
        },
      ],
    };
    final store = _CachedDiagnosisStore();
    late http.Request captured;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: store,
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(rawResponse), 200);
      }),
    );
    expect(repository.timeout.inSeconds, 35);
    const profile = ClinicalConditionProfile(
      conditions: {ClinicalCondition.diabetes: ClinicalSeverity.moderate},
    );

    final report = await repository.generateDiagnosis(
      profile: profile,
      foodPreferences: 'Vegetariana',
      language: 'es',
      userId: 42,
    );
    final payload = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(payload['preferences'], contains('español'));
    expect(payload['conditions'], 'diabetes:moderate');
    expect(payload['userId'], 42);
    expect(report.responseJson, jsonEncode(rawResponse));
    expect(
        store.report?.menus.single.meals.single.name, 'Avena con frutos rojos');

    final nutritionController = NutritionController(
      repository: MockNutritionRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LocalizationScope(
          language: AppLanguage.spanish,
          child: Scaffold(
            body: NutritionPage(
              controller: nutritionController,
              aiDiagnosisRepository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Recomendado por condición clínica'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('nutrition_clinical_recommendations_accordion')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Avena con frutos rojos'), findsOneWidget);
    expect(find.text('Avena integral con arándanos.'), findsOneWidget);

    final addMeal = find.byKey(const Key('clinical_recommendation_add_0_0'));
    await tester.ensureVisible(addMeal);
    await tester.tap(addMeal);
    await tester.pumpAndSettle();

    expect(nutritionController.entries, hasLength(1));
    expect(nutritionController.entries.single.name, 'Avena con frutos rojos');
    expect(nutritionController.entries.single.calories, 320);
    expect(nutritionController.entries.single.proteinG, 12);
  });
}
