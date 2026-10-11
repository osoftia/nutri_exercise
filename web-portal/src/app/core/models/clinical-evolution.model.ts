export interface ClinicalMetricMeta {
  title: string;
  consumption_label: string;
  consumption_unit: string;
  marker_label: string;
  marker_unit: string;
}

export interface HistoricalPoint {
  date: string;
  consumption: number;
  actual_marker: number;
}

export interface ProjectionPoint {
  date: string;
  projected_marker: number;
}

export interface ClinicalEvolutionPayload {
  historical_data: HistoricalPoint[];
  projected_data: ProjectionPoint[];
  health_score: number;
  metric: ClinicalMetricMeta;
}

export type HealthRiskLevel = 'low' | 'medium' | 'high';

export function riskLevelFor(score: number): HealthRiskLevel {
  if (score < 20) {
    return 'low';
  }
  if (score < 50) {
    return 'medium';
  }
  return 'high';
}

export interface ChartBar {
  key: string;
  x: number;
  y: number;
  width: number;
  height: number;
  centerX: number;
  date: string;
  consumption: number;
  actualMarker: number;
}

export interface ChartBand {
  key: string;
  x: number;
  width: number;
  centerX: number;
  label: string;
  isFuture: boolean;
  consumption: number | null;
  marker: number;
}

export interface ChartLineVertex {
  x: number;
  y: number;
  date: string;
  value: number;
  kind: 'historical' | 'projected';
}

export interface ChartTick {
  value: number;
  y: number;
  label: string;
}

export interface ChartLayout {
  width: number;
  height: number;
  plotLeft: number;
  plotRight: number;
  plotTop: number;
  plotBottom: number;
  plotWidth: number;
  plotHeight: number;
  bars: ChartBar[];
  bands: ChartBand[];
  historicalLine: string;
  projectionLine: string;
  historicalVertices: ChartLineVertex[];
  projectionVertices: ChartLineVertex[];
  consumptionTicks: ChartTick[];
  markerTicks: ChartTick[];
  todayX: number;
  markerMin: number;
  markerMax: number;
  consumptionMax: number;
}
