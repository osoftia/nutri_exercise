import { Service, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import { RagService } from '../services/rag.service';
import { AuditLogStore } from './audit-log.store';

/**
 * Step 2 — Reactive store for the RAG Prompt Lab.
 *
 * Clean-architecture state container: all mutable UI state lives in signals,
 * side effects (HTTP + audit log) are orchestrated in {@link executeQuery}.
 * Dependencies are resolved with `inject()` — no constructor injection.
 */
@Service()
export class RagLabStore {
  private readonly ragService = inject(RagService);
  private readonly auditLog = inject(AuditLogStore);

  // ── User inputs (writable) ──────────────────────────────────────────
  readonly systemPrompt = signal<string>('');
  readonly temperature = signal<number>(0.7);
  readonly similarityThreshold = signal<number>(0.8);
  readonly query = signal<string>('');

  // ── Request state ───────────────────────────────────────────────────
  readonly isLoading = signal<boolean>(false);
  readonly results = signal<PromptLabResult | null>(null);
  readonly error = signal<string | null>(null);

  // ── Derived state ───────────────────────────────────────────────────
  readonly hasResults = computed(() => this.results() !== null);
  readonly latencyMs = computed(() => this.results()?.latencyMs ?? null);
  readonly tokensPerSecond = computed(() => this.results()?.tokensPerSecond ?? null);
  readonly topMatchScore = computed(() => topScore(this.results()));

  setSystemPrompt(value: string): void {
    this.systemPrompt.set(value);
  }

  setTemperature(value: number): void {
    this.temperature.set(value);
  }

  setSimilarityThreshold(value: number): void {
    this.similarityThreshold.set(value);
  }

  setQuery(value: string): void {
    this.query.set(value);
  }

  /**
   * Executes the RAG query against {@link RagService} and mirrors the
   * outcome into the state signals. Every completion — success or error —
   * appends an audit entry to {@link AuditLogStore} with the request
   * parameters plus response telemetry (`latencyMs`, top match score).
   */
  executeQuery(): void {
    if (this.query().trim() === '' || this.isLoading()) {
      return;
    }
    this.isLoading.set(true);
    this.error.set(null);

    const request: PromptLabRequest = {
      query: this.query(),
      systemPrompt: this.systemPrompt(),
      temperature: this.temperature(),
      similarityThreshold: this.similarityThreshold(),
    };

    this.ragService
      .runPromptLab(request)
      .pipe(finalize(() => this.isLoading.set(false)))
      .subscribe({
        next: (result) => {
          this.results.set(result);
          this.auditLog.log({
            ...request,
            latencyMs: result.latencyMs,
            topMatchScore: topScore(result),
            status: 'success',
          });
        },
        error: () => {
          this.error.set('Could not execute the RAG query.');
          this.auditLog.log({
            ...request,
            latencyMs: null,
            topMatchScore: null,
            status: 'error',
          });
        },
      });
  }

  reset(): void {
    this.systemPrompt.set('');
    this.temperature.set(0.7);
    this.similarityThreshold.set(0.8);
    this.query.set('');
    this.isLoading.set(false);
    this.results.set(null);
    this.error.set(null);
  }
}

function topScore(result: PromptLabResult | null): number | null {
  if (!result || result.matchedSources.length === 0) {
    return null;
  }
  return result.matchedSources.reduce((max, source) => Math.max(max, source.score), 0);
}
