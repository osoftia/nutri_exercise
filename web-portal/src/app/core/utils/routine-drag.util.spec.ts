import { describe, it, expect } from 'vitest';
import { RoutineColumn, GenericExercise } from '../models/routine-board.model';
import {
  reorderColumns,
  moveCardInColumn,
  transferCard,
  exercisesForColumn,
  toColumnIdList,
} from './routine-drag.util';

const col = (id: string, ids: number[]): RoutineColumn => ({
  id,
  title: id,
  muscleGroup: 'Chest',
  dayOfWeek: 'Monday',
  bodyZones: [],
  exerciseIds: ids,
});

describe('routine-drag.util', () => {
  it('reorders columns via moveItemInArray', () => {
    const cols = [col('a', [1]), col('b', [2]), col('c', [3])];
    expect(reorderColumns(cols, 0, 2).map((c) => c.id)).toEqual(['b', 'c', 'a']);
  });

  it('moves card within column', () => {
    const next = moveCardInColumn(col('a', [1, 2, 3]), 0, 2);
    expect(next.exerciseIds).toEqual([2, 3, 1]);
  });

  it('transfers card across columns', () => {
    const { source, target } = transferCard(col('a', [1, 2]), col('b', [3]), 0, 1);
    expect(source.exerciseIds).toEqual([2]);
    expect(target.exerciseIds).toEqual([3, 1]);
  });

  it('maps exercises for column', () => {
    const all: GenericExercise[] = [
      { id: 1, name: 'Bench', muscleGroup: 'Chest', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
      { id: 2, name: 'Squat', muscleGroup: 'Legs', bodyZones: [], sets: 3, reps: '10', restSeconds: 60, isCustom: false, createdAt: '' },
    ];
    expect(exercisesForColumn(col('a', [2, 1]), all).map((e) => e.id)).toEqual([2, 1]);
  });

  it('creates id list', () => {
    expect(toColumnIdList([col('a', []), col('b', [])])).toEqual(['a', 'b']);
  });

  it('keeps order when indices match and clamps out-of-range moves', () => {
    expect(reorderColumns([col('a', [1]), col('b', [2])], 0, 0).map((c) => c.id)).toEqual(['a', 'b']);
    expect(moveCardInColumn(col('a', [1, 2]), -5, 99).exerciseIds).toEqual([2, 1]);
  });

  it('ignores transfer from an empty position', () => {
    const { source, target } = transferCard(col('a', []), col('b', [1]), 0, 0);
    expect(source.exerciseIds).toEqual([]);
    expect(target.exerciseIds).toEqual([1]);
  });
});
