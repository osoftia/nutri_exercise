import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';

import { TranslatePipe } from '../../core/pipes/translate.pipe';
import { HealthMetricsStore } from '../../core/stores/health-metrics.store';
import { ActiveCaloriesBar } from '../../components/organisms/active-calories-bar/active-calories-bar';
import { BloodPressureScatter } from '../../components/organisms/blood-pressure-scatter/blood-pressure-scatter';
import { BmiArea } from '../../components/organisms/bmi-area/bmi-area';
import { GlucoseLine } from '../../components/organisms/glucose-line/glucose-line';
import { SleepQualityHeatmap } from '../../components/organisms/sleep-quality-heatmap/sleep-quality-heatmap';

@Component({
  selector: 'app-health-metrics-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, BloodPressureScatter, GlucoseLine, BmiArea, SleepQualityHeatmap, ActiveCaloriesBar],
  templateUrl: './health-metrics.page.html',
  styleUrl: './health-metrics.page.scss',
})
export class HealthMetricsPage implements OnInit {
  readonly store = inject(HealthMetricsStore);

  ngOnInit(): void {
    this.store.load();
  }
}
