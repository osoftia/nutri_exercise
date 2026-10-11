import { Component, computed, inject } from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { HealthRiskLevel } from '../../../core/models/clinical-evolution.model';
import { ClinicalEvolutionStore } from '../../../core/stores/clinical-evolution.store';

const GAUGE_RADIUS = 84;

const RISK_COLORS: Record<HealthRiskLevel, string> = {
  low: 'var(--color-success)',
  medium: 'var(--color-warning)',
  high: 'var(--color-danger)',
};

const RISK_LABEL_KEYS: Record<HealthRiskLevel, string> = {
  low: 'evolution.low',
  medium: 'evolution.medium',
  high: 'evolution.high',
};

@Component({
  selector: 'app-health-risk-gauge',
  imports: [TranslatePipe],
  templateUrl: './health-risk-gauge.html',
  styleUrl: './health-risk-gauge.scss',
})
export class HealthRiskGauge {
  private readonly store = inject(ClinicalEvolutionStore);

  readonly radius = GAUGE_RADIUS;
  readonly score = this.store.healthScore;
  readonly level = this.store.riskLevel;
  readonly levelLabelKey = computed(() => RISK_LABEL_KEYS[this.level()]);
  readonly color = computed(() => RISK_COLORS[this.level()]);
  readonly circumference = 2 * Math.PI * GAUGE_RADIUS;
  readonly dashOffset = computed(
    () => this.circumference * (1 - Math.min(Math.max(this.score(), 0), 100) / 100),
  );
}
