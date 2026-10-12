import { formatShortDate } from '../geometry/date';
import { bucketAverage } from '../geometry/downsample';
import { toPolyline } from '../geometry/path';
import { createBandScale } from '../geometry/band-scale';
import { createLinearScale } from '../geometry/scale';
import { buildTicks, niceCeil } from '../geometry/ticks';
import {
  AxisTick,
  ChartFrame,
  ChartPadding,
  DataPoint,
  Point,
} from '../models/chart.model';
import { buildDateTicks, buildFrame, round2 } from './frame.builder';

export interface BarChartSpec {
  padding: ChartPadding;
  height: number;
  rollingWindow?: number;
  downsampleTarget?: number;
}

export interface BarRect {
  x: number;
  y: number;
  width: number;
  height: number;
  centerX: number;
  date: string;
  value: number;
}

export interface BarChartLayout {
  frame: ChartFrame;
  xTicks: AxisTick[];
  yTicks: AxisTick[];
  bars: BarRect[];
  rollingLine: string | null;
  valueMax: number;
}

export function buildBarChartLayout(
  rawData: readonly DataPoint[],
  width: number,
  spec: BarChartSpec,
): BarChartLayout {
  const frame = buildFrame(width, spec.height, spec.padding);
  const { plot } = frame;
  const data = bucketAverage(rawData, spec.downsampleTarget ?? 180);

  const valueMax = niceCeil(Math.max(...data.map((point) => point.value), 1), 4);
  const yScale = createLinearScale([0, valueMax], [plot.y + plot.height, plot.y]);
  const band = createBandScale(data.length, plot.x, plot.x + plot.width);
  const barWidth = band.step * 0.6;
  const baseline = plot.y + plot.height;

  const bars: BarRect[] = data.map((point, index) => {
    const top = yScale.map(point.value);
    return {
      x: round2(band.center(index) - barWidth / 2),
      y: round2(top),
      width: round2(barWidth),
      height: round2(baseline - top),
      centerX: round2(band.center(index)),
      date: point.date,
      value: point.value,
    };
  });

  const rollingWindow = spec.rollingWindow ?? 0;
  let rollingLine: string | null = null;
  if (rollingWindow > 1 && data.length >= rollingWindow) {
    const points: Point[] = [];
    for (let index = 0; index < data.length; index += 1) {
      const start = Math.max(0, index - rollingWindow + 1);
      const slice = data.slice(start, index + 1);
      const mean = slice.reduce((sum, point) => sum + point.value, 0) / slice.length;
      points.push({ x: round2(band.center(index)), y: round2(yScale.map(mean)) });
    }
    rollingLine = toPolyline(points);
  }

  return {
    frame,
    xTicks: buildDateTicks(
      data.map((point) => point.date),
      (index) => band.center(index),
      formatShortDate,
    ),
    yTicks: buildTicks(
      { min: 0, max: valueMax, step: round2(valueMax / 4) },
      (value) => yScale.map(value),
    ),
    bars,
    rollingLine,
    valueMax,
  };
}
