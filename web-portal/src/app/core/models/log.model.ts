export const LOG_LEVELS = [
  'All',
  'Verbose',
  'Debug',
  'Information',
  'Warning',
  'Error',
  'Fatal',
] as const;

export type LogLevelOption = (typeof LOG_LEVELS)[number];

export interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  exception: string | null;
  properties: Record<string, string>;
  sourceFile: string;
}

export interface LogQuery {
  startDate?: string;
  endDate?: string;
  logLevel?: string;
  tag?: string;
  pageNumber: number;
  pageSize: number;
}

export interface PagedLogResponse {
  items: LogEntry[];
  pageNumber: number;
  pageSize: number;
  totalCount: number;
}
