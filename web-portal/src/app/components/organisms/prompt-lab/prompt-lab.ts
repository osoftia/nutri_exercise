import { Component, inject } from '@angular/core';

import { PromptLabStore } from '../../../core/stores/prompt-lab.store';

@Component({
  selector: 'app-prompt-lab',
  imports: [],
  templateUrl: './prompt-lab.html',
  styleUrl: './prompt-lab.scss',
})
export class PromptLab {
  readonly store = inject(PromptLabStore);

  onSystemPromptInput(event: Event): void {
    this.store.setSystemPrompt((event.target as HTMLTextAreaElement).value);
  }

  onTemperatureInput(event: Event): void {
    this.store.setTemperature((event.target as HTMLInputElement).valueAsNumber);
  }

  onThresholdInput(event: Event): void {
    this.store.setSimilarityThreshold((event.target as HTMLInputElement).valueAsNumber);
  }

  onQueryInput(event: Event): void {
    this.store.setQuery((event.target as HTMLInputElement).value);
  }

  onRunQuery(): void {
    this.store.runQuery();
  }

  onReset(): void {
    this.store.reset();
  }
}