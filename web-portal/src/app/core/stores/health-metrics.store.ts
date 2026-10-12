import { Service, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { DataPoint } from '../charts/models/chart.model';
import {
  BloodPressureReading,
  HealthMetricsPayload,
  SleepRecord,
} from '../models/health-metrics.model';
import { HealthMetricsService } from '../services/health-metrics.service';

@Service()
export class HealthMetricsStore {
  private readonly service = inject(HealthMetricsService);

  readonly payload = signal<HealthMetricsPayload | null>(null);
  readonly isLoading = signal(false);
  readonly error = signal<string | null>(null);

  readonly bloodPressure = computed<BloodPressureReading[]>(
    () => this.payload()?.bloodPressure ?? [],
  );
  readonly glucose = computed<DataPoint[]>(() =>
    (this.payload()?.glucose ?? []).map((reading) => ({ date: reading.date, value: reading.value })),
  );
  readonly bmi = computed<DataPoint[]>(() =>
    (this.payload()?.bmi ?? []).map((reading) => ({ date: reading.date, value: reading.value })),
  );
  readonly sleep = computed<SleepRecord[]>(() => this.payload()?.sleep ?? []);
  readonly activeCalories = computed<DataPoint[]>(() =>
    (this.payload()?.activeCalories ?? []).map((record) => ({
      date: record.date,
      value: record.value,
    })),
  );

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
        error: () => this.error.set('Could not load health metrics data.'),
      });
  }
}
