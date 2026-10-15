import { LogEntry, LogQuery, PagedLogResponse } from '../models/log.model';

function entry(
  timestamp: string,
  level: string,
  message: string,
  exception: string | null = null,
  sourceFile = 'nutriexercise-20261001.json',
): LogEntry {
  return {
    timestamp,
    level,
    message,
    exception,
    properties: { SourceContext: 'NutriExercise.Infrastructure.Services' },
    sourceFile,
  };
}

export const mockLogs: LogEntry[] = [
  entry(
    '2026-10-01T12:05:00+00:00',
    'Error',
    '[OLLAMA-ERROR] Failed to reach Ollama at http://localhost:11434/api/generate for model llama3',
    'System.Net.Http.HttpRequestException: Connection refused (localhost:11434)\n   at System.Net.Sockets.Socket.Connect',
  ),
  entry(
    '2026-10-01T11:58:00+00:00',
    'Error',
    '[HTTP-ERROR] POST /api/Rag/query ClientIp=10.0.2.2 ElapsedMs=312: Connection refused',
    'System.Net.Http.HttpRequestException: Connection refused',
  ),
  entry('2026-10-01T11:30:00+00:00', 'Information', '[RAG-INFO]: Routine generated. Matches=3.'),
  entry(
    '2026-10-01T10:45:00+00:00',
    'Warning',
    '[RAG-INFO]: Vector search returned no matches above the threshold.',
  ),
  entry('2026-10-01T10:00:00+00:00', 'Information', '[HTTP-RESPONSE] POST /api/Rag/query StatusCode=200'),
  entry(
    '2026-09-30T21:12:00+00:00',
    'Error',
    '[RAG-ERROR]: pgvector similarity search failed. Query=creatina, Dimensions=768.',
    'Npgsql.NpgsqlException: Failed to connect to localhost:5432',
  ),
  entry('2026-09-30T20:40:00+00:00', 'Information', '[RAG-INFO]: Vector inserted. DocumentId=7f3'),
  entry(
    '2026-09-30T18:05:00+00:00',
    'Debug',
    '[HTTP-REQUEST] POST /api/Rag/query ClientIp=127.0.0.1 Body={ "query": "creatina" }',
  ),
  entry('2026-09-30T09:15:00+00:00', 'Information', '[RAG-INFO]: Starting up NutriExercise API...'),
];

function matchesLevel(log: LogEntry, level?: string): boolean {
  return !level || level === 'All' || log.level === level;
}

function matchesTag(log: LogEntry, tag?: string): boolean {
  return !tag || log.message.toLowerCase().includes(tag.toLowerCase());
}

function matchesRange(log: LogEntry, startDate?: string, endDate?: string): boolean {
  const timestamp = new Date(log.timestamp).getTime();

  if (startDate && timestamp < new Date(startDate).getTime()) {
    return false;
  }

  return !endDate || timestamp <= new Date(endDate).getTime();
}

export function queryMockLogs(query: LogQuery): PagedLogResponse {
  const filtered = mockLogs
    .filter((log) => matchesLevel(log, query.logLevel))
    .filter((log) => matchesTag(log, query.tag))
    .filter((log) => matchesRange(log, query.startDate, query.endDate))
    .sort((a, b) => b.timestamp.localeCompare(a.timestamp));

  const start = (query.pageNumber - 1) * query.pageSize;

  return {
    items: filtered.slice(start, start + query.pageSize),
    pageNumber: query.pageNumber,
    pageSize: query.pageSize,
    totalCount: filtered.length,
  };
}
