const MONTHS = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const MS_PER_DAY = 86_400_000;

export function parseDateUtc(isoDate: string): number {
  const [year, month, day] = isoDate.split('-').map(Number);
  return Date.UTC(year, (month ?? 1) - 1, day ?? 1);
}

export function formatShortDate(isoDate: string): string {
  const [, month, day] = isoDate.split('-').map(Number);
  return `${String(day).padStart(2, '0')} ${MONTHS[(month ?? 1) - 1] ?? ''}`.trim();
}

export function formatMonthLabel(isoDate: string): string {
  const [, month] = isoDate.split('-').map(Number);
  return MONTHS[(month ?? 1) - 1] ?? '';
}

export function weekdayIndexMonday(isoDate: string): number {
  const day = new Date(parseDateUtc(isoDate)).getUTCDay();
  return (day + 6) % 7;
}

export function startOfWeekMonday(isoDate: string): number {
  const ms = parseDateUtc(isoDate);
  const weekday = (new Date(ms).getUTCDay() + 6) % 7;
  return ms - weekday * MS_PER_DAY;
}

export function daysBetween(fromMs: number, toMs: number): number {
  return Math.round((toMs - fromMs) / MS_PER_DAY);
}

export function toIsoDate(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10);
}

export { MS_PER_DAY };
