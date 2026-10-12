import { ChartId } from './health-metrics.model';

export type RagCategoryId = 'lifestyle' | 'nutrition' | 'exercise' | 'diseases';

export type InsightSeverity = 'positive' | 'neutral' | 'watch' | 'risk';

export interface RagInsightRow {
  id: string;
  labelKey: string;
  detailKey: string;
  metric: string;
  severity: InsightSeverity;
  chartId?: ChartId;
}

export interface RagInsightCategory {
  id: RagCategoryId;
  titleKey: string;
  rows: RagInsightRow[];
}

export interface RagInsightsReport {
  generatedAt: string;
  summaryKey: string;
  categories: RagInsightCategory[];
}
