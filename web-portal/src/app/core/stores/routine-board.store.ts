import { Injectable, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';
import { RoutineColumn, GenericExercise, DayOfWeek, CreateExercisePayload, UpdateExercisePayload } from '../models/routine-board.model';
import { ExerciseRoutineService } from '../services/exercise-routine.service';
import { reorderColumns, moveCardInColumn, transferCard, exercisesForColumn } from '../utils/routine-drag.util';
import { assignColumnDay, updateColumnZones, duplicateColumnToDays, columnsForDay, groupColumnsByDay } from '../utils/routine-schedule.util';

const DEFAULT_COLUMNS: RoutineColumn[] = [
  { id: 'col-chest', title: 'Chest', muscleGroup: 'Chest', dayOfWeek: 'Monday', bodyZones: [], exerciseIds: [] },
  { id: 'col-back', title: 'Back', muscleGroup: 'Back', dayOfWeek: 'Tuesday', bodyZones: [], exerciseIds: [] },
  { id: 'col-legs', title: 'Legs', muscleGroup: 'Legs', dayOfWeek: 'Wednesday', bodyZones: [], exerciseIds: [] },
];

@Injectable({ providedIn: 'root' })
export class RoutineBoardStore {
  private readonly service = inject(ExerciseRoutineService);

  readonly columns = signal<RoutineColumn[]>([...DEFAULT_COLUMNS]);
  readonly exercises = signal<GenericExercise[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly selectedIds = signal<ReadonlySet<number>>(new Set());
  readonly activeDay = signal<DayOfWeek | 'All'>('All');

  readonly selectedCount = computed(() => this.selectedIds().size);
  readonly hasSelection = computed(() => this.selectedIds().size > 0);
  readonly columnsByDay = computed(() => groupColumnsByDay(this.columns()));
  readonly visibleColumns = computed(() => columnsForDay(this.columns(), this.activeDay()));

  readonly exercisesByColumn = computed(() => {
    const all = this.exercises();
    const map = new Map<string, GenericExercise[]>();
    for (const col of this.columns()) map.set(col.id, exercisesForColumn(col, all));
    return map;
  });

  load(): void {
    if (this.loading()) return;
    this.loading.set(true);
    this.error.set(null);
    this.service.getCatalog().pipe(finalize(() => this.loading.set(false))).subscribe({
      next: (items) => this.hydrate(items),
      error: () => this.error.set('Could not load routine board.'),
    });
  }

  createExercise(payload: CreateExercisePayload, targetColumnId?: string): void {
    this.loading.set(true);
    this.service.create(payload).pipe(finalize(() => this.loading.set(false))).subscribe({
      next: (created) => {
        this.exercises.update((list) => [...list, created]);
        this.addToColumn(created.id, targetColumnId ?? this.resolveColumnFor(created.muscleGroup));
      },
      error: () => this.error.set('Could not create exercise.'),
    });
  }

  updateExercise(id: number, payload: UpdateExercisePayload): void {
    this.service.update(id, payload).subscribe({
      next: (updated) => this.exercises.update((list) => list.map((e) => (e.id === id ? updated : e))),
      error: () => this.error.set('Could not update exercise.'),
    });
  }

  bulkDelete(): void {
    const ids = [...this.selectedIds()];
    if (!ids.length) return;
    this.service.bulkDelete(ids).subscribe({
      next: () => {
        this.exercises.update((list) => list.filter((e) => !ids.includes(e.id)));
        this.columns.update((cols) => cols.map((c) => ({ ...c, exerciseIds: c.exerciseIds.filter((id) => !ids.includes(id)) })));
        this.selectedIds.set(new Set());
      },
      error: () => this.error.set('Could not delete exercises.'),
    });
  }

  toggleSelect(id: number): void {
    this.selectedIds.update((set) => {
      const next = new Set(set);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }

  clearSelection(): void { this.selectedIds.set(new Set()); }

  reorderColumns(prev: number, curr: number): void { this.columns.update((c) => reorderColumns(c, prev, curr)); }

  moveWithin(columnId: string, prev: number, curr: number): void {
    this.columns.update((cols) => cols.map((c) => (c.id === columnId ? moveCardInColumn(c, prev, curr) : c)));
  }

  transfer(sourceId: string, targetId: string, prev: number, curr: number): void {
    const cols = this.columns();
    const src = cols.find((c) => c.id === sourceId);
    const tgt = cols.find((c) => c.id === targetId);
    if (!src || !tgt) return;
    const { source, target } = transferCard(src, tgt, prev, curr);
    this.columns.update((all) => all.map((c) => (c.id === source.id ? source : c.id === target.id ? target : c)));
  }

  reset(): void {
    this.columns.set([...DEFAULT_COLUMNS]);
    this.exercises.set([]);
    this.loading.set(false);
    this.error.set(null);
    this.selectedIds.set(new Set());
    this.activeDay.set('All');
  }

  setActiveDay(day: DayOfWeek | 'All'): void { this.activeDay.set(day); }

  assignColumnToDay(columnId: string, day: DayOfWeek): void {
    this.columns.update((cols) => assignColumnDay(cols, columnId, day));
  }

  updateColumnZones(columnId: string, zones: string[]): void {
    this.columns.update((cols) => updateColumnZones(cols, columnId, zones));
  }

  duplicateColumnToDays(sourceId: string, days: DayOfWeek[]): void {
    this.columns.update((cols) => duplicateColumnToDays(cols, sourceId, days));
  }

  private hydrate(items: GenericExercise[]): void {
    this.exercises.set(items);
    this.columns.update((cols) => cols.map((col) => ({
      ...col,
      exerciseIds: items.filter((e) => e.muscleGroup === col.muscleGroup).map((e) => e.id),
    })));
    if (!items.length) return;
    const unassigned = items.filter((e) => !colsContain(this.columns(), e.id));
    if (unassigned.length) this.columns.update((cols) => cols.map((c, i) => i === 0 ? { ...c, exerciseIds: [...c.exerciseIds, ...unassigned.map((e) => e.id)] } : c));
  }

  private addToColumn(exerciseId: number, columnId: string): void {
    this.columns.update((cols) => cols.map((c) => c.id === columnId ? { ...c, exerciseIds: [...c.exerciseIds, exerciseId] } : c));
  }

  private resolveColumnFor(group: string): string {
    const found = this.columns().find((c) => c.muscleGroup === group);
    return found ? found.id : this.columns()[0].id;
  }
}

function colsContain(cols: RoutineColumn[], id: number): boolean {
  return cols.some((c) => c.exerciseIds.includes(id));
}
