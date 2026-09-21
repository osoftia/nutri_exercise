import '../../models/symptom_log.dart';
import '../../models/user_profile.dart';
import '../popups/exercise_completion.dart';
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

  // --- Routines tab -----------------------------------------------------
  @override
  String get bodyProjectionLabel => 'Proyección corporal';
  @override
  String get workoutCompletedTitle => 'Entrenamiento completado';
  @override
  String get workoutCompletedSubtitle =>
      'Registra el entrenamiento de hoy y hace crecer tu avatar';

  // --- Schedule tab -----------------------------------------------------
  @override
  String get scheduleTitle => 'Agenda';
  @override
  String get noEventsScheduled => 'No hay eventos programados';

  static const List<String> _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const List<String> _weekdayNarrow = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
  static const List<String> _weekdayShort = [
    'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom',
  ];

  @override
  String monthYear(DateTime date) =>
      '${_months[date.month - 1]} de ${date.year}';

  @override
  String weekdayNarrow(int weekday) => _weekdayNarrow[weekday - 1];

  @override
  String weekdayShort(int weekday) => _weekdayShort[weekday - 1];

  @override
  String agendaTitle(DateTime date) =>
      '${_weekdayShort[date.weekday - 1]}, ${date.day} de '
      '${_months[date.month - 1]}';

  @override
  String get previousMonthTooltip => 'Mes anterior';
  @override
  String get nextMonthTooltip => 'Mes siguiente';

  // --- Symptom tracker --------------------------------------------------
  @override
  String get symptomTrackerTitle => 'Síntomas diarios';
  @override
  String get symptomTrackerSubtitle =>
      'Mantén pulsado un icono para ver qué registra';
  @override
  String get symptomNoneLogged => 'No hay síntomas registrados hoy.';

  @override
  String symptomLabel(SymptomType type) => switch (type) {
        SymptomType.pain => 'Dolor',
        SymptomType.discomfort => 'Molestias corporales',
        SymptomType.energy => 'Energía',
        SymptomType.stress => 'Estrés',
      };

  @override
  String symptomTooltip(SymptomType type) =>
      '${symptomLabel(type)} — toca para cambiar la intensidad';

  @override
  String symptomLevel(int level) => switch (level) {
        0 => 'Ninguno',
        1 => 'Leve',
        2 => 'Moderado',
        _ => 'Severo',
      };

  // --- Nutrition dashboard ---------------------------------------------
  @override
  String get reactiveNotificationsTitle => 'Notificaciones de comidas';
  @override
  String get reactiveNotificationsSubtitle =>
      'Notificar justo después de registrar una comida';
  @override
  String get exerciseNotButton => 'SIN EJERCICIO';
  @override
  String get testNotificationsButton => 'Probar notificaciones';
  @override
  String get weeklyCaloriesTitle => 'Calorías semanales';
  @override
  String get logAMealTitle => 'Registrar una comida';
  @override
  String get nameFieldLabel => 'Nombre';
  @override
  String get nameFieldHint => 'p. ej. Plátano';
  @override
  String get caloriesFieldLabel => 'Calorías';
  @override
  String get caloriesFieldHint => 'p. ej. 120';

  @override
  String caloriesOfTarget(int consumed, int target) =>
      '$consumed de $target kcal';

  @override
  String macroOfTarget(int value, int target) => '$value / ${target}g';

  // --- Workout completion sheet ----------------------------------------
  @override
  String get workoutCompleteTitle => 'Entrenamiento completado';
  @override
  String get nothingLoggedYet => 'Aún no hay registros';
  @override
  String get completionEmptyBody =>
      'No se completó ningún ejercicio en este registro.';
  @override
  String get doneButton => 'Listo';

  @override
  String setsAndReps(int sets, int reps) => '$sets series · $reps reps';

  @override
  String setsRepsLoad(int completed, int planned, int reps, String load) =>
      '$completed/$planned × $reps · ${load}kg';

  @override
  String get caloriesBurnedLabel => 'Calorías quemadas';

  @override
  String recoveryLabel(String region, RecoveryLevel level) {
    final suffix = switch (level) {
      RecoveryLevel.recovered => 'RECUPERADO',
      RecoveryLevel.recovering => 'RECUPERANDO',
      RecoveryLevel.fatigued => 'FATIGADO',
    };
    return '${region.toUpperCase()} · $suffix';
  }

  // --- Food / stomach sheet --------------------------------------------
  @override
  String get stomachTitle => 'Estómago';
  @override
  String get foodLoggedToday => 'Comida registrada hoy';
  @override
  String get noFoodLoggedToday => 'No hay comida registrada hoy.';

  @override
  String macroSummary(int protein, int carbs, int fat) =>
      'P ${protein}g · C ${carbs}g · G ${fat}g';

  @override
  String get totalLabel => 'Total';

  @override
  String itemCount(int count) => '$count ${count == 1 ? 'elemento' : 'elementos'}';

  @override
  String removeItemTooltip(String name) => 'Eliminar $name';
  @override
  String get deletionOnlyLabel => 'Solo eliminación';

  @override
  String kcal(int calories) => '$calories kcal';

  @override
  String kcalAmount(num calories) => '${calories.toStringAsFixed(0)} kcal';

  // --- Exercise detail sheet -------------------------------------------
  @override
  String get noPlanForMuscle => 'Aún no hay plan para este músculo';
  @override
  String get noExercisesPlanned =>
      'No hay ejercicios planificados para este grupo muscular.';
  @override
  String get completedVsPlanned => 'Completado vs planificado';
  @override
  String get aiSuggestionLabel => 'Sugerencia de IA';

  @override
  String setsOfPlanned(int completed, int planned) =>
      '✓ $completed/$planned series';

  @override
  String setsProgress(int completed, int planned) =>
      '$completed / $planned series';

  @override
  String volumeOfPlanned(String completed, String planned) =>
      '$completed / $planned kg';

  // --- Routine summary sheet -------------------------------------------
  @override
  String get routineSummaryCaption => 'Series planificadas vs completadas';
  @override
  String get noRoutinePlanned => 'No hay rutina planificada para hoy.';
  @override
  String get totalSetsLabel => 'Series totales';

  @override
  String completedOfPlanned(int completed, int planned) =>
      '$completed / $planned';

  @override
  String regionLabel(BodyRegion region) => switch (region) {
        BodyRegion.chest => 'PECHO',
        BodyRegion.armLeft => 'BRAZO IZQ',
        BodyRegion.armRight => 'BRAZO DER',
        BodyRegion.legLeft => 'PIERNA IZQ',
        BodyRegion.legRight => 'PIERNA DER',
        BodyRegion.core => 'CORE',
        BodyRegion.head => 'CABEZA',
        BodyRegion.neck => 'CUELLO',
      };

  // --- Weekly stats sheet ----------------------------------------------
  @override
  String get weeklyStatsCaption => 'Calorías consumidas vs quemadas (7 días)';
  @override
  String get consumedLabel => 'Consumidas';
  @override
  String get burnedLabel => 'Quemadas';
  @override
  String get balanceLabel => 'Balance';

  @override
  String signedKcal(int balance) {
    final sign = balance >= 0 ? '+' : '';
    return '$sign$balance kcal';
  }

  // --- History dialog / editor -----------------------------------------
  @override
  String get editEntryTitle => 'Editar registro';

  @override
  String editEntryTitleFor(String date) => 'Editar $date';

  @override
  String get deleteRecordButton => 'Eliminar registro';

  @override
  String deleteRecordConfirm(String weekday) =>
      '¿Eliminar la rutina de "$weekday"?';

  @override
  String get exercisesFieldLabel => 'Ejercicios (separados por comas)';
  @override
  String get historyTodayEmpty => 'No hay registros para este día';
  @override
  String get logAMealAction => 'Registrar una comida';

  // --- Daily log sheet -------------------------------------------------
  @override
  String get dailyCheckInTitle => 'Registro diario';
  @override
  String get dailyCheckInSubtitle => '¿Qué comiste y entrenaste hoy?';
  @override
  String get dailyLogHint => 'Escribe tu resumen…';
  @override
  String get analyzingLabel => 'Analizando…';

  @override
  String savedSummary(String summary) => 'Guardado — $summary';

  // --- AI chat ---------------------------------------------------------
  @override
  String get aiAssistantTitle => 'Asistente IA';
  @override
  String get aiChatEmptyPrompt => 'Pídeme que arme una rutina de entrenamiento.';
  @override
  String get aiChatInputHint => 'Pide una rutina de entrenamiento…';
  @override
  String get aiServiceUnavailable =>
      'El servicio de IA no está disponible ahora mismo.';
  @override
  String get sendLabel => 'Enviar';
  @override
  String get offlineAiTitle => 'IA sin conexión';
  @override
  String get offlineAiBody =>
      'Para consultar la IA, conéctate a internet.';
  @override
  String get gotItButton => 'Entendido';

  // --- Profile form / validation ---------------------------------------
  @override
  String get ageFieldLabel => 'Edad';
  @override
  String get weightFieldLabel => 'Peso';
  @override
  String get heightFieldLabel => 'Altura';
  @override
  String get fitnessGoalLabel => 'Objetivo físico';
  @override
  String get saveProfileButton => 'Guardar perfil';

  @override
  String requiredField(String label) => '$label es obligatorio';
  @override
  String get invalidNumberMessage => 'Introduce un número válido';

  @override
  String minimumOneMessage(String label) => '$label debe ser al menos 1';

  @override
  String fitnessGoal(FitnessGoal goal) => switch (goal) {
        FitnessGoal.muscleGain => 'Ganar músculo',
        FitnessGoal.fatLoss => 'Perder grasa',
        FitnessGoal.maintain => 'Mantener',
        FitnessGoal.endurance => 'Resistencia',
      };

  // --- Main shell ------------------------------------------------------
  @override
  String get dailyLogFabLabel => 'Registro diario';
}
