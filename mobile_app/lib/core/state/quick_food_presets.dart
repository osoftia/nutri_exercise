import '../domain/body_projection/nutrition_log.dart';

/// Quick-add food presets appended by the blueprint food sheet's "Add food"
/// action.
///
/// Extracted from `body_detail_controller.dart` (M48 decomposition) so the
/// controller stays focused on state, not sample data.
const List<LoggedFood> quickFoodPresets = [
  LoggedFood(
    name: 'Protein Shake',
    portion: '1 scoop',
    calories: 150,
    proteinG: 30,
    carbsG: 6,
    fatG: 1,
    saturatedFatG: 0.5,
    sugarsG: 2,
    fiberG: 0,
    glycemicIndex: 30,
    purinesMg: 20,
    sodiumMg: 180,
    time: '18:00',
  ),
  LoggedFood(
    name: 'Banana',
    portion: '1 medium',
    calories: 105,
    proteinG: 1,
    carbsG: 27,
    fatG: 0,
    saturatedFatG: 0,
    sugarsG: 14,
    fiberG: 3,
    glycemicIndex: 51,
    purinesMg: 27,
    sodiumMg: 1,
    time: '18:05',
  ),
  LoggedFood(
    name: 'Almonds',
    portion: '30 g',
    calories: 170,
    proteinG: 6,
    carbsG: 6,
    fatG: 15,
    saturatedFatG: 1,
    sugarsG: 1,
    fiberG: 4,
    glycemicIndex: 15,
    purinesMg: 45,
    sodiumMg: 0,
    time: '18:10',
  ),
];
