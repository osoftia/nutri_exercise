import 'app_language.dart';
import 'app_strings.dart';

/// Spanish dictionary.
class SpanishStrings extends AppStrings {
  /// Creates the Spanish dictionary.
  const SpanishStrings();

  @override
  String get appTitle => 'NutriExercise';

  @override
  String get navRoutines => 'Rutinas';
  @override
  String get navNutrition => 'Nutrición';
  @override
  String get navSchedule => 'Agenda';
  @override
  String get navProfile => 'Perfil';

  @override
  String get routinesTitle => 'Rutinas';
  @override
  String get nutritionTitle => 'Nutrición';
  @override
  String get profileTitle => 'Perfil';

  @override
  String get save => 'Guardar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get add => 'Añadir';
  @override
  String get delete => 'Eliminar';
  @override
  String get close => 'Cerrar';
  @override
  String get history => 'Historial';
  @override
  String get weeklyStats => 'Estadísticas semanales';
  @override
  String get dailyRoutineSummary => 'Resumen diario de rutina';
  @override
  String get dailyNutritionSummary => 'Resumen diario de nutrición';

  @override
  String get quickAddTitle => 'Añadir rápido';
  @override
  String get calorieLabel => 'Calorías';
  @override
  String get proteinLabel => 'Proteínas';
  @override
  String get carbsLabel => 'Carbohidratos';
  @override
  String get fatLabel => 'Grasas';
  @override
  String get portionLabel => 'Porción (g)';

  @override
  String addFoodTitle(String foodName) => 'Añadir $foodName';

  @override
  String get quickAddOatmealBerries => 'Avena con frutos rojos';
  @override
  String get quickAddGrilledChickenBowl => 'Bol de pollo a la parrilla';
  @override
  String get quickAddSalmonQuinoa => 'Salmón con quinoa';
  @override
  String get quickAddGreekYogurtAlmonds => 'Yogur griego con almendras';
  @override
  String get quickAddProteinShake => 'Batido de proteínas';

  @override
  String get languageSectionTitle => 'Idioma';
  @override
  String get languageSectionSubtitle => 'Elige el idioma de la aplicación';

  @override
  String languageName(AppLanguage language) => switch (language) {
        AppLanguage.english => 'Inglés',
        AppLanguage.spanish => 'Español',
      };
}
