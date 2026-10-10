import { RoutineColumn, GenericExercise } from '../models/routine-board.model';

// Local array helpers with CDK moveItemInArray/transferArrayItem semantics.
// Kept dependency-free so core utils stay testable under plain Vitest;
// UI components still use the real CDK directives for drag-drop.
function moveInArray<T>(list: T[], prevIndex: number, currIndex: number): void {
  const from = Math.max(0, Math.min(prevIndex, list.length - 1));
  const to = Math.max(0, Math.min(currIndex, list.length - 1));
  if (from === to) return;
  const [item] = list.splice(from, 1);
  list.splice(to, 0, item);
}

function transferInArrays<T>(src: T[], tgt: T[], prevIndex: number, currIndex: number): void {
  if (prevIndex < 0 || prevIndex >= src.length) return;
  const to = Math.max(0, Math.min(currIndex, tgt.length));
  const [item] = src.splice(prevIndex, 1);
  tgt.splice(to, 0, item);
}

export function reorderColumns(
  columns: RoutineColumn[],
  prevIndex: number,
  currIndex: number,
): RoutineColumn[] {
  const next = [...columns];
  moveInArray(next, prevIndex, currIndex);
  return next;
}

export function moveCardInColumn(
  column: RoutineColumn,
  prevIndex: number,
  currIndex: number,
): RoutineColumn {
  const ids = [...column.exerciseIds];
  moveInArray(ids, prevIndex, currIndex);
  return { ...column, exerciseIds: ids };
}

export function transferCard(
  source: RoutineColumn,
  target: RoutineColumn,
  prevIndex: number,
  currIndex: number,
): { source: RoutineColumn; target: RoutineColumn } {
  const srcIds = [...source.exerciseIds];
  const tgtIds = [...target.exerciseIds];
  transferInArrays(srcIds, tgtIds, prevIndex, currIndex);
  return {
    source: { ...source, exerciseIds: srcIds },
    target: { ...target, exerciseIds: tgtIds },
  };
}

export function exercisesForColumn(
  column: RoutineColumn,
  all: GenericExercise[],
): GenericExercise[] {
  const map = new Map(all.map((e) => [e.id, e]));
  return column.exerciseIds.map((id) => map.get(id)).filter((e): e is GenericExercise => !!e);
}

export function toColumnIdList(columns: RoutineColumn[]): string[] {
  return columns.map((c) => c.id);
}
