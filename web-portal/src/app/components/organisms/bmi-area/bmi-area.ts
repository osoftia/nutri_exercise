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
import { toPolyline } from '../../../core/charts/geometry/path';
import { buildLineChartLayout } from '../../../core/charts/builders/line.builder';
import {
  DEFAULT_PADDING,
  DataPoint,
  ReferenceBand,
  SeriesPoint,
} from '../../../core/charts/models/chart.model';
import { LocaleStore } from '../../../core/stores/locale.store';
import { translate } from '../../../core/i18n/translate';
import { ChartAxisX } from '../../charts/chart-axis-x/chart-axis-x';
import { ChartAxisY } from '../../charts/chart-axis-y/chart-axis-y';
import { ChartGrid } from '../../charts/chart-grid/chart-grid';
import { ChartLegend, LegendItem } from '../../charts/chart-legend/chart-legend';
import { ChartReferenceBands } from '../../charts/chart-reference-bands/chart-reference-bands';
import { ChartTooltip } from '../../charts/chart-tooltip/chart-tooltip';

const BMI_BANDS: ReferenceBand[] = [
  { from: 10, to: 18.5, label: 'bmi.underweight', tone: 'neutral' },
  { from: 18.5, to: 25, label: 'bmi.healthy', tone: 'success' },
  { from: 25, to: 30, label: 'bmi.overweight', tone: 'warning' },
  { from: 30, to: 40, label: 'bmi.obese', tone: 'danger' },
];

@Component({
  selector: 'app-bmi-area',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    TranslatePipe,
    ChartGrid,
    ChartAxisX,
    ChartAxisY,
    ChartReferenceBands,
    ChartTooltip,
    ChartLegend,
  ],
  templateUrl: './bmi-area.html',
  styleUrl: './bmi-area.scss',
})
export class BmiArea {
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly destroyRef = inject(DestroyRef);
  private readonly locale = inject(LocaleStore);

  readonly data = input.required<DataPoint[]>();
  readonly height = input(300);

  readonly width = observeWidth(this.host.nativeElement, this.destroyRef, 720);

  readonly legend: LegendItem[] = [{ label: 'bmi.series', variant: 'area' }];

  readonly layout = computed(() =>
    buildLineChartLayout(this.data(), this.width(), {
      padding: DEFAULT_PADDING,
      height: this.height(),
      fillArea: true,
      downsampleTarget: 200,
      bands: BMI_BANDS,
    }),
  );

  private readonly points = computed<SeriesPoint[]>(
    () => this.layout().series.find((series) => !series.dashed)?.points ?? [],
  );

  readonly hover = useNearestHover({
    points: () => this.points(),
    plot: () => this.layout().frame.plot,
    viewWidth: () => this.layout().frame.width,
    lines: (point) => [
      point.date,
      `${translate(this.locale.locale(), 'bmi.series')}: ${point.value} kg/m²`,
    ],
  });

  polyline(points: readonly SeriesPoint[]): string {
    return toPolyline(points);
  }
}
