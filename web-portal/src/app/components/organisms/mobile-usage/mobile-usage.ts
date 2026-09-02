import { Component, computed, input, output } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { TelemetryEvent, TelemetrySnapshot } from '../../../core/models/analytics.model';

@Component({
  selector: 'app-mobile-usage',
  imports: [MatProgressSpinnerModule, MatButtonModule],
  templateUrl: './mobile-usage.html',
  styleUrl: './mobile-usage.scss',
})
export class MobileUsage {
  readonly snapshot = input<TelemetrySnapshot | null>(null);
  readonly loading = input(false);
  readonly retry = output<void>();

  readonly activeSessions = computed(() => this.snapshot()?.activeWorkoutSessions ?? 0);
  readonly pendingSync = computed(() => this.snapshot()?.pendingSyncItems ?? 0);
  readonly lastSync = computed(() => this.snapshot()?.lastSyncAt ?? 'Never');
  readonly events = computed<TelemetryEvent[]>(() => this.snapshot()?.events ?? []);
}