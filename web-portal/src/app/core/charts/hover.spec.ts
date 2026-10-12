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

  it('selects the nearest point and exposes typed tooltip rows', () => {
    const hover = useNearestHover({
      points: () => POINTS,
      plot: () => ({ x: 0, y: 0, width: 200, height: 100 }),
      viewWidth: () => 200,
      lines: (point) => [point.date, `value ${point.value}`],
    });

    hover.onMove(moveEvent(105));
    expect(hover.hoveredIndex()).toBe(1);
    expect(hover.tooltip()?.rows).toEqual([
      { kind: 'title', text: '2024-01-02' },
      { kind: 'line', text: 'value 2' },
    ]);

    hover.clear();
    expect(hover.hoveredIndex()).toBe(-1);
    expect(hover.tooltip()).toBeNull();
  });

  it('appends insight rows supplied by the caller', () => {
    const hover = useNearestHover({
      points: () => POINTS,
      plot: () => ({ x: 0, y: 0, width: 200, height: 100 }),
      viewWidth: () => 200,
      lines: (point) => [point.date],
      insight: () => [{ kind: 'warning', text: 'Warning: elevated' }],
    });

    hover.onMove(moveEvent(5));
    const rows = hover.tooltip()?.rows ?? [];
    expect(rows).toHaveLength(2);
    expect(rows[1]).toEqual({ kind: 'warning', text: 'Warning: elevated' });
    expect(hover.tooltip()?.height).toBe(rows.length * 17 + 12);
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
