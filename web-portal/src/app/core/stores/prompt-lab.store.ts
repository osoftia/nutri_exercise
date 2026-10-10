import { Service, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import { PromptLabService } from '../services/prompt-lab.service';
import { AuditLogStore } from './audit-log.store';

@Service()
export class PromptLabStore {
  private readonly promptLabService = inject(PromptLabService);
  private readonly auditLog = inject(AuditLogStore);

  readonly temperature = signal<number>(0.7);
  readonly similarityThreshold = signal<number>(0.8);
  readonly systemPrompt = signal<string>('');
  readonly query = signal<string>('');
  readonly loading = signal<boolean>(false);
  readonly result = signal<PromptLabResult | null>(null);
  readonly error = signal<string | null>(null);

  readonly latencyMs = computed(() => this.result()?.latencyMs ?? null);
  readonly tokensPerSecond = computed(() => this.result()?.tokensPerSecond ?? null);
  readonly hasResult = computed(() => this.result() !== null);
  readonly sortedSources = computed(() =>
    [...(this.result()?.matchedSources ?? [])].sort((a, b) => b.score - a.score),
  );

  setTemperature(value: number): void {
    this.temperature.set(value);
  }

  setSimilarityThreshold(value: number): void {
    this.similarityThreshold.set(value);
  }

  setSystemPrompt(value: string): void {
    this.systemPrompt.set(value);
  }

  setQuery(value: string): void {
    this.query.set(value);
  }

  runQuery(): void {
    if (this.query().trim() === '' || this.loading()) {
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    const request: PromptLabRequest = {
      query: this.query(),
      systemPrompt: this.systemPrompt(),
      temperature: this.temperature(),
      similarityThreshold: this.similarityThreshold(),
    };
    this.promptLabService
      .runQuery(request)
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (result) => {
          this.result.set(result);
          this.auditLog.log({ ...request, latencyMs: result.latencyMs, topMatchScore: topScore(result), status: 'success' });
        },
        error: () => {
          this.error.set('Could not execute the prompt query.');
          this.auditLog.log({ ...request, latencyMs: null, topMatchScore: null, status: 'error' });
        },
      });
  }

  reset(): void {
    this.temperature.set(0.7);
    this.similarityThreshold.set(0.8);
    this.systemPrompt.set('');
    this.query.set('');
    this.loading.set(false);
    this.result.set(null);
    this.error.set(null);
  }
}

function topScore(result: PromptLabResult): number | null {
  if (!result.matchedSources.length) return null;
  return result.matchedSources.reduce((max, s) => Math.max(max, s.score), 0);
}