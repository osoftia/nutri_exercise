import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/ai_diagnosis.dart';

void main() {
  test('binds directly to the backend diagnosticReport and mealSuggestions',
      () {
    final report = AiDiagnosisReport.fromJson(
      {
        'diagnosticReport': 'Prioriza proteína magra, fibra y agua.',
        'mealSuggestions': [
          {
            'name': 'Avena con frutos rojos',
            'calories': 320,
            'protein': 12,
            'carbs': 50,
            'fat': 8,
          },
          'Bowl de lentejas con verduras',
        ],
      },
      conditionIds: const ['diabetes'],
      foodPreferences: 'vegetariana',
      language: 'es',
    );

    expect(report.summary, 'Prioriza proteína magra, fibra y agua.');
    expect(report.menus, hasLength(1));
    expect(report.menus.single.meals, hasLength(2));
    expect(report.menus.single.meals.first.name, 'Avena con frutos rojos');
    expect(report.menus.single.meals.first.calories, 320);
    expect(report.menus.single.meals.first.proteinG, 12);
    expect(report.menus.single.meals.last.name,
        'Bowl de lentejas con verduras');
  });

  test('reads a structured diagnosticReport object without placeholders', () {
    final report = AiDiagnosisReport.fromJson(
      {
        'diagnosticReport': {
          'title': 'Informe clínico',
          'summary': 'Detalle estructurado del diagnóstico.',
          'considerations': ['Revisar con tu profesional de salud.'],
        },
        'mealSuggestions': [
          {'name': 'Ensalada de garbanzos'},
        ],
      },
      conditionIds: const ['highCholesterol'],
      foodPreferences: '',
      language: 'es',
    );

    expect(report.title, 'Informe clínico');
    expect(report.summary, 'Detalle estructurado del diagnóstico.');
    expect(report.considerations, ['Revisar con tu profesional de salud.']);
    expect(report.menus.single.meals.single.name, 'Ensalada de garbanzos');
  });

  test('does not substitute generic educational placeholder content', () {
    final report = AiDiagnosisReport.fromJson(
      const {},
      conditionIds: const [],
      foodPreferences: '',
      language: 'es',
    );

    expect(report.title, isEmpty);
    expect(report.summary, isEmpty);
    expect(report.menus, isEmpty);

    final unnamedMeal = MealSuggestion.fromJson(
      const {'calories': 100},
      language: 'es',
    );
    expect(unnamedMeal.name, isEmpty);
    expect(unnamedMeal.calories, 100);
  });
}
