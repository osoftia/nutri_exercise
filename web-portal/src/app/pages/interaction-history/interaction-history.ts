import { Component, OnInit, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { AdminSidebar } from '../../components/organisms/admin-sidebar/admin-sidebar';
import { TopNavbar } from '../../components/organisms/top-navbar/top-navbar';
import { InteractionService } from '../../core/services/interaction';
import { Interaction } from '../../core/mocks/mock-interaction.data';

@Component({
  selector: 'app-interaction-history',
  imports: [AdminSidebar, TopNavbar, DatePipe],
  templateUrl: './interaction-history.html',
  styleUrl: './interaction-history.scss',
})
export class InteractionHistory implements OnInit {
  private readonly interactionService = inject(InteractionService);

  readonly interactions = signal<Interaction[]>([]);
  readonly loading = signal(true);
  readonly expandedIds = signal<string[]>([]);
  readonly submittingId = signal<string | null>(null);

  ngOnInit(): void {
    this.interactionService.getHistory().subscribe({
      next: (data) => this.interactions.set(data),
      complete: () => this.loading.set(false),
    });
  }

  isExpanded(id: string): boolean {
    return this.expandedIds().includes(id);
  }

  toggle(id: string): void {
    this.expandedIds.update((ids) =>
      ids.includes(id) ? ids.filter((x) => x !== id) : [...ids, id],
    );
  }

  onRate(id: string, isCorrect: boolean): void {
    if (this.submittingId() === id) {
      return;
    }
    this.submittingId.set(id);
    this.interactionService.submitFeedback(id, isCorrect).subscribe({
      next: () => {
        this.interactions.update((items) =>
          items.map((item) => (item.id === id ? { ...item, isCorrect } : item)),
        );
        this.submittingId.set(null);
      },
      error: () => this.submittingId.set(null),
    });
  }
}
