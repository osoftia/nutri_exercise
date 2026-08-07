export interface Exercise {
  id: number;
  name: string;
  muscleGroup: string;
  sets: number;
  reps: string;
  restSeconds: number;
}

export interface WorkoutDay {
  id: number;
  weekday: string;
  focus: string;
  exercises: Exercise[];
}

export const mockWorkoutRoutines: WorkoutDay[] = [
  {
    id: 1,
    weekday: 'Monday',
    focus: 'Chest & Triceps',
    exercises: [
      { id: 1001, name: 'Bench Press', muscleGroup: 'Chest', sets: 4, reps: '8-12', restSeconds: 90 },
      { id: 1002, name: 'Incline Dumbbell Press', muscleGroup: 'Chest', sets: 3, reps: '10-12', restSeconds: 90 },
      { id: 1003, name: 'Triceps Pushdown', muscleGroup: 'Triceps', sets: 3, reps: '12-15', restSeconds: 60 },
    ],
  },
  {
    id: 2,
    weekday: 'Wednesday',
    focus: 'Back & Biceps',
    exercises: [
      { id: 2001, name: 'Deadlift', muscleGroup: 'Back', sets: 4, reps: '5-8', restSeconds: 120 },
      { id: 2002, name: 'Lat Pulldown', muscleGroup: 'Back', sets: 3, reps: '10-12', restSeconds: 90 },
      { id: 2003, name: 'Barbell Curl', muscleGroup: 'Biceps', sets: 3, reps: '10-12', restSeconds: 60 },
    ],
  },
  {
    id: 3,
    weekday: 'Friday',
    focus: 'Legs & Core',
    exercises: [
      { id: 3001, name: 'Squat', muscleGroup: 'Legs', sets: 4, reps: '6-10', restSeconds: 120 },
      { id: 3002, name: 'Leg Press', muscleGroup: 'Legs', sets: 3, reps: '10-12', restSeconds: 90 },
      { id: 3003, name: 'Plank', muscleGroup: 'Core', sets: 3, reps: '60 sec', restSeconds: 45 },
    ],
  },
];
