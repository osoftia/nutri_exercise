import { AxisTick, ChartFrame, ChartPadding } from '../models/chart.model';

export function buildFrame(width: number, height: number, padding: ChartPadding): ChartFrame {
  const plotWidth = Math.max(width - padding.left - padding.right, 1);
  const plotHeight = Math.max(height - padding.top - padding.bottom, 1);
  return {
    width,
    height,
    plot: { x: padding.left, y: padding.top, width: plotWidth, height: plotHeight },
  };
}

export function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

export function buildDateTicks(
  dates: readonly string[],
  toPosition: (ms: number) => number,
  label: (isoDate: string) => string,
  maxTicks = 6,
): AxisTick[] {
  const count = dates.length;
  if (count === 0) {
    return [];
  }
  if (count === 1) {
    return [{ value: 0, position: round2(toPosition(0)), label: label(dates[0]) }];
  }

  const step = Math.max(Math.floor((count - 1) / Math.max(maxTicks - 1, 1)), 1);
  const ticks: AxisTick[] = [];
  for (let index = 0; index < count; index += step) {
    ticks.push({
      value: index,
      position: round2(toPosition(index)),
      label: label(dates[index]),
    });
  }
  const lastIndex = count - 1;
  const lastTick = ticks[ticks.length - 1];
  if (lastTick && lastTick.value !== lastIndex) {
    ticks.push({
      value: lastIndex,
      position: round2(toPosition(lastIndex)),
      label: label(dates[lastIndex]),
    });
  }
  return ticks;
}
