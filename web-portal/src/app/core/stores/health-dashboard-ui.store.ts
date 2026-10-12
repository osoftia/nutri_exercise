import { Service, signal } from '@angular/core';

import { ChartId, HealthTab } from '../models/health-metrics.model';

const FOCUS_TIMEOUT_MS = 2800;

@Service()
export class HealthDashboardUiStore {
  readonly activeTab = signal<HealthTab>('dashboard');
  readonly focusedChartId = signal<ChartId | null>(null);
  private focusTimer: ReturnType<typeof setTimeout> | null = null;

  setTab(tab: HealthTab): void {
    this.activeTab.set(tab);
    if (tab !== 'dashboard') {
      this.clearFocus();
    }
  }

  focusChart(id: ChartId): void {
    this.focusedChartId.set(id);
    this.activeTab.set('dashboard');
    if (this.focusTimer !== null) {
      clearTimeout(this.focusTimer);
    }
    this.focusTimer = setTimeout(() => {
      this.focusedChartId.set(null);
      this.focusTimer = null;
    }, FOCUS_TIMEOUT_MS);
  }

  clearFocus(): void {
    if (this.focusTimer !== null) {
      clearTimeout(this.focusTimer);
      this.focusTimer = null;
    }
    this.focusedChartId.set(null);
  }
}
