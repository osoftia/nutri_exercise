import { Component, input } from '@angular/core';

import { AnalyticsMetrics } from '../../../../core/utils/analytics.util';

@Component({
  selector: 'app-analytics-summary',
  imports: [],
  templateUrl: './analytics-summary.html',
  styleUrl: './analytics-summary.scss',
})
export class AnalyticsSummary {
  readonly analytics = input.required<AnalyticsMetrics>();
}