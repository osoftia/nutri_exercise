import { Component, OnInit, computed, inject } from '@angular/core';

import { TranslatePipe } from '../../core/pipes/translate.pipe';
import { HealthEvolutionChart } from '../../components/organisms/health-evolution-chart/health-evolution-chart';
import { HealthRiskGauge } from '../../components/organisms/health-risk-gauge/health-risk-gauge';
import { ClinicalEvolutionStore } from '../../core/stores/clinical-evolution.store';

@Component({
  selector: 'app-clinical-evolution-page',
  imports: [HealthRiskGauge, HealthEvolutionChart, TranslatePipe],
  templateUrl: './clinical-evolution.page.html',
  styleUrl: './clinical-evolution.page.scss',
})
export class ClinicalEvolutionPage implements OnInit {
  readonly store = inject(ClinicalEvolutionStore);

  readonly currentMarker = computed(
    () => lastValue(this.store.payload()?.historical_data.map((point) => point.actual_marker) ?? []),
  );

  readonly projectedMarker = computed(
    () => lastValue(this.store.payload()?.projected_data.map((point) => point.projected_marker) ?? []),
  );

  readonly markerDelta = computed(() => {
    const current = this.currentMarker();
    const projected = this.projectedMarker();
    return current === null || projected === null ? null : projected - current;
  });

  readonly consumptionChange = computed(() => {
    const history = this.store.payload()?.historical_data ?? [];
    if (history.length < 2) {
      return null;
    }
    return history[history.length - 1].consumption - history[0].consumption;
  });

  readonly improved = computed(() => (this.markerDelta() ?? 0) <= 0);
  readonly consumptionUnit = computed(() => this.store.metric()?.consumption_unit ?? '');
  readonly markerUnit = computed(() => this.store.metric()?.marker_unit ?? '');

  ngOnInit(): void {
    this.store.load();
  }

  signed(value: number): string {
    return value > 0 ? `+${value}` : `${value}`;
  }
}

function lastValue(values: number[]): number | null {
  return values.length ? values[values.length - 1] : null;
}
