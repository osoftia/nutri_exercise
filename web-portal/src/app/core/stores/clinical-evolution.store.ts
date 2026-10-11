import { Service, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import {
  ChartLayout,
  ClinicalEvolutionPayload,
  ClinicalMetricMeta,
  HealthRiskLevel,
  riskLevelFor,
} from '../models/clinical-evolution.model';
import { ClinicalEvolutionService } from '../services/clinical-evolution.service';
import { buildChartLayout } from '../utils/clinical-chart.util';

@Service()
export class ClinicalEvolutionStore {
  private readonly service = inject(ClinicalEvolutionService);

  readonly payload = signal<ClinicalEvolutionPayload | null>(null);
  readonly isLoading = signal(false);
  readonly error = signal<string | null>(null);

  readonly healthScore = computed(() => this.payload()?.health_score ?? 0);
  readonly riskLevel = computed<HealthRiskLevel>(() => riskLevelFor(this.healthScore()));
  readonly metric = computed<ClinicalMetricMeta | null>(() => this.payload()?.metric ?? null);
  readonly chartLayout = computed<ChartLayout | null>(() => {
    const payload = this.payload();
    return payload ? buildChartLayout(payload) : null;
  });

  load(): void {
    if (this.isLoading()) {
      return;
    }
    this.isLoading.set(true);
    this.error.set(null);
    this.service
      .load()
      .pipe(finalize(() => this.isLoading.set(false)))
      .subscribe({
        next: (payload) => this.payload.set(payload),
        error: () => this.error.set('Could not load clinical evolution data.'),
      });
  }
}
