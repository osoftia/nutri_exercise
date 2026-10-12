import { AxisTick } from '../models/chart.model';

export interface NiceDomain {
  min: number;
  max: number;
  step: number;
}

const CANDIDATES = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];

export function niceStep(rawStep: number): number {
  const magnitude = Math.pow(10, Math.floor(Math.log10(Math.max(rawStep, 1e-9))));
  return (CANDIDATES.find((candidate) => candidate * magnitude >= rawStep) ?? 10) * magnitude;
}

export function niceCeil(maxValue: number, segments: number): number {
  const safeMax = Math.max(maxValue, 1);
  return round2(niceStep(safeMax / segments) * segments);
}

export function niceDomain(min: number, max: number, segments: number): NiceDomain {
  if (max <= min) {
    max = min + 1;
  }
  const step = niceStep((max - min) / segments);
  return {
    min: round2(Math.floor(min / step) * step),
    max: round2(Math.ceil(max / step) * step),
    step: round2(step),
  };
}

export function buildTicks(
  domain: NiceDomain,
  toPosition: (value: number) => number,
): AxisTick[] {
  const count = Math.max(Math.round((domain.max - domain.min) / domain.step), 1);
  const ticks: AxisTick[] = [];
  for (let index = 0; index <= count; index += 1) {
    const value = round2(domain.min + index * domain.step);
    ticks.push({ value, position: round2(toPosition(value)), label: formatTick(value, domain.step) });
  }
  return ticks;
}

export function formatTick(value: number, step: number): string {
  if (step >= 1) {
    return String(Math.round(value));
  }
  return value.toFixed(step >= 0.1 ? 1 : 2);
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}
