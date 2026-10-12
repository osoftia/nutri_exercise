import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { wrapText } from '../../../core/charts/insight';
import { translate } from '../../../core/i18n/translate';
import { MOCK_RAG_INSIGHTS } from '../../../core/mocks/mock-rag-insights.data';
import { ChartId } from '../../../core/models/health-metrics.model';
import { RagInsightRow } from '../../../core/models/rag-insights.model';
import { HealthDashboardUiStore } from '../../../core/stores/health-dashboard-ui.store';
import { LocaleStore } from '../../../core/stores/locale.store';
import { PdfLine, downloadPdf } from '../../../core/utils/pdf.util';

const CHART_LABEL_KEYS: Record<ChartId, string> = {
  'blood-pressure': 'metrics.bloodPressure.title',
  glucose: 'metrics.glucose.title',
  bmi: 'metrics.bmi.title',
  sleep: 'metrics.sleep.title',
  calories: 'metrics.calories.title',
};

@Component({
  selector: 'app-rag-insights',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  templateUrl: './rag-insights.html',
  styleUrl: './rag-insights.scss',
})
export class RagInsights {
  private readonly locale = inject(LocaleStore);
  private readonly ui = inject(HealthDashboardUiStore);

  readonly report = MOCK_RAG_INSIGHTS;
  readonly isDownloading = signal(false);

  isLinked(row: RagInsightRow): boolean {
    return row.chartId !== undefined;
  }

  chartLabelKey(chartId: ChartId): string {
    return CHART_LABEL_KEYS[chartId];
  }

  openChart(row: RagInsightRow): void {
    if (row.chartId) {
      this.ui.focusChart(row.chartId);
    }
  }

  download(): void {
    this.isDownloading.set(true);
    try {
      downloadPdf('health_rag_report.pdf', this.buildLines());
    } finally {
      this.isDownloading.set(false);
    }
  }

  private buildLines(): PdfLine[] {
    const locale = this.locale.locale();
    const lines: PdfLine[] = [];
    const push = (text: string, size: number, gap: number, bold = false): void => {
      const chunks = wrapText(text, 92);
      chunks.forEach((chunk, index) => {
        lines.push({ text: chunk, size, bold, gap: index === chunks.length - 1 ? gap : 2 });
      });
    };

    push(translate(locale, 'rag.report.title'), 20, 6, true);
    push(`${translate(locale, 'rag.report.generated')}: ${this.report.generatedAt}`, 10, 14);
    push(translate(locale, 'rag.report.summaryTitle'), 13, 4, true);
    push(translate(locale, this.report.summaryKey), 11, 14);

    for (const category of this.report.categories) {
      push(translate(locale, category.titleKey), 14, 6, true);
      for (const row of category.rows) {
        const severity = translate(locale, `rag.severity.${row.severity}`);
        push(`${translate(locale, row.labelKey)} - ${row.metric} [${severity}]`, 11, 2);
        push(translate(locale, row.detailKey), 10, 8);
      }
      lines.push({ text: '', size: 6, gap: 6 });
    }

    return lines;
  }
}
