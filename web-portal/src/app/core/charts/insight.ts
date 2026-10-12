import { translate } from '../i18n/translate';
import { AppLocale } from '../stores/locale.store';
import { ChartInsight, TooltipRow, TooltipRowKind } from './models/chart.model';

export function buildInsightRows(
  insight: ChartInsight | undefined,
  locale: AppLocale,
  maxChars = 34,
): TooltipRow[] {
  if (!insight) {
    return [];
  }
  const rows: TooltipRow[] = [];
  const push = (kind: TooltipRowKind, labelKey: string, text: string | undefined): void => {
    if (!text) {
      return;
    }
    const prefixed = `${translate(locale, labelKey)}: ${text}`;
    for (const line of wrapText(prefixed, maxChars)) {
      rows.push({ kind, text: line });
    }
  };
  push('risk', 'tooltip.risk', insight.risk);
  push('warning', 'tooltip.warning', insight.warning);
  push('advice', 'tooltip.advice', insight.advice);
  return rows;
}

export function wrapText(text: string, maxChars: number): string[] {
  const words = text.split(/\s+/).filter(Boolean);
  const lines: string[] = [];
  let current = '';
  for (const word of words) {
    if (!current) {
      current = word;
    } else if (`${current} ${word}`.length <= maxChars) {
      current = `${current} ${word}`;
    } else {
      lines.push(current);
      current = word;
    }
  }
  if (current) {
    lines.push(current);
  }
  return lines;
}
