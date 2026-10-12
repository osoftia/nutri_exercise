import { formatShortDate, parseDateUtc } from '../geometry/date';
import { createLinearScale } from '../geometry/scale';
import { buildTicks, niceDomain } from '../geometry/ticks';
import {
  AxisTick,
  ChartFrame,
  ChartPadding,
  Point,
  ReferenceBand,
  RenderedBand,
  Tone,
} from '../models/chart.model';
import { buildDateTicks, buildFrame, round2 } from './frame.builder';

export interface ScatterDatum {
  date: string;
  primary: number;
  secondary: number;
}

export interface ScatterSpec {
  padding: ChartPadding;
  height: number;
  bands: ReferenceBand[];
}

export interface ScatterPoint extends Point {
  date: string;
  value: number;
  kind: 'primary' | 'secondary';
  tone: Tone;
}

export interface ScatterChartLayout {
  frame: ChartFrame;
  xTicks: AxisTick[];
  yTicks: AxisTick[];
  points: ScatterPoint[];
  bands: RenderedBand[];
  valueDomain: { min: number; max: number };
}

export function buildScatterChartLayout(
  data: readonly ScatterDatum[],
  width: number,
  spec: ScatterSpec,
): ScatterChartLayout {
  const frame = buildFrame(width, spec.height, spec.padding);
  const { plot } = frame;

  const times = data.map((point) => parseDateUtc(point.date));
  const values = data.flatMap((point) => [point.primary, point.secondary]);
  const bandValues = spec.bands.flatMap((band) => [band.from, band.to]);
  const allValues = values.length ? [...values, ...bandValues] : bandValues;
  const yDomain = niceDomain(
    allValues.length ? Math.min(...allValues) : 0,
    allValues.length ? Math.max(...allValues) : 100,
    4,
  );
  const yScale = createLinearScale([yDomain.min, yDomain.max], [plot.y + plot.height, plot.y]);
  const xScale = createLinearScale(
    times.length ? [times[0], times[times.length - 1]] : [0, 1],
    [plot.x, plot.x + plot.width],
  );

  const points: ScatterPoint[] = data.flatMap((datum, index) => [
    {
      x: round2(xScale.map(times[index])),
      y: round2(yScale.map(datum.primary)),
      date: datum.date,
      value: datum.primary,
      kind: 'primary' as const,
      tone: toneForValue(datum.primary, spec.bands),
    },
    {
      x: round2(xScale.map(times[index])),
      y: round2(yScale.map(datum.secondary)),
      date: datum.date,
      value: datum.secondary,
      kind: 'secondary' as const,
      tone: toneForValue(datum.secondary, spec.bands),
    },
  ]);

  const bands: RenderedBand[] = spec.bands.map((band) => ({
    ...band,
    y: round2(yScale.map(band.to)),
    height: round2(Math.abs(yScale.map(band.from) - yScale.map(band.to))),
  }));

  return {
    frame,
    xTicks: buildDateTicks(
      data.map((point) => point.date),
      (index) => xScale.map(times[index]),
      formatShortDate,
    ),
    yTicks: buildTicks(yDomain, (value) => yScale.map(value)),
    points,
    bands,
    valueDomain: { min: yDomain.min, max: yDomain.max },
  };
}

function toneForValue(value: number, bands: readonly ReferenceBand[]): Tone {
  for (const band of bands) {
    if (value >= band.from && value < band.to) {
      return band.tone;
    }
  }
  return 'neutral';
}
