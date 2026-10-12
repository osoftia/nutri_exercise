import { describe, expect, it } from 'vitest';

import { useNearestHover } from './hover';
import { SeriesPoint } from './models/chart.model';

const POINTS: SeriesPoint[] = [
  { x: 0, y: 10, date: '2024-01-01', value: 1 },
  { x: 100, y: 20, date: '2024-01-02', value: 2 },
  { x: 200, y: 30, date: '2024-01-03', value: 3 },
];

function moveEvent(clientX: number): MouseEvent {
  return {
    clientX,
    currentTarget: { getBoundingClientRect: () => ({ left: 0, width: 200 }) },
  } as unknown as MouseEvent;
}

describe('useNearestHover', () => {
  it('starts without a tooltip', () => {
    const hover = useNearestHover({
      points: () => POINTS,
      plot: () => ({ x: 0, y: 0, width: 200, height: 100 }),
      viewWidth: () => 200,
      lines: (point) => [point.date, `value ${point.value}`],
    });
    expect(hover.tooltip()).toBeNull();
  });

  it('selects the nearest point and exposes a tooltip', () => {
    const hover = useNearestHover({
      points: () => POINTS,
      plot: () => ({ x: 0, y: 0, width: 200, height: 100 }),
      viewWidth: () => 200,
      lines: (point) => [point.date, `value ${point.value}`],
    });

    hover.onMove(moveEvent(105));
    expect(hover.hoveredIndex()).toBe(1);
    expect(hover.tooltip()?.lines).toEqual(['2024-01-02', 'value 2']);

    hover.clear();
    expect(hover.hoveredIndex()).toBe(-1);
    expect(hover.tooltip()).toBeNull();
  });

  it('ignores moves when there are no points', () => {
    const hover = useNearestHover({
      points: () => [],
      plot: () => ({ x: 0, y: 0, width: 10, height: 10 }),
      viewWidth: () => 10,
      lines: () => [],
    });
    hover.onMove(moveEvent(5));
    expect(hover.hoveredIndex()).toBe(-1);
  });
});
