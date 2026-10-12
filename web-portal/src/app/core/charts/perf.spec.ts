import { describe, expect, it } from 'vitest';

import { buildLineChartLayout } from './builders/line.builder';
import { buildBarChartLayout } from './builders/bar.builder';
import { DEFAULT_PADDING, DataPoint } from './models/chart.model';

const DAY = 86_400_000;
const BASE = Date.UTC(2016, 0, 1);

function bigSeries(count: number): DataPoint[] {
  return Array.from({ length: count }, (_, index) => ({
    date: new Date(BASE + index * DAY).toISOString().slice(0, 10),
    value: 90 + 40 * Math.sin(index / 30),
  }));
}

describe('chart performance budgets', () => {
  const data = bigSeries(3650);

  it('downsamples a decade of daily points to a render budget', () => {
    const layout = buildLineChartLayout(data, 900, {
      padding: DEFAULT_PADDING,
      height: 320,
      downsampleTarget: 240,
    });
    expect(layout.series[0].points.length).toBeLessThanOrEqual(240);
  });

  it('caps bar nodes for dense data', () => {
    const layout = buildBarChartLayout(data, 900, {
      padding: DEFAULT_PADDING,
      height: 320,
      rollingWindow: 7,
      downsampleTarget: 180,
    });
    expect(layout.bars.length).toBeLessThanOrEqual(180);
  });

  it('builds a dense layout well within a frame budget', () => {
    const start = performance.now();
    for (let iteration = 0; iteration < 20; iteration += 1) {
      buildLineChartLayout(data, 900, {
        padding: DEFAULT_PADDING,
        height: 320,
        downsampleTarget: 240,
      });
    }
    expect(performance.now() - start).toBeLessThan(400);
  });
});
