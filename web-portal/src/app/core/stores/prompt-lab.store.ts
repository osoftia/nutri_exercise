import { Service, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import { PromptLabService } from '../services/prompt-lab.service';

@Service()
export class PromptLabStore {
  private readonly promptLabService = inject(PromptLabService);

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
        next: (result) => this.result.set(result),
        error: () => this.error.set('Could not execute the prompt query.'),
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