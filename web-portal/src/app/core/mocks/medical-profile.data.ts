import {
  AiSuggestion,
  FoodItem,
  MedicalCondition,
  UserProfile,
} from '../models/medical-profile.model';

export const MOCK_CONDITIONS: MedicalCondition[] = [
  {
    id: 'high-cholesterol',
    name: 'High Cholesterol',
    severity: 'moderate',
    description: 'Elevated LDL cholesterol. Limit saturated fat intake.',
  },
  {
    id: 'type-2-diabetes',
    name: 'Type 2 Diabetes',
    severity: 'moderate',
    description: 'Impaired glucose regulation. Limit fast-absorbing sugars.',
  },
  {
    id: 'gout',
    name: 'Gout',
    severity: 'high',
    description: 'Uric acid crystal buildup. Limit high-purine foods.',
  },
];

export const MOCK_PROFILES: UserProfile[] = [
  {
    id: 'user-anna',
    displayName: 'Anna',
    age: 54,
    conditionIds: ['high-cholesterol'],
    notes: 'Wants heart-healthy breakfast options.',
  },
  {
    id: 'user-ben',
    displayName: 'Ben',
    age: 47,
    conditionIds: ['type-2-diabetes'],
    notes: 'Tracks post-meal glucose spikes.',
  },
  {
    id: 'user-cara',
    displayName: 'Cara',
    age: 61,
    conditionIds: ['gout'],
    notes: 'Avoids purine-rich seafood and red meat.',
  },
];

function food(
  id: string,
  name: string,
  category: string,
  tags: string[],
  baseNutrients: [number, number, number, number],
): FoodItem {
  const [calories, protein, carbs, fat] = baseNutrients;
  return { id, name, category, tags, baseNutrients: { calories, protein, carbs, fat } };
}

export const MOCK_FOODS: FoodItem[] = [
  food('bacon', 'Bacon', 'meat', ['bacon', 'red-meat', 'high-saturated-fat'], [541, 37, 1, 42]),
  food('oatmeal', 'Oatmeal', 'grain', ['oatmeal', 'high-fiber', 'whole-grain'], [150, 5, 27, 3]),
  food('shrimp', 'Shrimp', 'seafood', ['shrimp', 'high-purine', 'lean-protein'], [99, 24, 0, 0.3]),
  food('sugary-soda', 'Sugary Soda', 'beverage', ['sugary-soda', 'high-sugar'], [150, 0, 39, 0]),
  food('salmon', 'Salmon', 'seafood', ['salmon', 'omega-3', 'lean-protein'], [208, 20, 0, 13]),
  food('lentils', 'Lentils', 'legume', ['lentils', 'high-fiber', 'plant-protein'], [116, 9, 20, 0.4]),
  food('red-meat', 'Red Meat', 'meat', ['red-meat', 'high-purine', 'high-saturated-fat'], [250, 26, 0, 15]),
  food('chicken-breast', 'Chicken Breast', 'meat', ['lean-protein', 'low-fat'], [165, 31, 0, 3.6]),
  food('white-rice', 'White Rice', 'grain', ['refined-carb'], [130, 2.7, 28, 0.3]),
  food('broccoli', 'Broccoli', 'vegetable', ['high-fiber', 'low-calorie'], [34, 2.8, 6.6, 0.4]),
  food('greek-yogurt', 'Greek Yogurt', 'dairy', ['high-protein', 'probiotic'], [97, 9, 3.6, 5]),
  food('almonds', 'Almonds', 'nuts', ['healthy-fat', 'high-fiber'], [579, 21, 22, 50]),
  food('white-bread', 'White Bread', 'grain', ['refined-carb', 'high-sugar'], [265, 9, 49, 3.2]),
  food('orange-juice', 'Orange Juice', 'beverage', ['high-sugar', 'vitamin-c'], [112, 1.7, 26, 0.5]),
  food('eggs', 'Eggs', 'dairy', ['high-protein'], [155, 13, 1.1, 11]),
  food('kale', 'Kale', 'vegetable', ['high-fiber', 'low-calorie', 'vitamin-c'], [49, 4.3, 8.8, 0.9]),
];

export const MOCK_SUGGESTIONS: AiSuggestion[] = [
  {
    id: 'tip-cholesterol',
    text: 'Your cholesterol levels require attention today. Avoid saturated fats.',
    context: 'high-cholesterol',
  },
  {
    id: 'tip-diabetes',
    text: 'Your glucose has been unsteady. Prefer fiber-rich foods over sugary drinks.',
    context: 'type-2-diabetes',
  },
  {
    id: 'tip-gout',
    text: 'Your uric acid is elevated. Avoid high-purine foods like shrimp and red meat.',
    context: 'gout',
  },
  {
    id: 'tip-general',
    text: 'Balance every plate with vegetables, lean protein, and whole grains.',
    context: 'general',
  },
];
