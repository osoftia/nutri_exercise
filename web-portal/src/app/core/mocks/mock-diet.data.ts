export interface Meal {
  id: number;
  name: string;
  mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
}

export interface DailyMenu {
  id: number;
  date: string;
  totalCalories: number;
  meals: Meal[];
}

export const mockDailyMenus: DailyMenu[] = [
  {
    id: 1,
    date: '2026-08-07',
    totalCalories: 2100,
    meals: [
      { id: 101, name: 'Oatmeal with berries', mealType: 'breakfast', calories: 350, protein: 12, carbs: 55, fat: 8 },
      { id: 102, name: 'Grilled chicken salad', mealType: 'lunch', calories: 520, protein: 42, carbs: 30, fat: 22 },
      { id: 103, name: 'Salmon with quinoa', mealType: 'dinner', calories: 640, protein: 48, carbs: 52, fat: 24 },
      { id: 104, name: 'Greek yogurt & nuts', mealType: 'snack', calories: 590, protein: 18, carbs: 20, fat: 15 },
    ],
  },
  {
    id: 2,
    date: '2026-08-08',
    totalCalories: 1950,
    meals: [
      { id: 201, name: 'Egg white omelette', mealType: 'breakfast', calories: 310, protein: 26, carbs: 12, fat: 16 },
      { id: 202, name: 'Turkey wrap', mealType: 'lunch', calories: 480, protein: 34, carbs: 48, fat: 14 },
      { id: 203, name: 'Beef stir-fry', mealType: 'dinner', calories: 610, protein: 52, carbs: 44, fat: 20 },
      { id: 204, name: 'Protein shake', mealType: 'snack', calories: 550, protein: 30, carbs: 15, fat: 6 },
    ],
  },
];
