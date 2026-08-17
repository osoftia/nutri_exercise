import { Service, computed, inject, signal } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { finalize } from 'rxjs/operators';

import { AiInteraction } from '../models/interaction.model';
import { InteractionService } from '../services/interaction.service';

@Service()
export class DashboardStore {
  private readonly interactionService = inject(InteractionService);
  private readonly snackBar = inject(MatSnackBar);

  readonly interactions = signal<AiInteraction[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly submittingIds = signal<ReadonlySet<string>>(new Set());

  readonly total = computed(() => this.interactions().length);
  readonly hasFeedback = computed(
    () => this.interactions().filter((interaction) => interaction.feedbackText !== null).length,
  );

  load(): void {
    if (this.loading()) {
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    this.interactionService
      .getInteractions()
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (data) => this.interactions.set(data),
        error: () => this.error.set('Could not load AI-generated routines.'),
      });
  }

  retry(): void {
    this.load();
  }

  submitFeedback(id: string, text: string): void {
    this.submittingIds.update((ids) => new Set(ids).add(id));
    this.interactionService
      .updateFeedback(id, { feedbackText: text })
      .pipe(
        finalize(() => {
          this.submittingIds.update((ids) => {
            const next = new Set(ids);
            next.delete(id);
            return next;
          });
        }),
      )
      .subscribe({
        next: (updated) => {
          this.interactions.update((items) =>
            items.map((interaction) => (interaction.id === id ? updated : interaction)),
          );
          this.snackBar.open('Feedback saved.', 'OK', { duration: 3000 });
        },
        error: () => {
          this.snackBar.open('Could not save feedback. Please try again.', 'OK', {
            duration: 5000,
          });
        },
      });
  }

  reset(): void {
    this.interactions.set([]);
    this.loading.set(false);
    this.error.set(null);
    this.submittingIds.set(new Set());
  }
}