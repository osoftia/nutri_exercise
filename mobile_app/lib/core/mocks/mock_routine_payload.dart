// ---------------------------------------------------------------------------
// Mock Routine Payload – mirrors the C# backend JSON schema exactly.
//
// Schema per day:
//   id: int
//   name: String          (focus area, e.g. "Chest & Triceps")
//   dayOfWeek: String     (e.g. "Monday")
//   description: String
//   model: String         (LLM model identifier)
//   generatedAt: String   (ISO-8601)
//   sources: List<String> (RAG source paths)
//   exercises: List<Exercise>
//     id: int
//     name: String
//     muscleGroup: String
//     series: int
//     reps: String
//     restSeconds: int
//     weight: String?     (optional, e.g. "80 kg")
//   nutrition: NutritionInfo?
//     totalCalories: int
//     protein: int
//     carbs: int
//     fat: int
//     meals: List<Meal>
//       id: int
//       name: String
//       mealType: String
//       calories: int
//       protein: int
//       carbs: int
//       fat: int
// ---------------------------------------------------------------------------

const mockRoutineApiPayload = <Map<String, dynamic>>[
  // ── Day 1: Chest & Triceps ──────────────────────────────────────────────
  {
    'id': 1,
    'name': 'Chest & Triceps',
    'dayOfWeek': 'Monday',
    'description': 'Push strength and hypertrophy session targeting '
        'pectoralis major, anterior deltoids, and triceps.',
    'model': 'llama3',
    'generatedAt': '2026-08-15T09:30:00Z',
    'sources': [
      'rag://exercise-library/chest',
      'rag://nutrition/protein',
    ],
    'exercises': [
      {
        'id': 1001,
        'name': 'Bench Press',
        'muscleGroup': 'Chest',
        'series': 4,
        'reps': '8-12',
        'restSeconds': 90,
        'weight': '80 kg',
      },
      {
        'id': 1002,
        'name': 'Incline Dumbbell Press',
        'muscleGroup': 'Chest',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 90,
        'weight': '30 kg',
      },
      {
        'id': 1003,
        'name': 'Cable Fly',
        'muscleGroup': 'Chest',
        'series': 3,
        'reps': '12-15',
        'restSeconds': 60,
        'weight': '15 kg',
      },
      {
        'id': 1004,
        'name': 'Triceps Pushdown',
        'muscleGroup': 'Triceps',
        'series': 3,
        'reps': '12-15',
        'restSeconds': 60,
        'weight': '25 kg',
      },
      {
        'id': 1005,
        'name': 'Overhead Triceps Extension',
        'muscleGroup': 'Triceps',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 60,
        'weight': '20 kg',
      },
    ],
    'nutrition': {
      'totalCalories': 2100,
      'protein': 140,
      'carbs': 220,
      'fat': 70,
      'meals': [
        {
          'id': 101,
          'name': 'Oatmeal with berries',
          'mealType': 'breakfast',
          'calories': 350,
          'protein': 12,
          'carbs': 55,
          'fat': 8,
        },
        {
          'id': 102,
          'name': 'Grilled chicken salad',
          'mealType': 'lunch',
          'calories': 520,
          'protein': 42,
          'carbs': 30,
          'fat': 22,
        },
        {
          'id': 103,
          'name': 'Protein shake',
          'mealType': 'snack',
          'calories': 280,
          'protein': 30,
          'carbs': 15,
          'fat': 6,
        },
        {
          'id': 104,
          'name': 'Salmon with quinoa',
          'mealType': 'dinner',
          'calories': 640,
          'protein': 48,
          'carbs': 52,
          'fat': 24,
        },
      ],
    },
  },
  // ── Day 2: Back & Biceps ────────────────────────────────────────────────
  {
    'id': 2,
    'name': 'Back & Biceps',
    'dayOfWeek': 'Wednesday',
    'description': 'Pull strength session targeting latissimus dorsi, '
        'rhomboids, and biceps with controlled tempo.',
    'model': 'llama3',
    'generatedAt': '2026-08-15T09:30:00Z',
    'sources': [
      'rag://exercise-library/back',
      'rag://nutrition/recovery',
    ],
    'exercises': [
      {
        'id': 2001,
        'name': 'Deadlift',
        'muscleGroup': 'Back',
        'series': 4,
        'reps': '5-8',
        'restSeconds': 120,
        'weight': '120 kg',
      },
      {
        'id': 2002,
        'name': 'Lat Pulldown',
        'muscleGroup': 'Back',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 90,
        'weight': '50 kg',
      },
      {
        'id': 2003,
        'name': 'Seated Cable Row',
        'muscleGroup': 'Back',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 90,
        'weight': '55 kg',
      },
      {
        'id': 2004,
        'name': 'Barbell Curl',
        'muscleGroup': 'Biceps',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 60,
        'weight': '30 kg',
      },
      {
        'id': 2005,
        'name': 'Hammer Curl',
        'muscleGroup': 'Biceps',
        'series': 3,
        'reps': '12-15',
        'restSeconds': 60,
        'weight': '14 kg',
      },
    ],
    'nutrition': {
      'totalCalories': 1950,
      'protein': 150,
      'carbs': 180,
      'fat': 65,
      'meals': [
        {
          'id': 201,
          'name': 'Egg white omelette',
          'mealType': 'breakfast',
          'calories': 310,
          'protein': 26,
          'carbs': 12,
          'fat': 16,
        },
        {
          'id': 202,
          'name': 'Turkey wrap',
          'mealType': 'lunch',
          'calories': 480,
          'protein': 34,
          'carbs': 48,
          'fat': 14,
        },
        {
          'id': 203,
          'name': 'Greek yogurt & nuts',
          'mealType': 'snack',
          'calories': 310,
          'protein': 18,
          'carbs': 20,
          'fat': 15,
        },
        {
          'id': 204,
          'name': 'Beef stir-fry with rice',
          'mealType': 'dinner',
          'calories': 610,
          'protein': 52,
          'carbs': 55,
          'fat': 18,
        },
      ],
    },
  },
  // ── Day 3: Legs & Core ──────────────────────────────────────────────────
  {
    'id': 3,
    'name': 'Legs & Core',
    'dayOfWeek': 'Friday',
    'description': 'Lower-body strength and core stability session '
        'focusing on compound movements and anti-rotation.',
    'model': 'llama3',
    'generatedAt': '2026-08-15T09:30:00Z',
    'sources': [
      'rag://exercise-library/legs',
      'rag://nutrition/recovery',
    ],
    'exercises': [
      {
        'id': 3001,
        'name': 'Squat',
        'muscleGroup': 'Legs',
        'series': 4,
        'reps': '6-10',
        'restSeconds': 120,
        'weight': '100 kg',
      },
      {
        'id': 3002,
        'name': 'Leg Press',
        'muscleGroup': 'Legs',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 90,
        'weight': '160 kg',
      },
      {
        'id': 3003,
        'name': 'Romanian Deadlift',
        'muscleGroup': 'Hamstrings',
        'series': 3,
        'reps': '8-10',
        'restSeconds': 90,
        'weight': '80 kg',
      },
      {
        'id': 3004,
        'name': 'Plank',
        'muscleGroup': 'Core',
        'series': 3,
        'reps': '60 sec',
        'restSeconds': 45,
        'weight': null,
      },
      {
        'id': 3005,
        'name': 'Cable Woodchop',
        'muscleGroup': 'Core',
        'series': 3,
        'reps': '12-15',
        'restSeconds': 60,
        'weight': '15 kg',
      },
    ],
    'nutrition': {
      'totalCalories': 2250,
      'protein': 155,
      'carbs': 240,
      'fat': 68,
      'meals': [
        {
          'id': 301,
          'name': 'Whole-grain pancakes',
          'mealType': 'breakfast',
          'calories': 420,
          'protein': 22,
          'carbs': 60,
          'fat': 10,
        },
        {
          'id': 302,
          'name': 'Chicken breast with sweet potato',
          'mealType': 'lunch',
          'calories': 580,
          'protein': 48,
          'carbs': 50,
          'fat': 14,
        },
        {
          'id': 303,
          'name': 'Cottage cheese & pineapple',
          'mealType': 'snack',
          'calories': 210,
          'protein': 24,
          'carbs': 18,
          'fat': 4,
        },
        {
          'id': 304,
          'name': 'Salmon with quinoa & greens',
          'mealType': 'dinner',
          'calories': 640,
          'protein': 48,
          'carbs': 52,
          'fat': 24,
        },
      ],
    },
  },
  // ── Day 4: Shoulders & Abs ──────────────────────────────────────────────
  {
    'id': 4,
    'name': 'Shoulders & Abs',
    'dayOfWeek': 'Saturday',
    'description': 'Overhead pressing volume with direct core work '
        'for rotational stability and bracing.',
    'model': 'llama3',
    'generatedAt': '2026-08-15T09:30:00Z',
    'sources': [
      'rag://exercise-library/shoulders',
      'rag://nutrition/protein',
    ],
    'exercises': [
      {
        'id': 4001,
        'name': 'Overhead Press',
        'muscleGroup': 'Shoulders',
        'series': 4,
        'reps': '6-10',
        'restSeconds': 90,
        'weight': '50 kg',
      },
      {
        'id': 4002,
        'name': 'Lateral Raise',
        'muscleGroup': 'Shoulders',
        'series': 3,
        'reps': '12-15',
        'restSeconds': 60,
        'weight': '10 kg',
      },
      {
        'id': 4003,
        'name': 'Face Pull',
        'muscleGroup': 'Shoulders',
        'series': 3,
        'reps': '15-20',
        'restSeconds': 60,
        'weight': '15 kg',
      },
      {
        'id': 4004,
        'name': 'Hanging Leg Raise',
        'muscleGroup': 'Core',
        'series': 3,
        'reps': '10-15',
        'restSeconds': 60,
        'weight': null,
      },
      {
        'id': 4005,
        'name': 'Ab Rollout',
        'muscleGroup': 'Core',
        'series': 3,
        'reps': '10-12',
        'restSeconds': 60,
        'weight': null,
      },
    ],
    'nutrition': {
      'totalCalories': 2050,
      'protein': 145,
      'carbs': 210,
      'fat': 62,
      'meals': [
        {
          'id': 401,
          'name': 'Scrambled eggs & avocado toast',
          'mealType': 'breakfast',
          'calories': 400,
          'protein': 24,
          'carbs': 30,
          'fat': 20,
        },
        {
          'id': 402,
          'name': 'Tuna poke bowl',
          'mealType': 'lunch',
          'calories': 520,
          'protein': 38,
          'carbs': 55,
          'fat': 12,
        },
        {
          'id': 403,
          'name': 'Apple & peanut butter',
          'mealType': 'snack',
          'calories': 280,
          'protein': 8,
          'carbs': 30,
          'fat': 14,
        },
        {
          'id': 404,
          'name': 'Chicken pasta primavera',
          'mealType': 'dinner',
          'calories': 580,
          'protein': 42,
          'carbs': 60,
          'fat': 14,
        },
      ],
    },
  },
];

