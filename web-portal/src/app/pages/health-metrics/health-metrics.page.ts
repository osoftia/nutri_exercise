import { DOCUMENT } from '@angular/common';
import { ChangeDetectionStrategy, Component, OnInit, effect, inject } from '@angular/core';

import { TranslatePipe } from '../../core/pipes/translate.pipe';
import { HealthDashboardUiStore } from '../../core/stores/health-dashboard-ui.store';
import { HealthMetricsStore } from '../../core/stores/health-metrics.store';
import { ActiveCaloriesBar } from '../../components/organisms/active-calories-bar/active-calories-bar';
import { BloodPressureScatter } from '../../components/organisms/blood-pressure-scatter/blood-pressure-scatter';
import { BmiArea } from '../../components/organisms/bmi-area/bmi-area';
import { GlucoseLine } from '../../components/organisms/glucose-line/glucose-line';
import { RagInsights } from '../../components/organisms/rag-insights/rag-insights';
import { SleepQualityHeatmap } from '../../components/organisms/sleep-quality-heatmap/sleep-quality-heatmap';

@Component({
  selector: 'app-health-metrics-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    TranslatePipe,
    BloodPressureScatter,
    GlucoseLine,
    BmiArea,
    SleepQualityHeatmap,
    ActiveCaloriesBar,
    RagInsights,
  ],
  templateUrl: './health-metrics.page.html',
  styleUrl: './health-metrics.page.scss',
})
export class HealthMetricsPage implements OnInit {
  readonly store = inject(HealthMetricsStore);
  readonly ui = inject(HealthDashboardUiStore);
  private readonly document = inject(DOCUMENT);

  constructor() {
    effect(() => {
      const id = this.ui.focusedChartId();
      if (!id || this.ui.activeTab() !== 'dashboard') {
        return;
      }
      requestAnimationFrame(() => {
        this.document
          .getElementById(`chart-${id}`)
          ?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      });
    });
  }

  ngOnInit(): void {
    this.store.load();
  }
}
