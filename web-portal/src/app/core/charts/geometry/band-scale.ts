export interface BandScale {
  readonly count: number;
  readonly step: number;
  readonly start: number;
  center(index: number): number;
  left(index: number): number;
}

export function createBandScale(count: number, start: number, end: number): BandScale {
  const safeCount = Math.max(count, 1);
  const step = (end - start) / safeCount;
  return {
    count: safeCount,
    step,
    start,
    center: (index: number) => start + (index + 0.5) * step,
    left: (index: number) => start + index * step,
  };
}