// ── Mock AI-generated routine response ──────────────────────────────────────
const mockGeneratedRoutineApiPayload = <String, dynamic>{
  'id': 99,
  'name': 'AI Generated Routine',
  'dayOfWeek': 'Weekly',
  'description': 'Mock AI routine for: {userPreferences}\n\n'
      'Generated by llama3 using retrieved exercise and nutrition context.',
  'model': 'llama3',
  'generatedAt': '2026-08-15T09:30:00Z',
  'sources': ['rag://exercise-library', 'rag://nutrition/protein'],
  'exercises': [
    {
      'id': 1001,
      'name': 'Bench Press',
      'muscleGroup': 'Chest',
      'series': 4,
      'reps': '8-12',
      'restSeconds': 90,
      'weight': '80 kg',
    },
    {
      'id': 3001,
      'name': 'Squat',
      'muscleGroup': 'Legs',
      'series': 4,
      'reps': '6-10',
      'restSeconds': 120,
      'weight': '100 kg',
    },
  ],
  'nutrition': {
    'totalCalories': 2100,
    'protein': 140,
    'carbs': 220,
    'fat': 70,
    'meals': [
      {
        'id': 101,
        'name': 'Oatmeal with berries',
        'mealType': 'breakfast',
        'calories': 350,
        'protein': 12,
        'carbs': 55,
        'fat': 8,
      },
      {
        'id': 102,
        'name': 'Grilled chicken salad',
        'mealType': 'lunch',
        'calories': 520,
        'protein': 42,
        'carbs': 30,
        'fat': 22,
      },
    ],
  },
};
