import { describe, expect, it, vi } from 'vitest';
import { DestroyRef } from '@angular/core';

import { createBandScale } from './band-scale';
import { createLinearScale } from './scale';
import { buildTicks, formatTick, niceCeil, niceDomain, niceStep } from './ticks';
import { toAreaPath, toPolyline } from './path';
import { bucketAverage, lttbIndices } from './downsample';
import { nearestIndex } from './nearest';
import { buildGaugeArc } from './gauge';
import {
  daysBetween,
  formatMonthLabel,
  formatShortDate,
  parseDateUtc,
  startOfWeekMonday,
  toIsoDate,
  weekdayIndexMonday,
} from './date';
import { observeWidth } from '../resize';

describe('linear scale', () => {
  it('maps domain values into the pixel range and inverts them', () => {
    const scale = createLinearScale([0, 100], [0, 200]);
    expect(scale.map(50)).toBe(100);
    expect(scale.invert(100)).toBe(50);
    expect(scale.invert(scale.map(37))).toBeCloseTo(37, 6);
  });

  it('falls back to a unit span for degenerate domains', () => {
    const scale = createLinearScale([5, 5], [0, 10]);
    expect(Number.isFinite(scale.map(5))).toBe(true);
  });
});

describe('band scale', () => {
  it('computes step, left edge and center per band', () => {
    const band = createBandScale(4, 0, 400);
    expect(band.step).toBe(100);
    expect(band.left(2)).toBe(200);
    expect(band.center(2)).toBe(250);
  });

  it('never divides by zero for empty data', () => {
    expect(createBandScale(0, 0, 100).count).toBe(1);
  });
});

describe('ticks', () => {
  it('rounds up to a nice maximum covering the data', () => {
    expect(niceCeil(45, 4)).toBe(60);
    expect(niceStep(11.25)).toBe(15);
  });

  it('builds a symmetric nice domain', () => {
    expect(niceDomain(177, 232, 4)).toEqual({ min: 165, max: 240, step: 15 });
  });

  it('produces positioned, formatted ticks', () => {
    const ticks = buildTicks({ min: 0, max: 60, step: 15 }, (value) => value * 2);
    expect(ticks).toHaveLength(5);
    expect(ticks[0]).toEqual({ value: 0, position: 0, label: '0' });
    expect(ticks[4]).toEqual({ value: 60, position: 120, label: '60' });
    expect(formatTick(18.5, 0.1)).toBe('18.5');
  });
});

describe('path builders', () => {
  it('builds a polyline string', () => {
    expect(toPolyline([{ x: 0, y: 1 }, { x: 2, y: 3 }])).toBe('0,1 2,3');
  });

  it('builds a closed area path down to the baseline', () => {
    expect(toAreaPath([{ x: 0, y: 10 }, { x: 10, y: 20 }], 30)).toBe(
      'M0 10 L10 20 L10 30 L0 30 Z',
    );
    expect(toAreaPath([], 30)).toBe('');
  });
});

describe('downsampling', () => {
  const xs = Array.from({ length: 100 }, (_, index) => index);
  const ys = xs.map((value) => Math.sin(value / 5));

  it('returns every index when the threshold covers the data', () => {
    expect(lttbIndices(xs, ys, 100)).toHaveLength(100);
    expect(lttbIndices(xs, ys, 0)).toHaveLength(100);
  });

  it('keeps the endpoints and the requested count', () => {
    const indices = lttbIndices(xs, ys, 10);
    expect(indices).toHaveLength(10);
    expect(indices[0]).toBe(0);
    expect(indices[indices.length - 1]).toBe(99);
  });

  it('averages data into buckets', () => {
    const data = Array.from({ length: 10 }, (_, index) => ({ date: `2026-01-${index + 1}`, value: index }));
    const bucketed = bucketAverage(data, 5);
    expect(bucketed).toHaveLength(5);
    expect(bucketed[0].value).toBe(0.5);
  });

  it('leaves small datasets untouched', () => {
    const data = [{ date: '2026-01-01', value: 3 }];
    expect(bucketAverage(data, 5)).toEqual(data);
  });
});

describe('nearest index', () => {
  it('finds the closest value', () => {
    expect(nearestIndex([0, 10, 20], 12)).toBe(1);
    expect(nearestIndex([0, 10, 20], 19)).toBe(2);
  });

  it('returns -1 for an empty series', () => {
    expect(nearestIndex([], 5)).toBe(-1);
  });
});

describe('gauge geometry', () => {
  it('clamps the score and derives the dash offset', () => {
    const arc = buildGaugeArc(32, 84);
    expect(arc.fraction).toBeCloseTo(0.32, 6);
    expect(arc.dashOffset).toBeCloseTo(arc.circumference * 0.68, 6);
    expect(buildGaugeArc(150, 84).fraction).toBe(1);
    expect(buildGaugeArc(-10, 84).fraction).toBe(0);
  });
});

describe('date helpers', () => {
  it('parses and formats ISO dates in UTC', () => {
    expect(parseDateUtc('2026-08-17')).toBe(Date.UTC(2026, 7, 17));
    expect(formatShortDate('2026-08-17')).toBe('17 Aug');
    expect(formatMonthLabel('2026-08-17')).toBe('Aug');
    expect(toIsoDate(parseDateUtc('2026-08-17'))).toBe('2026-08-17');
  });

  it('aligns weeks to Monday', () => {
    expect(weekdayIndexMonday('2024-01-01')).toBe(0);
    expect(weekdayIndexMonday('2024-01-07')).toBe(6);
    const start = startOfWeekMonday('2024-01-03');
    expect(toIsoDate(start)).toBe('2024-01-01');
    expect(daysBetween(parseDateUtc('2024-01-01'), parseDateUtc('2024-01-08'))).toBe(7);
  });
});

describe('observeWidth', () => {
  it('falls back to a default width when ResizeObserver is unavailable', () => {
    const onDestroy = vi.fn();
    const destroyRef = { onDestroy } as unknown as DestroyRef;
    const width = observeWidth({} as HTMLElement, destroyRef, 512);
    expect(width()).toBe(512);
  });
});
