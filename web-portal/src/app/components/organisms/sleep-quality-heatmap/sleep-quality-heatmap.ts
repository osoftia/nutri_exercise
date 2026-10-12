import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  computed,
  inject,
  input,
  signal,
} from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { observeWidth } from '../../../core/charts/resize';
import {
  HeatmapCell,
  HeatmapDatum,
  buildHeatmapLayout,
} from '../../../core/charts/builders/heatmap.builder';
import { buildInsightRows } from '../../../core/charts/insight';
import { ChartPadding, TooltipRow } from '../../../core/charts/models/chart.model';
import { SleepRecord } from '../../../core/models/health-metrics.model';
import { LocaleStore } from '../../../core/stores/locale.store';
import { translate } from '../../../core/i18n/translate';
import { ChartTooltip } from '../../charts/chart-tooltip/chart-tooltip';

const HEATMAP_PADDING: ChartPadding = { top: 20, right: 20, bottom: 28, left: 56 };
const WEEKDAY_KEYS = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

interface HeatTooltip {
  x: number;
  y: number;
  width: number;
  height: number;
  rows: TooltipRow[];
}

@Component({
  selector: 'app-sleep-quality-heatmap',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, ChartTooltip],
  templateUrl: './sleep-quality-heatmap.html',
  styleUrl: './sleep-quality-heatmap.scss',
})
export class SleepQualityHeatmap {
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly destroyRef = inject(DestroyRef);
  private readonly locale = inject(LocaleStore);

  readonly data = input.required<SleepRecord[]>();
  readonly height = input(300);

  readonly width = observeWidth(this.host.nativeElement, this.destroyRef, 720);
  readonly weekdays = WEEKDAY_KEYS;
  readonly levels = [0, 1, 2, 3, 4];

  readonly layout = computed(() =>
    buildHeatmapLayout(this.toData(this.data()), this.width(), {
      padding: HEATMAP_PADDING,
      height: this.height(),
      rows: 7,
      min: 0,
      max: 100,
      steps: 5,
    }),
  );

  private readonly recordsByDate = computed(
    () => new Map(this.data().map((record) => [record.date, record])),
  );

  readonly hoveredCell = signal<HeatmapCell | null>(null);

  readonly tooltip = computed<HeatTooltip | null>(() => {
    const chart = this.layout();
    const cell = this.hoveredCell();
    if (!chart || !cell) {
      return null;
    }
    const record = this.recordsByDate().get(cell.date);
    const rows: TooltipRow[] = [
      { kind: 'title', text: cell.date },
      { kind: 'line', text: `${translate(this.locale.locale(), 'sleep.score')}: ${cell.value}` },
      {
        kind: 'line',
        text: `${translate(this.locale.locale(), 'sleep.hours')}: ${record?.hours ?? '—'} h`,
      },
      ...buildInsightRows(record?.insights, this.locale.locale()),
    ];
    const width = 240;
    const height = rows.length * 17 + 12;
    const plot = chart.frame.plot;
    const x = Math.min(
      Math.max(cell.x + cell.width / 2 - width / 2, plot.x),
      plot.x + plot.width - width,
    );
    return { x, y: plot.y + 6, width, height, rows };
  });

  onMove(event: MouseEvent): void {
    const chart = this.layout();
    if (!chart || chart.columns === 0) {
      return;
    }
    const element = event.currentTarget as SVGGraphicsElement;
    const bounds = element.getBoundingClientRect();
    const x = (event.clientX - bounds.left) * (chart.frame.width / (bounds.width || 1));
    const y = (event.clientY - bounds.top) * (chart.frame.height / (bounds.height || 1));
    const plot = chart.frame.plot;
    const column = Math.floor((x - plot.x) / chart.cellWidth);
    const row = Math.floor((y - plot.y) / chart.cellHeight);
    const cell = chart.cells.find((item) => item.column === column && item.row === row) ?? null;
    this.hoveredCell.set(cell);
  }

  clear(): void {
    this.hoveredCell.set(null);
  }

  private toData(records: readonly SleepRecord[]): HeatmapDatum[] {
    return records.map((record) => ({
      date: record.date,
      value: record.score,
      insights: record.insights,
    }));
  }
}
