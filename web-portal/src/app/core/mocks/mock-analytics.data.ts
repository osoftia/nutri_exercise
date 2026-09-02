import {
  AiPerformance,
  DbTable,
  DbTableRow,
  TelemetrySnapshot,
  VectorMatch,
} from '../models/analytics.model';

export const mockTelemetrySnapshot: TelemetrySnapshot = {
  activeWorkoutSessions: 3,
  pendingSyncItems: 2,
  lastSyncAt: '2026-08-18T08:00:00Z',
  events: [
    { id: 'evt-6', type: 'sync_completed', occurredAt: '2026-08-18T08:00:00Z' },
    { id: 'evt-5', type: 'session_started', occurredAt: '2026-08-18T07:55:00Z' },
    { id: 'evt-4', type: 'session_completed', occurredAt: '2026-08-18T07:40:00Z' },
    { id: 'evt-3', type: 'sync_failed', occurredAt: '2026-08-18T07:20:00Z' },
    { id: 'evt-2', type: 'session_started', occurredAt: '2026-08-18T07:00:00Z' },
    { id: 'evt-1', type: 'session_completed', occurredAt: '2026-08-18T06:30:00Z' },
  ],
};

export const mockAiPerformance: AiPerformance = {
  averageLatencyMs: 1842,
  averageTokensPerSecond: 38,
  totalGenerations: 8,
  samples: [
    { id: 'gen-1', generatedAt: '2026-08-17T10:00:00Z', latencyMs: 2400, tokensPerSecond: 30 },
    { id: 'gen-2', generatedAt: '2026-08-17T11:00:00Z', latencyMs: 1800, tokensPerSecond: 41 },
    { id: 'gen-3', generatedAt: '2026-08-17T12:00:00Z', latencyMs: 2200, tokensPerSecond: 35 },
    { id: 'gen-4', generatedAt: '2026-08-17T13:00:00Z', latencyMs: 1600, tokensPerSecond: 44 },
    { id: 'gen-5', generatedAt: '2026-08-17T14:00:00Z', latencyMs: 1900, tokensPerSecond: 37 },
    { id: 'gen-6', generatedAt: '2026-08-17T15:00:00Z', latencyMs: 1500, tokensPerSecond: 42 },
    { id: 'gen-7', generatedAt: '2026-08-17T16:00:00Z', latencyMs: 2100, tokensPerSecond: 33 },
    { id: 'gen-8', generatedAt: '2026-08-17T17:00:00Z', latencyMs: 1300, tokensPerSecond: 46 },
  ],
};

const embedding1536 = (seed: number): number[] =>
  Array.from({ length: 1536 }, (_, index) => Math.sin(seed + index) * 0.1);

export const mockDbTables: DbTable[] = [
  { name: 'routines', rowCount: 42, columns: ['id', 'name', 'day_of_week', 'description'], vectorColumns: [] },
  { name: 'diets', rowCount: 18, columns: ['id', 'name', 'meal_type', 'description'], vectorColumns: [] },
  { name: 'users', rowCount: 120, columns: ['id', 'name', 'email'], vectorColumns: [] },
  { name: 'interactions', rowCount: 64, columns: ['id', 'prompt', 'response', 'rating'], vectorColumns: [] },
  {
    name: 'routine_embeddings',
    rowCount: 24,
    columns: ['id', 'routine_id', 'embedding', 'preview'],
    vectorColumns: [{ name: 'embedding', dimensions: 1536 }],
  },
];

export const mockRowsByTable: Record<string, DbTableRow[]> = {
  routines: [
    { id: 1, name: 'Push Day', day_of_week: 'Monday', description: 'Bench press 4x8' },
    { id: 2, name: 'Pull Day', day_of_week: 'Tuesday', description: 'Deadlift 3x5' },
  ],
  routine_embeddings: [
    {
      id: 101,
      routine_id: 1,
      embedding: embedding1536(1),
      preview: 'Push strength and hypertrophy session targeting chest',
    },
    {
      id: 102,
      routine_id: 2,
      embedding: embedding1536(2),
      preview: 'Pull strength session targeting back and biceps',
    },
  ],
};

export function mockSemanticSearch(query: string): VectorMatch[] {
  const normalized = query.trim().toLowerCase();
  const base = normalized.includes('push') ? 0.92 : 0.6;
  return [
    { id: '101', score: base, preview: `Push strength session matching "${query}"` },
    { id: '102', score: base - 0.11, preview: `Pull session related to "${query}"` },
    { id: '103', score: base - 0.24, preview: `Lower-body session related to "${query}"` },
  ];
}