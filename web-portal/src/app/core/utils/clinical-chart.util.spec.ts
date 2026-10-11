import { describe, expect, it } from 'vitest';

import { MOCK_CLINICAL_EVOLUTION } from '../mocks/mock-clinical-evolution.data';
import { CHART_HEIGHT, CHART_WIDTH, buildChartLayout } from './clinical-chart.util';

describe('buildChartLayout', () => {
  it('builds one bar per historical point and one band per point', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);

    expect(layout.bars).toHaveLength(8);
    expect(layout.bands).toHaveLength(12);
    expect(layout.historicalVertices).toHaveLength(8);
    expect(layout.projectionVertices).toHaveLength(5);
  });

  it('bridges the projection from the last historical marker', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);
    const bridge = layout.projectionVertices[0];
    const future = layout.projectionVertices.slice(1);
    const lastHistory = layout.historicalVertices[layout.historicalVertices.length - 1];

    expect(bridge.kind).toBe('historical');
    expect(bridge.value).toBe(198);
    expect(bridge.x).toBe(lastHistory.x);
    expect(future.every((vertex) => vertex.kind === 'projected')).toBe(true);
  });

  it('places today on the last historical band', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);
    const lastHistory = layout.historicalVertices[layout.historicalVertices.length - 1];

    expect(layout.todayX).toBe(lastHistory.x);
    expect(layout.todayX).toBe(layout.bands[7].centerX);
  });

  it('keeps bars inside the plot area', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);

    for (const bar of layout.bars) {
      expect(bar.y).toBeGreaterThanOrEqual(layout.plotTop);
      expect(bar.y + bar.height).toBeCloseTo(layout.plotBottom, 5);
      expect(bar.x).toBeGreaterThanOrEqual(layout.plotLeft);
      expect(bar.x + bar.width).toBeLessThanOrEqual(layout.plotRight);
    }
  });

  it('maps consumption ticks from the baseline to the top', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);
    const lastTick = layout.consumptionTicks[layout.consumptionTicks.length - 1];

    expect(layout.consumptionMax).toBe(60);
    expect(layout.consumptionTicks[0].value).toBe(0);
    expect(layout.consumptionTicks[0].y).toBeCloseTo(layout.plotBottom, 5);
    expect(lastTick.y).toBeCloseTo(layout.plotTop, 5);
  });

  it('produces one coordinate per vertex in the polylines', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);

    expect(layout.historicalLine.split(' ')).toHaveLength(8);
    expect(layout.projectionLine.split(' ')).toHaveLength(5);
  });

  it('exposes the canvas dimensions', () => {
    const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);

    expect(layout.width).toBe(CHART_WIDTH);
    expect(layout.height).toBe(CHART_HEIGHT);
  });

  it('handles an empty payload without NaN geometry', () => {
    const layout = buildChartLayout({
      historical_data: [],
      projected_data: [],
      health_score: 0,
      metric: MOCK_CLINICAL_EVOLUTION.metric,
    });

    expect(layout.bars).toHaveLength(0);
    expect(Number.isFinite(layout.todayX)).toBe(true);
    expect(layout.markerTicks.every((tick) => Number.isFinite(tick.y))).toBe(true);
  });
});
