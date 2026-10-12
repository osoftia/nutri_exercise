import {
  MS_PER_DAY,
  daysBetween,
  formatMonthLabel,
  startOfWeekMonday,
  toIsoDate,
  weekdayIndexMonday,
} from '../geometry/date';
import { ChartFrame, ChartInsight, ChartPadding } from '../models/chart.model';
import { buildFrame, round2 } from './frame.builder';

export interface HeatmapDatum {
  date: string;
  value: number | null;
  insights?: ChartInsight;
}

export interface HeatmapSpec {
  padding: ChartPadding;
  height: number;
  rows: number;
  min: number;
  max: number;
  steps: number;
}

export interface HeatmapCell {
  x: number;
  y: number;
  width: number;
  height: number;
  date: string;
  value: number | null;
  level: number | null;
  column: number;
  row: number;
  insights?: ChartInsight;
}

export interface ColumnLabel {
  column: number;
  x: number;
  label: string;
}

export interface HeatmapLayout {
  frame: ChartFrame;
  cells: HeatmapCell[];
  columnLabels: ColumnLabel[];
  rows: number;
  steps: number;
  columns: number;
  cellWidth: number;
  cellHeight: number;
}

export function buildHeatmapLayout(
  data: readonly HeatmapDatum[],
  width: number,
  spec: HeatmapSpec,
): HeatmapLayout {
  const frame = buildFrame(width, spec.height, spec.padding);
  const { plot } = frame;
  if (data.length === 0) {
    return {
      frame,
      cells: [],
      columnLabels: [],
      rows: spec.rows,
      steps: spec.steps,
      columns: 0,
      cellWidth: 0,
      cellHeight: 0,
    };
  }

  const firstWeek = startOfWeekMonday(data[0].date);
  const lastWeek = startOfWeekMonday(data[data.length - 1].date);
  const columns = Math.max(Math.floor(daysBetween(firstWeek, lastWeek) / 7) + 1, 1);
  const cellWidth = plot.width / columns;
  const cellHeight = plot.height / spec.rows;
  const gap = 2;

  const cells: HeatmapCell[] = data.map((datum) => {
    const column = Math.floor(daysBetween(firstWeek, startOfWeekMonday(datum.date)) / 7);
    const row = weekdayIndexMonday(datum.date);
    return {
      x: round2(plot.x + column * cellWidth),
      y: round2(plot.y + row * cellHeight),
      width: round2(Math.max(cellWidth - gap, 1)),
      height: round2(Math.max(cellHeight - gap, 1)),
      date: datum.date,
      value: datum.value,
      level: datum.value === null ? null : levelFor(datum.value, spec),
      column,
      row,
      insights: datum.insights,
    };
  });

  const columnLabels: ColumnLabel[] = [];
  let lastMonth = '';
  for (let column = 0; column < columns; column += 1) {
    const weekStartMs = firstWeek + column * 7 * MS_PER_DAY;
    const month = formatMonthLabel(toIsoDate(weekStartMs));
    if (column === 0 || month !== lastMonth) {
      columnLabels.push({
        column,
        x: round2(plot.x + column * cellWidth + cellWidth / 2),
        label: month,
      });
      lastMonth = month;
    }
  }

  return { frame, cells, columnLabels, rows: spec.rows, steps: spec.steps, columns, cellWidth, cellHeight };
}

function levelFor(value: number, spec: HeatmapSpec): number {
  const span = spec.max - spec.min || 1;
  const normalized = (value - spec.min) / span;
  return Math.min(Math.max(Math.floor(normalized * spec.steps), 0), spec.steps - 1);
}
