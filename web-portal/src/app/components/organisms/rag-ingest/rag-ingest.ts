import { Component, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { DEFAULT_RAG_USER_ID, RagIngestResponse, toRagIngestRequest } from '../../../core/models/rag.model';
import { RagLoggerService } from '../../../core/services/rag-logger.service';
import { RagService } from '../../../core/services/rag.service';

/** Body-zone options accepted by `POST /api/rag/ingest`. */
export const BODY_ZONE_OPTIONS = [
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Legs',
  'Core',
  'Arms',
] as const;

export type BodyZoneOption = (typeof BODY_ZONE_OPTIONS)[number];

/**
 * Knowledge ingestion form for the RAG feature.
 *
 * Standalone component (Signals + `inject()`, no constructor injection)
 * wired to `POST {backendUrl}/api/rag/ingest`. Every document is linked
 * automatically to the default test user (`UserId = 1`) by the backend —
 * no login required. All state transitions are traced through
 * {@link RagLoggerService} (`[RAG-INFO]:` / `[RAG-ERROR]:`).
 */
@Component({
  selector: 'app-rag-ingest',
  templateUrl: './rag-ingest.html',
  styleUrl: './rag-ingest.scss',
})
export class RagIngest {
  private readonly ragService = inject(RagService);
  private readonly logger = inject(RagLoggerService);

  readonly title = signal<string>('');
  readonly content = signal<string>('');
  readonly bodyZone = signal<string>(BODY_ZONE_OPTIONS[5]);
  readonly loading = signal<boolean>(false);
  readonly result = signal<RagIngestResponse | null>(null);
  readonly error = signal<string | null>(null);

  readonly bodyZoneOptions: readonly string[] = BODY_ZONE_OPTIONS;
  readonly defaultUserId = DEFAULT_RAG_USER_ID;

  readonly isValid = computed(
    () => this.title().trim() !== '' && this.content().trim() !== '' && this.bodyZone().trim() !== '',
  );
  readonly canSubmit = computed(() => this.isValid() && !this.loading());
  readonly hasResult = computed(() => this.result() !== null);

  onTitleInput(event: Event): void {
    this.title.set((event.target as HTMLInputElement).value);
  }

  onContentInput(event: Event): void {
    this.content.set((event.target as HTMLTextAreaElement).value);
  }

  onBodyZoneChange(event: Event): void {
    this.bodyZone.set((event.target as HTMLSelectElement).value);
  }

  onSubmit(): void {
    if (this.loading()) {
      return;
    }
    if (!this.isValid()) {
      this.error.set('Title, Content and Body Zone are required.');
      this.logger.error('RAG ingestion skipped — empty form state.', {
        hasTitle: this.title().trim() !== '',
        hasContent: this.content().trim() !== '',
        hasBodyZone: this.bodyZone().trim() !== '',
      });
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    this.result.set(null);
    this.logger.info('RAG ingestion started.', {
      title: this.title().trim(),
      bodyZone: this.bodyZone().trim(),
      userId: DEFAULT_RAG_USER_ID,
    });

    this.ragService
      .ingest(toRagIngestRequest(this.title(), this.content(), this.bodyZone()))
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (response) => {
          this.result.set(response);
          this.logger.info('RAG ingestion form state changed to success.', {
            documentId: response.Id,
            userId: response.UserId,
          });
        },
        error: (err) => {
          this.error.set('Could not ingest the document.');
          this.logger.error('RAG ingestion form state changed to error.', err);
        },
      });
  }

  onReset(): void {
    this.title.set('');
    this.content.set('');
    this.bodyZone.set(BODY_ZONE_OPTIONS[5]);
    this.loading.set(false);
    this.result.set(null);
    this.error.set(null);
    this.logger.info('RAG ingestion form reset to defaults.');
  }
}
