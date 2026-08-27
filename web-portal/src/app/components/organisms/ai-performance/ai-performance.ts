import { Component, computed, input } from '@angular/core';
import { MatCardModule } from '@angular/material/card';

import { AiPerformance, FeedbackDistribution } from '../../../core/models/analytics.model';
import { BarChart, BarChartDatum } from '../../atoms/bar-chart/bar-chart';

@Component({
  selector: 'app-ai-performance',
  imports: [MatCardModule, BarChart],
  templateUrl: './ai-performance.html',
  styleUrl: './ai-performance.scss',
})
export class AiPerformanceComponent {
  readonly performance = input<AiPerformance | null>(null);
  readonly distribution = input<FeedbackDistribution>({ positive: 0, negative: 0, reviewed: 0 });

  readonly latencySamples = computed<BarChartDatum[]>(() =>
    (this.performance()?.samples ?? []).map((sample) => ({
      label: sample.id,
      value: sample.latencyMs,
    })),
  );

  readonly positivePercent = computed(() => {
    const { positive, reviewed } = this.distribution();
    return reviewed === 0 ? 0 : Math.round((positive / reviewed) * 100);
  });

  readonly negativePercent = computed(() => {
    const { negative, reviewed } = this.distribution();
    return reviewed === 0 ? 0 : Math.round((negative / reviewed) * 100);
  });
}