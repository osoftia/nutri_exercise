export type MuscleGroup =
  | 'Chest'
  | 'Back'
  | 'Legs'
  | 'Triceps'
  | 'Biceps'
  | 'Core'
  | 'Shoulders'
  | 'Glutes'
  | 'Custom';

export type DayOfWeek =
  | 'Monday'
  | 'Tuesday'
  | 'Wednesday'
  | 'Thursday'
  | 'Friday'
  | 'Saturday'
  | 'Sunday';

export interface GenericExercise {
  id: number;
  name: string;
  muscleGroup: MuscleGroup;
  bodyZones: string[];
  sets: number;
  reps: string;
  restSeconds: number;
  isCustom: boolean;
  createdAt: string;
}

export interface MuscleGroupPackage {
  id: string;
  muscleGroup: MuscleGroup;
  label: string;
  color: string;
}

export interface RoutineColumn {
  id: string;
  title: string;
  muscleGroup: MuscleGroup;
  dayOfWeek: DayOfWeek;
  bodyZones: string[];
  exerciseIds: number[];
}

export interface RoutineBoard {
  columns: RoutineColumn[];
  exercises: GenericExercise[];
}

export interface CreateExercisePayload {
  name: string;
  muscleGroup: MuscleGroup;
  bodyZones?: string[];
  sets: number;
  reps: string;
  restSeconds: number;
}

export interface UpdateExercisePayload {
  name?: string;
  muscleGroup?: MuscleGroup;
  bodyZones?: string[];
  sets?: number;
  reps?: string;
  restSeconds?: number;
}
