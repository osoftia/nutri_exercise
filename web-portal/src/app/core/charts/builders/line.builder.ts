import { formatShortDate, parseDateUtc } from '../geometry/date';
import { lttbIndices } from '../geometry/downsample';
import { toAreaPath } from '../geometry/path';
import { LinearScale, createLinearScale } from '../geometry/scale';
import { buildTicks, niceDomain } from '../geometry/ticks';
import {
  AxisTick,
  ChartFrame,
  ChartPadding,
  DataPoint,
  Marker,
  Rect,
  RenderedBand,
  SeriesPoint,
  Tone,
} from '../models/chart.model';
import { buildDateTicks, buildFrame, round2 } from './frame.builder';

export interface TargetBand {
  from: number;
  to: number;
  label: string;
  tone: Tone;
}

export interface LineChartSpec {
  padding: ChartPadding;
  height: number;
  bands?: TargetBand[];
  dashedFrom?: number;
  fillArea?: boolean;
  downsampleTarget?: number;
}

export interface LineSeriesLayout {
  id: string;
  points: SeriesPoint[];
  dashed: boolean;
}

export interface LineChartLayout {
  frame: ChartFrame;
  xTicks: AxisTick[];
  yTicks: AxisTick[];
  series: LineSeriesLayout[];
  area: string | null;
  bands: RenderedBand[];
  markers: Marker[];
  valueDomain: { min: number; max: number };
}

export function buildLineChartLayout(
  data: readonly DataPoint[],
  width: number,
  spec: LineChartSpec,
): LineChartLayout {
  const frame = buildFrame(width, spec.height, spec.padding);
  if (data.length === 0) {
    return emptyLayout(frame);
  }

  const { plot } = frame;
  const times = data.map((point) => parseDateUtc(point.date));
  const values = data.map((point) => point.value);
  const bandValues = (spec.bands ?? []).flatMap((band) => [band.from, band.to]);
  const domainValues = bandValues.length ? [...values, ...bandValues] : values;
  const yDomain = niceDomain(Math.min(...domainValues), Math.max(...domainValues), 4);
  const yScale = createLinearScale([yDomain.min, yDomain.max], [plot.y + plot.height, plot.y]);
  const xScale = createLinearScale(
    [times[0], times[times.length - 1]],
    [plot.x, plot.x + plot.width],
  );

  const { series, area } = buildSeries(data, times, values, xScale, yScale, spec, plot);

  return {
    frame,
    xTicks: buildDateTicks(
      data.map((point) => point.date),
      (index) => xScale.map(times[index]),
      formatShortDate,
    ),
    yTicks: buildTicks(yDomain, (value) => yScale.map(value)),
    series,
    area,
    bands: buildBands(spec.bands, yScale),
    markers: buildMarkers(spec.dashedFrom, data, times, xScale),
    valueDomain: { min: yDomain.min, max: yDomain.max },
  };
}

function buildSeries(
  data: readonly DataPoint[],
  times: readonly number[],
  values: readonly number[],
  xScale: LinearScale,
  yScale: LinearScale,
  spec: LineChartSpec,
  plot: Rect,
): { series: LineSeriesLayout[]; area: string | null } {
  const target = spec.downsampleTarget ?? 240;
  const toPoints = (indices: readonly number[]): SeriesPoint[] =>
    indices.map((index) => ({
      x: round2(xScale.map(times[index])),
      y: round2(yScale.map(values[index])),
      date: data[index].date,
      value: values[index],
      insights: data[index].insights,
    }));

  const split = spec.dashedFrom;
  if (split !== undefined && split >= 0 && split < data.length - 1) {
    const solidIndices = lttbIndices(
      times.slice(0, split + 1),
      values.slice(0, split + 1),
      Math.max(target - (data.length - split), 3),
    );
    const dashedIndices = lttbIndices(
      times.slice(split),
      values.slice(split),
      Math.max(data.length - split, 3),
    ).map((index) => index + split);
    const solidPoints = toPoints(solidIndices);
    return {
      series: [
        { id: 'solid', points: solidPoints, dashed: false },
        { id: 'dashed', points: toPoints(dashedIndices), dashed: true },
      ],
      area: spec.fillArea ? toAreaPath(solidPoints, plot.y + plot.height) : null,
    };
  }

  const points = toPoints(lttbIndices(times, values, target));
  return {
    series: [{ id: 'solid', points, dashed: false }],
    area: spec.fillArea ? toAreaPath(points, plot.y + plot.height) : null,
  };
}

function buildBands(
  bands: readonly TargetBand[] | undefined,
  yScale: LinearScale,
): RenderedBand[] {
  return (bands ?? []).map((band) => ({
    ...band,
    y: round2(yScale.map(band.to)),
    height: round2(Math.abs(yScale.map(band.from) - yScale.map(band.to))),
  }));
}

function buildMarkers(
  split: number | undefined,
  data: readonly DataPoint[],
  times: readonly number[],
  xScale: LinearScale,
): Marker[] {
  if (split === undefined || split < 0) {
    return [];
  }
  return [{ position: round2(xScale.map(times[split])), label: formatShortDate(data[split].date) }];
}

function emptyLayout(frame: ChartFrame): LineChartLayout {
  return {
    frame,
    xTicks: [],
    yTicks: [],
    series: [],
    area: null,
    bands: [],
    markers: [],
    valueDomain: { min: 0, max: 1 },
  };
}
