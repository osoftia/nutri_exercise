export type AuditLogStatus = 'success' | 'error';

export interface AuditLogEntry {
  id: string;
  /** ISO-8601 timestamp of when the query completed. */
  timestamp: string;
  query: string;
  systemPrompt: string;
  temperature: number;
  similarityThreshold: number;
  /** Backend latency in ms, or null when the request failed. */
  latencyMs: number | null;
  /** Best pgvector match score (0–1), or null when there were no matches. */
  topMatchScore: number | null;
  status: AuditLogStatus;
}

export type AuditLogInput = Omit<AuditLogEntry, 'id' | 'timestamp'> & {
  id?: string;
  timestamp?: string;
};

export function createAuditLogEntry(input: AuditLogInput): AuditLogEntry {
  return {
    ...input,
    id: input.id ?? `audit-${Date.now()}-${Math.floor(Math.random() * 1e6)}`,
    timestamp: input.timestamp ?? new Date().toISOString(),
  };
}
