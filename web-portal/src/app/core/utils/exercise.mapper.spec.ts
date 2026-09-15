import { describe, it, expect } from 'vitest';
import { toGenericExercise, fromWorkoutDay, normalizeMuscleGroup, filterByMuscleGroup, dedupeById } from './exercise.mapper';
import { GenericExercise } from '../models/routine-board.model';

describe('exercise.mapper', () => {
  it('creates generic exercise with trimmed fields', () => {
    const e = toGenericExercise({ name: ' Hip Thrust ', muscleGroup: 'Glutes', sets: 3, reps: ' 12 ', restSeconds: 60 }, 99);
    expect(e.name).toBe('Hip Thrust');
    expect(e.reps).toBe('12');
    expect(e.isCustom).toBe(true);
  });

  it('normalizes muscle group', () => {
    expect(normalizeMuscleGroup('chest')).toBe('Chest');
    expect(normalizeMuscleGroup('  TRICEPS ')).toBe('Triceps');
    expect(normalizeMuscleGroup('unknown')).toBe('Custom');
  });

  it('filters by muscle group', () => {
    const items: GenericExercise[] = [
      { id: 1, name: 'a', muscleGroup: 'Chest', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
      { id: 2, name: 'b', muscleGroup: 'Back', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
    ];
    expect(filterByMuscleGroup(items, 'Chest')).toHaveLength(1);
  });

  it('carries body zones from the create payload', () => {
    const e = toGenericExercise({ name: 'Flow', muscleGroup: 'Core', bodyZones: ['Core'], sets: 2, reps: '10', restSeconds: 30 }, 7);
    expect(e.bodyZones).toEqual(['Core']);
  });

  it('maps a workout day to generic exercises with empty zones', () => {
    const items = fromWorkoutDay({
      id: 1,
      weekday: 'Monday',
      focus: 'Legs',
      exercises: [{ id: 5, name: 'Squat', muscleGroup: 'Legs', sets: 4, reps: '8', restSeconds: 90 }],
    });
    expect(items).toHaveLength(1);
    expect(items[0].muscleGroup).toBe('Legs');
    expect(items[0].bodyZones).toEqual([]);
    expect(items[0].isCustom).toBe(false);
  });

  it('dedupes by id', () => {
    const items: GenericExercise[] = [
      { id: 1, name: 'a', muscleGroup: 'Chest', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
      { id: 1, name: 'a2', muscleGroup: 'Chest', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
      { id: 2, name: 'b', muscleGroup: 'Back', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
    ];
    expect(dedupeById(items).map((i) => i.id)).toEqual([1, 2]);
  });
});
