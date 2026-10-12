import { createBandScale } from '../charts/geometry/band-scale';
import { formatShortDate } from '../charts/geometry/date';
import { toPolyline } from '../charts/geometry/path';
import { createLinearScale } from '../charts/geometry/scale';
import { buildTicks, niceCeil, niceDomain } from '../charts/geometry/ticks';
import { buildFrame, round2 } from '../charts/builders/frame.builder';
import {
  ChartBand,
  ChartBar,
  ChartLayout,
  ChartLineVertex,
  ClinicalEvolutionPayload,
} from '../models/clinical-evolution.model';

export const CHART_WIDTH = 880;
export const CHART_HEIGHT = 380;

const CHART_PADDING = { top: 32, right: 64, bottom: 52, left: 64 };
const TICK_SEGMENTS = 4;

export function buildChartLayout(payload: ClinicalEvolutionPayload): ChartLayout {
  const history = payload.historical_data;
  const projection = payload.projected_data;
  const totalPoints = Math.max(history.length + projection.length, 1);

  const frame = buildFrame(CHART_WIDTH, CHART_HEIGHT, CHART_PADDING);
  const { plot } = frame;
  const band = createBandScale(totalPoints, plot.x, plot.x + plot.width);

  const consumptionMax = niceCeil(Math.max(...history.map((point) => point.consumption), 1), TICK_SEGMENTS);
  const markerValues = [
    ...history.map((point) => point.actual_marker),
    ...projection.map((point) => point.projected_marker),
  ];
  const markerDomain = niceDomain(
    markerValues.length ? Math.min(...markerValues) : 0,
    markerValues.length ? Math.max(...markerValues) : 100,
    TICK_SEGMENTS,
  );
  const { min: markerMin, max: markerMax } = markerDomain;

  const yConsumption = createLinearScale([0, consumptionMax], [plot.y + plot.height, plot.y]);
  const yMarker = createLinearScale([markerMin, markerMax], [plot.y + plot.height, plot.y]);

  const bars: ChartBar[] = history.map((point, index) => {
    const width = band.step * 0.5;
    const top = yConsumption.map(point.consumption);
    return {
      key: point.date,
      x: round2(band.center(index) - width / 2),
      y: round2(top),
      width: round2(width),
      height: round2(plot.y + plot.height - top),
      centerX: round2(band.center(index)),
      date: point.date,
      consumption: point.consumption,
      actualMarker: point.actual_marker,
    };
  });

  const historicalVertices: ChartLineVertex[] = history.map((point, index) => ({
    x: round2(band.center(index)),
    y: round2(yMarker.map(point.actual_marker)),
    date: point.date,
    value: point.actual_marker,
    kind: 'historical',
  }));

  const lastHistoryIndex = history.length - 1;
  const projectionVertices: ChartLineVertex[] = [
    ...(lastHistoryIndex >= 0
      ? [
          {
            x: band.center(lastHistoryIndex),
            y: yMarker.map(history[lastHistoryIndex].actual_marker),
            date: history[lastHistoryIndex].date,
            value: history[lastHistoryIndex].actual_marker,
            kind: 'historical' as const,
          },
        ]
      : []),
    ...projection.map((point, index) => ({
      x: band.center(history.length + index),
      y: yMarker.map(point.projected_marker),
      date: point.date,
      value: point.projected_marker,
      kind: 'projected' as const,
    })),
  ].map((vertex) => ({ ...vertex, x: round2(vertex.x), y: round2(vertex.y) }));

  const bands: ChartBand[] = [
    ...history.map((point, index) => ({
      key: point.date,
      x: round2(band.left(index)),
      width: round2(band.step),
      centerX: round2(band.center(index)),
      label: formatShortDate(point.date),
      isFuture: false,
      consumption: point.consumption,
      marker: point.actual_marker,
    })),
    ...projection.map((point, index) => ({
      key: point.date,
      x: round2(band.left(history.length + index)),
      width: round2(band.step),
      centerX: round2(band.center(history.length + index)),
      label: formatShortDate(point.date),
      isFuture: true,
      consumption: null,
      marker: point.projected_marker,
    })),
  ];

  return {
    width: CHART_WIDTH,
    height: CHART_HEIGHT,
    plotLeft: plot.x,
    plotRight: plot.x + plot.width,
    plotTop: plot.y,
    plotBottom: plot.y + plot.height,
    plotWidth: plot.width,
    plotHeight: plot.height,
    bars,
    bands,
    historicalLine: toPolyline(historicalVertices),
    projectionLine: toPolyline(projectionVertices),
    historicalVertices,
    projectionVertices,
    consumptionTicks: buildTicks(
      { min: 0, max: consumptionMax, step: round2(consumptionMax / TICK_SEGMENTS) },
      (value) => yConsumption.map(value),
    ).map((tick) => ({ value: tick.value, y: tick.position, label: tick.label })),
    markerTicks: buildTicks(markerDomain, (value) => yMarker.map(value)).map((tick) => ({
      value: tick.value,
      y: tick.position,
      label: tick.label,
    })),
    todayX: round2(band.center(Math.max(lastHistoryIndex, 0))),
    markerMin,
    markerMax,
    consumptionMax,
  };
}
