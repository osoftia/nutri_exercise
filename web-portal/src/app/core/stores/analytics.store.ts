import { Service, computed, inject, signal } from '@angular/core';
import { forkJoin, finalize } from 'rxjs';

import { AiPerformance, TelemetrySnapshot } from '../models/analytics.model';
import { AiMetricsService } from '../services/ai-metrics.service';
import { TelemetryService } from '../services/telemetry.service';
import { DashboardStore } from './dashboard.store';

@Service()
export class AnalyticsStore {
  private readonly telemetryService = inject(TelemetryService);
  private readonly aiMetricsService = inject(AiMetricsService);
  private readonly dashboard = inject(DashboardStore);

  readonly telemetry = signal<TelemetrySnapshot | null>(null);
  readonly aiPerformance = signal<AiPerformance | null>(null);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);

  readonly feedbackDistribution = computed(() => {
    const analytics = this.dashboard.analytics();
    return {
      positive: analytics.positiveCount,
      negative: analytics.negativeCount,
      reviewed: analytics.reviewedCount,
    };
  });

  load(): void {
    if (this.loading()) {
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    forkJoin({
      telemetry: this.telemetryService.getSnapshot(),
      performance: this.aiMetricsService.getPerformance(),
    })
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: ({ telemetry, performance }) => {
          this.telemetry.set(telemetry);
          this.aiPerformance.set(performance);
        },
        error: () => this.error.set('Could not load analytics data.'),
      });
  }

  retry(): void {
    this.load();
  }

  reset(): void {
    this.telemetry.set(null);
    this.aiPerformance.set(null);
    this.loading.set(false);
    this.error.set(null);
  }
}