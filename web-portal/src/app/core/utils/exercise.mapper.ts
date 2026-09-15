import { GenericExercise, MuscleGroup, CreateExercisePayload } from '../models/routine-board.model';
import { Exercise, WorkoutDay } from '../mocks/mock-routine.data';

export function toGenericExercise(payload: CreateExercisePayload, id: number): GenericExercise {
  return {
    id,
    name: payload.name.trim(),
    muscleGroup: payload.muscleGroup,
    bodyZones: [...(payload.bodyZones ?? [])],
    sets: payload.sets,
    reps: payload.reps.trim(),
    restSeconds: payload.restSeconds,
    isCustom: true,
    createdAt: new Date().toISOString(),
  };
}

export function fromWorkoutDay(day: WorkoutDay): GenericExercise[] {
  return day.exercises.map((e) => fromExercise(e));
}

function fromExercise(e: Exercise): GenericExercise {
  return {
    id: e.id,
    name: e.name,
    muscleGroup: normalizeMuscleGroup(e.muscleGroup),
    bodyZones: [],
    sets: e.sets,
    reps: e.reps,
    restSeconds: e.restSeconds,
    isCustom: false,
    createdAt: new Date().toISOString(),
  };
}

export function normalizeMuscleGroup(raw: string): MuscleGroup {
  const key = raw.trim().toLowerCase();
  const map: Record<string, MuscleGroup> = {
    chest: 'Chest',
    back: 'Back',
    legs: 'Legs',
    triceps: 'Triceps',
    biceps: 'Biceps',
    core: 'Core',
    shoulders: 'Shoulders',
    glutes: 'Glutes',
  };
  return map[key] ?? 'Custom';
}

export function filterByMuscleGroup(items: GenericExercise[], group: MuscleGroup): GenericExercise[] {
  return items.filter((i) => i.muscleGroup === group);
}

export function dedupeById(items: GenericExercise[]): GenericExercise[] {
  const seen = new Set<number>();
  return items.filter((i) => {
    if (seen.has(i.id)) return false;
    seen.add(i.id);
    return true;
  });
}
