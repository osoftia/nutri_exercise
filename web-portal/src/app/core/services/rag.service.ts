import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, delay, map, of, tap } from 'rxjs';

import { environment } from '../../../environments/environment';
import { mockPromptLabResponse, mockRagIngestResponse } from '../mocks/mock-prompt-lab.data';
import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import {
  RagIngestRequest,
  RagIngestResponse,
  RagRequest,
  RagResponse,
  fromRagResponse,
  toRagRequest,
} from '../models/rag.model';
import { RagLoggerService } from './rag-logger.service';

/**
 * HTTP client for the .NET 8 RAG endpoints
 * (`POST {backendUrl}/api/rag/query` and `POST {backendUrl}/api/rag/ingest`,
 * e.g. `http://192.168.1.2:5439/api/rag/query` on the Mac dev server).
 * Falls back to local mocks while `environment.useMocks` is true.
 *
 * Successful queries and ingestion actions are traced with `[RAG-INFO]:`;
 * failed HTTP calls with `[RAG-ERROR]:` (via {@link RagLoggerService}).
 */
@Service()
export class RagService {
  private readonly http = inject(HttpClient);
  private readonly logger = inject(RagLoggerService);
  private readonly queryUrl = `${environment.backendUrl}/api/rag/query`;
  private readonly ingestUrl = `${environment.backendUrl}/api/rag/ingest`;

  query(request: RagRequest): Observable<RagResponse> {
    if (environment.useMocks) {
      return of(this.mockResponse(request)).pipe(
        delay(800),
        tap((response) =>
          this.logger.info('RAG query served from mock.', {
            query: request.Query,
            latencyMs: response.Telemetry.LatencyMs,
          }),
        ),
      );
    }
    return this.http.post<RagResponse>(this.queryUrl, request).pipe(
      tap({
        next: (response) =>
          this.logger.info('RAG query executed successfully.', {
            latencyMs: response.Telemetry.LatencyMs,
            tokensPerSecond: response.Telemetry.TokensPerSecond,
            matches: response.MatchedSources.length,
          }),
        error: (err) => this.logger.error('RAG query HTTP call failed.', err),
      }),
    );
  }

  runPromptLab(request: PromptLabRequest): Observable<PromptLabResult> {
    if (environment.useMocks) {
      return of(mockPromptLabResponse(request.query)).pipe(
        delay(800),
        map((result) => ({
          ...result,
          matchedSources: [...result.matchedSources].sort((a, b) => b.score - a.score),
        })),
      );
    }
    return this.query(toRagRequest(request)).pipe(map(fromRagResponse));
  }

  /**
   * Ingests a custom document (`POST {backendUrl}/api/rag/ingest`).
   * The backend links the record to the default test user (`UserId = 1`)
   * automatically — no auth token is sent.
   */
  ingest(request: RagIngestRequest): Observable<RagIngestResponse> {
    if (environment.useMocks) {
      return of(mockRagIngestResponse(request)).pipe(
        delay(800),
        tap((response) =>
          this.logger.info('RAG ingestion served from mock.', {
            title: request.Title,
            userId: response.UserId,
          }),
        ),
      );
    }
    return this.http.post<RagIngestResponse>(this.ingestUrl, request).pipe(
      tap({
        next: (response) =>
          this.logger.info('RAG document ingested successfully.', {
            title: request.Title,
            documentId: response.Id,
            userId: response.UserId,
          }),
        error: (err) => this.logger.error('RAG ingestion HTTP call failed.', err),
      }),
    );
  }

  private mockResponse(request: RagRequest): RagResponse {
    const result = mockPromptLabResponse(request.Query);
    return {
      Answer: result.answer,
      MatchedSources: result.matchedSources.map((s) => ({
        Id: s.id,
        Title: s.title,
        Score: s.score,
      })),
      Telemetry: {
        LatencyMs: result.latencyMs,
        TokensPerSecond: result.tokensPerSecond,
      },
    };
  }
}
