/// Default quick-log meals used when there is no meal history for a slot.
///
/// Keys are the `MealType` names (`breakfast`, `lunch`, `dinner`).
const Map<String, List<String>> defaultMealsByTimeOfDay = {
  'breakfast': ['Huevos con arepa', 'Avena', 'Frutas'],
  'lunch': ['Pechuga con arroz', 'Pescado', 'Carne asada'],
  'dinner': ['Ensalada', 'Sopa', 'Huevos cocidos'],
};