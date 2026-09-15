import '@angular/compiler';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { of, Subject, throwError } from 'rxjs';

import { GenericExercise } from '../models/routine-board.model';
import { ExerciseRoutineService } from '../services/exercise-routine.service';
import { RoutineBoardStore } from './routine-board.store';

const ex = (id: number, name: string, muscleGroup: GenericExercise['muscleGroup'] = 'Chest'): GenericExercise => ({
  id,
  name,
  muscleGroup,
  bodyZones: [],
  sets: 3,
  reps: '10',
  restSeconds: 60,
  isCustom: false,
  createdAt: '',
});

function setup(serviceMock: {
  getCatalog: ReturnType<typeof vi.fn>;
  create: ReturnType<typeof vi.fn>;
  update: ReturnType<typeof vi.fn>;
  bulkDelete: ReturnType<typeof vi.fn>;
}): RoutineBoardStore {
  const injector = Injector.create([
    { provide: ExerciseRoutineService, useValue: serviceMock },
    RoutineBoardStore,
  ]);
  return runInInjectionContext(injector, () => injector.get(RoutineBoardStore));
}

describe('RoutineBoardStore (routine-board.feature)', () => {
  let service: {
    getCatalog: ReturnType<typeof vi.fn>;
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    bulkDelete: ReturnType<typeof vi.fn>;
  };
  let store: RoutineBoardStore;

  beforeEach(() => {
    service = {
      getCatalog: vi.fn().mockReturnValue(of([])),
      create: vi.fn(),
      update: vi.fn(),
      bulkDelete: vi.fn(),
    };
    store = setup(service);
  });

  it('board loads with muscle-group columns grouped by muscle', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'Bench Press', 'Chest'), ex(2, 'Row', 'Back'), ex(3, 'Squat', 'Legs')]));
    store.load();
    expect(store.columns()).toHaveLength(3);
    expect(store.exercises()).toHaveLength(3);
    expect(store.exercisesByColumn().get('col-chest')?.map((e) => e.id)).toEqual([1]);
    expect(store.loading()).toBe(false);
    expect(store.error()).toBeNull();
  });

  it('surfaces error when catalog fails', () => {
    service.getCatalog.mockReturnValue(throwError(() => new Error('down')));
    store.load();
    expect(store.error()).toBe('Could not load routine board.');
    expect(store.loading()).toBe(false);
  });

  it('reorders columns via cdkDropListGroup', () => {
    store.load();
    store.reorderColumns(0, 2);
    expect(store.columns().map((c) => c.id)).toEqual(['col-back', 'col-legs', 'col-chest']);
  });

  it('moves card within column via moveItemInArray', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'a'), ex(2, 'b'), ex(3, 'c')]));
    store.load();
    store.moveWithin('col-chest', 0, 2);
    expect(store.columns().find((c) => c.id === 'col-chest')?.exerciseIds).toEqual([2, 3, 1]);
  });

  it('moves card across columns via transferArrayItem', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'Bench Press', 'Chest')]));
    store.load();
    expect(store.columns().find((c) => c.id === 'col-back')?.exerciseIds).toEqual([]);
    store.transfer('col-chest', 'col-back', 0, 0);
    expect(store.columns().find((c) => c.id === 'col-chest')?.exerciseIds).toEqual([]);
    expect(store.columns().find((c) => c.id === 'col-back')?.exerciseIds).toEqual([1]);
  });

  it('inline editing persists to generic table', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'Bench')]));
    service.update.mockReturnValue(of(ex(1, 'Incline Press')));
    store.load();
    store.updateExercise(1, { name: 'Incline Press' });
    expect(service.update).toHaveBeenCalledWith(1, { name: 'Incline Press' });
    expect(store.exercises().find((e) => e.id === 1)?.name).toBe('Incline Press');
  });

  it('bulk delete removes selected cards from board and catalog', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'a'), ex(2, 'b')]));
    service.bulkDelete.mockReturnValue(of(void 0));
    store.load();
    store.toggleSelect(1);
    store.toggleSelect(2);
    expect(store.selectedCount()).toBe(2);
    store.bulkDelete();
    expect(service.bulkDelete).toHaveBeenCalledWith([1, 2]);
    expect(store.exercises()).toHaveLength(0);
    expect(store.hasSelection()).toBe(false);
  });

  it('add custom exercise persists and appears in backlog', () => {
    const created = ex(99, 'Hip Thrust', 'Glutes');
    service.create.mockReturnValue(of(created));
    store.load();
    store.createExercise({ name: 'Hip Thrust', muscleGroup: 'Glutes', sets: 3, reps: '12', restSeconds: 60 });
    expect(service.create).toHaveBeenCalled();
    expect(store.exercises().map((e) => e.id)).toContain(99);
  });

  it('tags a routine column with custom body zones', () => {
    store.load();
    store.updateColumnZones('col-chest', [' Legs ', '', 'Legs', 'Core']);
    expect(store.columns().find((c) => c.id === 'col-chest')?.bodyZones).toEqual(['Legs', 'Core']);
  });

  it('assigns a routine column to a day of the week', () => {
    store.load();
    expect(store.columnsByDay().get('Monday')?.map((c) => c.id)).toContain('col-chest');
    store.assignColumnToDay('col-chest', 'Wednesday');
    expect(store.columnsByDay().get('Monday')?.map((c) => c.id)).not.toContain('col-chest');
    expect(store.columnsByDay().get('Wednesday')?.map((c) => c.id)).toContain('col-chest');
  });

  it('duplicates a routine across multiple days with exercises and zones', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'Flow A'), ex(2, 'Flow B')]));
    store.load();
    store.updateColumnZones('col-chest', ['Legs', 'Core']);
    store.duplicateColumnToDays('col-chest', ['Monday', 'Wednesday', 'Friday']);
    expect(store.columns()).toHaveLength(5);
    const wed = store.columnsByDay().get('Wednesday') ?? [];
    const fri = store.columnsByDay().get('Friday') ?? [];
    expect(wed).toHaveLength(2);
    expect(fri.map((c) => c.id)).toContain('col-chest--friday');
    expect(wed.find((c) => c.id === 'col-chest--wednesday')?.exerciseIds).toEqual([1, 2]);
    expect(fri.find((c) => c.id === 'col-chest--friday')?.bodyZones).toEqual(['Legs', 'Core']);
  });

  it('filters visible columns by the active day', () => {
    store.load();
    store.setActiveDay('Monday');
    expect(store.visibleColumns().map((c) => c.id)).toEqual(['col-chest']);
    expect(store.columnsByDay().get('Monday')?.map((c) => c.id)).toEqual(['col-chest']);
    store.setActiveDay('All');
    expect(store.visibleColumns()).toHaveLength(3);
  });

  it('ignores a second load while already loading', () => {
    service.getCatalog.mockReturnValue(new Subject());
    store.load();
    store.load();
    expect(service.getCatalog).toHaveBeenCalledTimes(1);
  });

  it('parks exercises without a matching column in the first column', () => {
    service.getCatalog.mockReturnValue(of([ex(9, 'Hip Thrust', 'Glutes')]));
    store.load();
    expect(store.columns()[0].exerciseIds).toContain(9);
  });

  it('ignores transfer between unknown columns', () => {
    store.load();
    store.transfer('nope', 'missing', 0, 0);
    expect(store.columns()).toHaveLength(3);
  });

  it('surfaces an error when bulk delete fails', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'a')]));
    service.bulkDelete.mockReturnValue(throwError(() => new Error('no')));
    store.load();
    store.toggleSelect(1);
    store.bulkDelete();
    expect(store.error()).toBe('Could not delete exercises.');
    expect(store.exercises()).toHaveLength(1);
  });

  it('surfaces an error when inline editing fails', () => {
    service.getCatalog.mockReturnValue(of([ex(1, 'Bench')]));
    service.update.mockReturnValue(throwError(() => new Error('no')));
    store.load();
    store.updateExercise(1, { name: 'Other' });
    expect(store.error()).toBe('Could not update exercise.');
  });

  it('clears selection and resets the board to all days', () => {
    store.load();
    store.toggleSelect(1);
    store.clearSelection();
    expect(store.hasSelection()).toBe(false);
    store.setActiveDay('Friday');
    store.reset();
    expect(store.activeDay()).toBe('All');
    expect(store.visibleColumns()).toHaveLength(3);
  });
});
