import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  computed,
  inject,
  input,
} from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { observeWidth } from '../../../core/charts/resize';
import { useNearestHover } from '../../../core/charts/hover';
import { buildInsightRows } from '../../../core/charts/insight';
import { buildBarChartLayout } from '../../../core/charts/builders/bar.builder';
import { DEFAULT_PADDING, DataPoint, SeriesPoint } from '../../../core/charts/models/chart.model';
import { LocaleStore } from '../../../core/stores/locale.store';
import { translate } from '../../../core/i18n/translate';
import { ChartAxisX } from '../../charts/chart-axis-x/chart-axis-x';
import { ChartAxisY } from '../../charts/chart-axis-y/chart-axis-y';
import { ChartGrid } from '../../charts/chart-grid/chart-grid';
import { ChartLegend, LegendItem } from '../../charts/chart-legend/chart-legend';
import { ChartTooltip } from '../../charts/chart-tooltip/chart-tooltip';

@Component({
  selector: 'app-active-calories-bar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, ChartGrid, ChartAxisX, ChartAxisY, ChartTooltip, ChartLegend],
  templateUrl: './active-calories-bar.html',
  styleUrl: './active-calories-bar.scss',
})
export class ActiveCaloriesBar {
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly destroyRef = inject(DestroyRef);
  private readonly locale = inject(LocaleStore);

  readonly data = input.required<DataPoint[]>();
  readonly height = input(300);

  readonly width = observeWidth(this.host.nativeElement, this.destroyRef, 720);

  readonly legend: LegendItem[] = [
    { label: 'calories.bars', variant: 'bar' },
    { label: 'calories.rolling', variant: 'dashed' },
  ];

  readonly layout = computed(() =>
    buildBarChartLayout(this.data(), this.width(), {
      padding: DEFAULT_PADDING,
      height: this.height(),
      rollingWindow: 7,
      downsampleTarget: 180,
    }),
  );

  private readonly points = computed<SeriesPoint[]>(() =>
    this.layout().bars.map((bar) => ({
      x: bar.centerX,
      y: bar.y,
      date: bar.date,
      value: bar.value,
      insights: bar.insights,
    })),
  );

  readonly hover = useNearestHover({
    points: () => this.points(),
    plot: () => this.layout().frame.plot,
    viewWidth: () => this.layout().frame.width,
    lines: (point) => [
      point.date,
      `${translate(this.locale.locale(), 'calories.bars')}: ${point.value} kcal`,
    ],
    insight: (point) => buildInsightRows(point.insights, this.locale.locale()),
  });
}
