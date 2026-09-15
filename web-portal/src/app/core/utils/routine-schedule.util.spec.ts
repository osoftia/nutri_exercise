import { describe, it, expect } from 'vitest';
import { RoutineColumn } from '../models/routine-board.model';
import {
  normalizeZones,
  assignColumnDay,
  duplicateColumnToDays,
  columnsForDay,
  groupColumnsByDay,
} from './routine-schedule.util';

const col = (id: string, day: RoutineColumn['dayOfWeek'] = 'Monday'): RoutineColumn => ({
  id,
  title: id,
  muscleGroup: 'Chest',
  dayOfWeek: day,
  bodyZones: ['Core'],
  exerciseIds: [1, 2],
});

describe('routine-schedule.util', () => {
  it('normalizes zones by trimming, dropping empties and deduping', () => {
    expect(normalizeZones([' Legs ', '', 'legs', 'Core'])).toEqual(['Legs', 'Core']);
  });

  it('assigns a column to another day', () => {
    const next = assignColumnDay([col('a')], 'a', 'Friday');
    expect(next[0].dayOfWeek).toBe('Friday');
  });

  it('returns columns unchanged when the source is unknown', () => {
    const cols = [col('a')];
    expect(duplicateColumnToDays(cols, 'missing', ['Friday'])).toBe(cols);
  });

  it('skips the source day and existing duplicates (idempotent)', () => {
    const cols = [col('a')];
    const once = duplicateColumnToDays(cols, 'a', ['Monday', 'Friday']);
    expect(once.map((c) => c.id)).toEqual(['a', 'a--friday']);
    const twice = duplicateColumnToDays(once, 'a', ['Monday', 'Friday']);
    expect(twice).toHaveLength(2);
  });

  it('copies exercises and zones without sharing references', () => {
    const [copy] = duplicateColumnToDays([col('a')], 'a', ['Friday']).filter((c) => c.id === 'a--friday');
    expect(copy.exerciseIds).toEqual([1, 2]);
    expect(copy.bodyZones).toEqual(['Core']);
    expect(copy.exerciseIds).not.toBe(col('a').exerciseIds);
  });

  it('filters by day and passes through All', () => {
    const cols = [col('a', 'Monday'), col('b', 'Friday')];
    expect(columnsForDay(cols, 'Friday').map((c) => c.id)).toEqual(['b']);
    expect(columnsForDay(cols, 'All')).toHaveLength(2);
  });

  it('groups columns under every weekday', () => {
    const grouped = groupColumnsByDay([col('a', 'Monday')]);
    expect(grouped.size).toBe(7);
    expect(grouped.get('Monday')?.map((c) => c.id)).toEqual(['a']);
    expect(grouped.get('Friday')).toEqual([]);
  });
});
