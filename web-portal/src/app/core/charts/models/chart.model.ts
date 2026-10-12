export type Tone = 'neutral' | 'primary' | 'success' | 'warning' | 'danger';

export interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface Point {
  x: number;
  y: number;
}

export interface ChartPadding {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export const DEFAULT_PADDING: ChartPadding = { top: 28, right: 52, bottom: 44, left: 52 };

export interface ChartFrame {
  width: number;
  height: number;
  plot: Rect;
}

export interface AxisTick {
  value: number;
  position: number;
  label: string;
}

export interface ReferenceBand {
  from: number;
  to: number;
  label: string;
  tone: Tone;
}

export interface RenderedBand extends ReferenceBand {
  y: number;
  height: number;
}

export interface Marker {
  position: number;
  label: string;
}

export interface DataPoint {
  date: string;
  value: number;
}

export interface SeriesPoint extends Point {
  date: string;
  value: number;
}
