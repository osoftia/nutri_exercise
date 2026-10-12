import { describe, expect, it } from 'vitest';

import { buildFrame } from './frame.builder';
import { buildLineChartLayout } from './line.builder';
import { buildBarChartLayout } from './bar.builder';
import { buildScatterChartLayout, ScatterDatum } from './scatter.builder';
import { buildHeatmapLayout, HeatmapDatum } from './heatmap.builder';
import { DEFAULT_PADDING, DataPoint } from '../models/chart.model';

const BASE = Date.UTC(2024, 0, 1);
const DAY = 86_400_000;

function iso(offset: number): string {
  return new Date(BASE + offset * DAY).toISOString().slice(0, 10);
}

function series(count: number): DataPoint[] {
  return Array.from({ length: count }, (_, index) => ({
    date: iso(index),
    value: 100 - index,
  }));
}

describe('buildFrame', () => {
  it('subtracts padding from the canvas', () => {
    const frame = buildFrame(800, 400, { top: 20, right: 40, bottom: 30, left: 50 });
    expect(frame.plot).toEqual({ x: 50, y: 20, width: 710, height: 350 });
  });
});

describe('buildLineChartLayout', () => {
  it('builds a single solid series with axes and area', () => {
    const layout = buildLineChartLayout(series(20), 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      fillArea: true,
    });

    expect(layout.series).toHaveLength(1);
    expect(layout.series[0].dashed).toBe(false);
    expect(layout.series[0].points.length).toBeGreaterThan(2);
    expect(layout.area).not.toBeNull();
    expect(layout.yTicks.length).toBeGreaterThan(1);
    expect(layout.xTicks.length).toBeGreaterThan(1);
  });

  it('downsamples large series to the requested budget', () => {
    const layout = buildLineChartLayout(series(500), 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      downsampleTarget: 40,
    });
    expect(layout.series[0].points.length).toBeLessThanOrEqual(40);
  });

  it('splits historical and projected series at the dashed boundary', () => {
    const data = series(12);
    const layout = buildLineChartLayout(data, 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      dashedFrom: 8,
    });

    expect(layout.series).toHaveLength(2);
    expect(layout.series[0].dashed).toBe(false);
    expect(layout.series[1].dashed).toBe(true);
    expect(layout.series[1].points[0].date).toBe(data[8].date);
    expect(layout.markers).toHaveLength(1);
  });

  it('renders target bands and includes them in the domain', () => {
    const layout = buildLineChartLayout(series(10), 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      bands: [{ from: 70, to: 99, label: 'glucose.target', tone: 'success' }],
    });
    expect(layout.bands).toHaveLength(1);
    expect(layout.bands[0].height).toBeGreaterThan(0);
  });

  it('handles an empty dataset', () => {
    const layout = buildLineChartLayout([], 720, { padding: DEFAULT_PADDING, height: 300 });
    expect(layout.series).toHaveLength(0);
    expect(layout.xTicks).toHaveLength(0);
  });

  it('carries point insights through to the series points', () => {
    const data: DataPoint[] = [
      { date: iso(0), value: 10, insights: { warning: 'elevated' } },
      { date: iso(1), value: 20 },
    ];
    const layout = buildLineChartLayout(data, 720, { padding: DEFAULT_PADDING, height: 300 });
    expect(layout.series[0].points[0].insights).toEqual({ warning: 'elevated' });
    expect(layout.series[0].points[1].insights).toBeUndefined();
  });
});

describe('buildBarChartLayout', () => {
  it('builds bars and a rolling average line', () => {
    const layout = buildBarChartLayout(series(14), 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      rollingWindow: 3,
    });
    expect(layout.bars).toHaveLength(14);
    expect(layout.rollingLine).not.toBeNull();
    expect(layout.valueMax).toBeGreaterThan(0);
    for (const bar of layout.bars) {
      expect(bar.height).toBeGreaterThan(0);
    }
  });

  it('omits the rolling line when no window is requested', () => {
    const layout = buildBarChartLayout(series(5), 720, { padding: DEFAULT_PADDING, height: 300 });
    expect(layout.rollingLine).toBeNull();
  });
});

describe('buildScatterChartLayout', () => {
  const data: ScatterDatum[] = [
    { date: iso(0), primary: 130, secondary: 85 },
    { date: iso(1), primary: 118, secondary: 76 },
  ];

  it('creates two points per reading with category tones', () => {
    const layout = buildScatterChartLayout(data, 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      bands: [
        { from: 0, to: 120, label: 'bp.normal', tone: 'success' },
        { from: 120, to: 140, label: 'bp.stage1', tone: 'warning' },
      ],
    });

    expect(layout.points).toHaveLength(4);
    expect(layout.points[0].tone).toBe('warning');
    expect(layout.points[1].tone).toBe('success');
    expect(layout.bands).toHaveLength(2);
  });

  it('handles an empty dataset', () => {
    const layout = buildScatterChartLayout([], 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      bands: [],
    });
    expect(layout.points).toHaveLength(0);
  });
});

describe('buildHeatmapLayout', () => {
  const data: HeatmapDatum[] = Array.from({ length: 14 }, (_, index) => ({
    date: iso(index),
    value: index * 8,
  }));

  it('lays out a calendar grid with levels and month labels', () => {
    const layout = buildHeatmapLayout(data, 720, {
      padding: { top: 20, right: 20, bottom: 28, left: 56 },
      height: 300,
      rows: 7,
      min: 0,
      max: 100,
      steps: 5,
    });

    expect(layout.cells).toHaveLength(14);
    expect(layout.columns).toBe(2);
    expect(layout.cellWidth).toBeGreaterThan(0);
    expect(layout.columnLabels.length).toBeGreaterThanOrEqual(1);
    expect(layout.cells[0].level).toBe(0);
    expect(layout.cells[13].level).toBe(4);
  });

  it('handles an empty dataset', () => {
    const layout = buildHeatmapLayout([], 720, {
      padding: DEFAULT_PADDING,
      height: 300,
      rows: 7,
      min: 0,
      max: 100,
      steps: 5,
    });
    expect(layout.cells).toHaveLength(0);
    expect(layout.columns).toBe(0);
  });
});
