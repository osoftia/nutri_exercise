import { DayOfWeek, RoutineColumn } from '../models/routine-board.model';

export const WEEK_DAYS: DayOfWeek[] = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

export function normalizeZones(zones: string[]): string[] {
  const seen = new Map<string, string>();
  for (const zone of zones) {
    const label = zone.trim();
    const key = label.toLowerCase();
    if (label && !seen.has(key)) seen.set(key, label);
  }
  return [...seen.values()];
}

export function assignColumnDay(
  columns: RoutineColumn[],
  columnId: string,
  day: DayOfWeek,
): RoutineColumn[] {
  return columns.map((c) => (c.id === columnId ? { ...c, dayOfWeek: day } : c));
}

export function updateColumnZones(
  columns: RoutineColumn[],
  columnId: string,
  zones: string[],
): RoutineColumn[] {
  const bodyZones = normalizeZones(zones);
  return columns.map((c) => (c.id === columnId ? { ...c, bodyZones } : c));
}

export function duplicateColumnToDays(
  columns: RoutineColumn[],
  sourceId: string,
  days: DayOfWeek[],
): RoutineColumn[] {
  const src = columns.find((c) => c.id === sourceId);
  if (!src) return columns;
  const next = [...columns];
  for (const day of days) {
    if (day === src.dayOfWeek) continue;
    const id = `${src.id}--${day.toLowerCase()}`;
    if (next.some((c) => c.id === id)) continue;
    next.push({ ...src, id, dayOfWeek: day, exerciseIds: [...src.exerciseIds], bodyZones: [...src.bodyZones] });
  }
  return next;
}

export function columnsForDay(columns: RoutineColumn[], day: DayOfWeek | 'All'): RoutineColumn[] {
  if (day === 'All') return columns;
  return columns.filter((c) => c.dayOfWeek === day);
}

export function groupColumnsByDay(columns: RoutineColumn[]): Map<DayOfWeek, RoutineColumn[]> {
  const map = new Map<DayOfWeek, RoutineColumn[]>(WEEK_DAYS.map((d) => [d, []]));
  for (const col of columns) map.get(col.dayOfWeek)?.push(col);
  return map;
}
