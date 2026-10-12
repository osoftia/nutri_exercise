import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { ChartBand } from '../../../core/models/clinical-evolution.model';
import { ClinicalEvolutionStore } from '../../../core/stores/clinical-evolution.store';

interface ChartTooltip {
  x: number;
  y: number;
  width: number;
  height: number;
  band: ChartBand;
}

@Component({
  selector: 'app-health-evolution-chart',
  imports: [TranslatePipe],
  templateUrl: './health-evolution-chart.html',
  styleUrl: './health-evolution-chart.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HealthEvolutionChart {
  readonly store = inject(ClinicalEvolutionStore);
  readonly layout = this.store.chartLayout;
  readonly metric = this.store.metric;
  readonly hoveredBand = signal<ChartBand | null>(null);

  readonly tooltip = computed<ChartTooltip | null>(() => {
    const chart = this.layout();
    const band = this.hoveredBand();
    if (!chart || !band) {
      return null;
    }
    const width = 176;
    const height = 74;
    const x = clamp(band.centerX - width / 2, chart.plotLeft, chart.plotRight - width);
    return { x, y: chart.plotTop + 6, width, height, band };
  });

  hoverBand(band: ChartBand): void {
    this.hoveredBand.set(band);
  }

  clearHover(): void {
    this.hoveredBand.set(null);
  }

  isActiveBand(key: string): boolean {
    return this.hoveredBand()?.key === key;
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
