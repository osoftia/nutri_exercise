import { Component, inject } from '@angular/core';

import { RagLabStore } from '../../../core/stores/rag-lab.store';

/**
 * Step 3 — RAG Controls UI Panel ("Editorial Tech" brutalist).
 *
 * Standalone, signal-driven controls bound directly to {@link RagLabStore}.
 * No local state, no constructor injection, no ReactiveForms — every input
 * writes straight into the store on each `input` event.
 */
@Component({
  selector: 'app-rag-lab-controls',
  templateUrl: './rag-lab-controls.html',
  styleUrl: './rag-lab-controls.scss',
})
export class RagLabControls {
  readonly store = inject(RagLabStore);

  onSystemPromptInput(event: Event): void {
    this.store.setSystemPrompt((event.target as HTMLTextAreaElement).value);
  }

  onTemperatureInput(event: Event): void {
    this.store.setTemperature(clamp01((event.target as HTMLInputElement).valueAsNumber));
  }

  onThresholdInput(event: Event): void {
    this.store.setSimilarityThreshold(clamp01((event.target as HTMLInputElement).valueAsNumber));
  }

  onQueryInput(event: Event): void {
    this.store.setQuery((event.target as HTMLInputElement).value);
  }

  onExecute(): void {
    this.store.executeQuery();
  }

  onReset(): void {
    this.store.reset();
  }
}

function clamp01(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.min(1, Math.max(0, value));
}
