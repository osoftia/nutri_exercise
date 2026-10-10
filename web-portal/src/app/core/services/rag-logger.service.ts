import { Service } from '@angular/core';

/**
 * RAG-scoped structured console logger.
 *
 * Emits consistent prefixed lines for traceability (see ARCHITECTURE.md):
 * - `[RAG-INFO]:` — successful queries, ingestion actions, store state changes.
 * - `[RAG-ERROR]:` — failed HTTP calls, empty state exceptions, unexpected
 *   server responses.
 *
 * Provided in root via `@Service()` and consumed with `inject()`
 * (no constructor injection). The service holds no dependencies itself;
 * it is the single console owner for the RAG feature alongside the
 * global `TelemetryService`.
 */
@Service()
export class RagLoggerService {
  /** Successful queries, ingestion actions and store state changes. */
  info(message: string, context?: unknown): void {
    const line = `[RAG-INFO]: ${message}`;
    if (context === undefined) console.info(line);
    else console.info(line, context);
  }

  /** Failed HTTP calls, empty state exceptions, unexpected responses. */
  error(message: string, context?: unknown): void {
    const line = `[RAG-ERROR]: ${message}`;
    if (context === undefined) console.error(line);
    else console.error(line, context);
  }
}
