export type TelemetryEventType =
  | 'session_started'
  | 'session_completed'
  | 'sync_completed'
  | 'sync_failed';

export interface TelemetryEvent {
  id: string;
  type: TelemetryEventType;
  occurredAt: string;
}

export interface TelemetrySnapshot {
  activeWorkoutSessions: number;
  pendingSyncItems: number;
  lastSyncAt: string | null;
  events: TelemetryEvent[];
}

export interface AiMetricSample {
  id: string;
  generatedAt: string;
  latencyMs: number;
  tokensPerSecond: number;
}

export interface AiPerformance {
  averageLatencyMs: number;
  averageTokensPerSecond: number;
  totalGenerations: number;
  samples: AiMetricSample[];
}

export interface VectorColumnInfo {
  name: string;
  dimensions: number;
}

export interface DbTable {
  name: string;
  rowCount: number;
  columns: string[];
  vectorColumns: VectorColumnInfo[];
}

export interface DbTableRow {
  [column: string]: unknown;
}

export interface VectorMatch {
  id: string;
  score: number;
  preview: string;
}

export interface FeedbackDistribution {
  positive: number;
  negative: number;
  reviewed: number;
}