import {
  ChartBand,
  ChartBar,
  ChartLayout,
  ChartLineVertex,
  ChartTick,
  ClinicalEvolutionPayload,
} from '../models/clinical-evolution.model';

export const CHART_WIDTH = 880;
export const CHART_HEIGHT = 380;

const CHART_PADDING = { top: 32, right: 64, bottom: 52, left: 64 };
const TICK_SEGMENTS = 4;
const MONTHS = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

export function buildChartLayout(payload: ClinicalEvolutionPayload): ChartLayout {
  const history = payload.historical_data;
  const projection = payload.projected_data;
  const totalPoints = Math.max(history.length + projection.length, 1);

  const plotLeft = CHART_PADDING.left;
  const plotRight = CHART_WIDTH - CHART_PADDING.right;
  const plotTop = CHART_PADDING.top;
  const plotBottom = CHART_HEIGHT - CHART_PADDING.bottom;
  const plotWidth = plotRight - plotLeft;
  const plotHeight = plotBottom - plotTop;
  const bandWidth = plotWidth / totalPoints;
  const centerX = (index: number) => plotLeft + (index + 0.5) * bandWidth;

  const consumptionMax = niceScale(
    Math.max(...history.map((point) => point.consumption), 1),
    TICK_SEGMENTS,
  );

  const markerValues = [
    ...history.map((point) => point.actual_marker),
    ...projection.map((point) => point.projected_marker),
  ];
  const markerRawMin = markerValues.length ? Math.min(...markerValues) : 0;
  const markerRawMax = markerValues.length ? Math.max(...markerValues) : 100;
  const markerPadding = (markerRawMax - markerRawMin) * 0.15 || 5;
  const markerMin = Math.floor((markerRawMin - markerPadding) / 5) * 5;
  const markerMax = Math.max(
    Math.ceil((markerRawMax + markerPadding) / 5) * 5,
    markerMin + 5,
  );

  const yConsumption = (value: number) =>
    plotBottom - (value / consumptionMax) * plotHeight;
  const yMarker = (value: number) =>
    plotBottom - ((value - markerMin) / (markerMax - markerMin)) * plotHeight;

  const bars: ChartBar[] = history.map((point, index) => {
    const cx = centerX(index);
    const width = bandWidth * 0.5;
    const top = yConsumption(point.consumption);
    return {
      key: point.date,
      x: round2(cx - width / 2),
      y: round2(top),
      width: round2(width),
      height: round2(plotBottom - top),
      centerX: round2(cx),
      date: point.date,
      consumption: point.consumption,
      actualMarker: point.actual_marker,
    };
  });

  const historicalVertices: ChartLineVertex[] = history.map((point, index) => ({
    x: round2(centerX(index)),
    y: round2(yMarker(point.actual_marker)),
    date: point.date,
    value: point.actual_marker,
    kind: 'historical',
  }));

  const lastHistoryIndex = history.length - 1;
  const projectionVertices: ChartLineVertex[] = [
    ...(lastHistoryIndex >= 0
      ? [
          {
            x: centerX(lastHistoryIndex),
            y: yMarker(history[lastHistoryIndex].actual_marker),
            date: history[lastHistoryIndex].date,
            value: history[lastHistoryIndex].actual_marker,
            kind: 'historical' as const,
          },
        ]
      : []),
    ...projection.map((point, index) => ({
      x: centerX(history.length + index),
      y: yMarker(point.projected_marker),
      date: point.date,
      value: point.projected_marker,
      kind: 'projected' as const,
    })),
  ].map((vertex) => ({ ...vertex, x: round2(vertex.x), y: round2(vertex.y) }));

  const bands: ChartBand[] = [
    ...history.map((point, index) => ({
      key: point.date,
      x: round2(plotLeft + index * bandWidth),
      width: round2(bandWidth),
      centerX: round2(centerX(index)),
      label: formatShortDate(point.date),
      isFuture: false,
      consumption: point.consumption,
      marker: point.actual_marker,
    })),
    ...projection.map((point, index) => ({
      key: point.date,
      x: round2(plotLeft + (history.length + index) * bandWidth),
      width: round2(bandWidth),
      centerX: round2(centerX(history.length + index)),
      label: formatShortDate(point.date),
      isFuture: true,
      consumption: null,
      marker: point.projected_marker,
    })),
  ];

  return {
    width: CHART_WIDTH,
    height: CHART_HEIGHT,
    plotLeft,
    plotRight,
    plotTop,
    plotBottom,
    plotWidth,
    plotHeight,
    bars,
    bands,
    historicalLine: toPolyline(historicalVertices),
    projectionLine: toPolyline(projectionVertices),
    historicalVertices,
    projectionVertices,
    consumptionTicks: buildTicks(0, consumptionMax, yConsumption),
    markerTicks: buildTicks(markerMin, markerMax, yMarker),
    todayX: round2(centerX(Math.max(lastHistoryIndex, 0))),
    markerMin,
    markerMax,
    consumptionMax,
  };
}

function toPolyline(vertices: ChartLineVertex[]): string {
  return vertices.map((vertex) => `${vertex.x},${vertex.y}`).join(' ');
}

function buildTicks(min: number, max: number, y: (value: number) => number): ChartTick[] {
  const ticks: ChartTick[] = [];
  for (let index = 0; index <= TICK_SEGMENTS; index += 1) {
    const value = min + (max - min) * (index / TICK_SEGMENTS);
    ticks.push({ value: round2(value), y: round2(y(value)), label: formatTick(value) });
  }
  return ticks;
}

function niceScale(maxValue: number, segments: number): number {
  const safeMax = Math.max(maxValue, 1);
  const rawStep = safeMax / segments;
  const magnitude = Math.pow(10, Math.floor(Math.log10(rawStep)));
  const candidates = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];
  const step = (candidates.find((candidate) => candidate * magnitude >= rawStep) ?? 10) * magnitude;
  return round2(step * segments);
}

function formatShortDate(isoDate: string): string {
  const parts = isoDate.split('-');
  const month = Number(parts[1]);
  const day = Number(parts[2]);
  const monthLabel = MONTHS[month - 1] ?? '';
  return `${String(day).padStart(2, '0')} ${monthLabel}`.trim();
}

function formatTick(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(1);
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}
