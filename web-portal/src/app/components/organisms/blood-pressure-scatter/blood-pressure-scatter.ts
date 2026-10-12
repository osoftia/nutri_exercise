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
import {
  ScatterDatum,
  buildScatterChartLayout,
} from '../../../core/charts/builders/scatter.builder';
import { DEFAULT_PADDING, ReferenceBand, SeriesPoint } from '../../../core/charts/models/chart.model';
import { BloodPressureReading } from '../../../core/models/health-metrics.model';
import { LocaleStore } from '../../../core/stores/locale.store';
import { translate } from '../../../core/i18n/translate';
import { ChartAxisX } from '../../charts/chart-axis-x/chart-axis-x';
import { ChartAxisY } from '../../charts/chart-axis-y/chart-axis-y';
import { ChartGrid } from '../../charts/chart-grid/chart-grid';
import { ChartLegend, LegendItem } from '../../charts/chart-legend/chart-legend';
import { ChartReferenceBands } from '../../charts/chart-reference-bands/chart-reference-bands';
import { ChartTooltip } from '../../charts/chart-tooltip/chart-tooltip';

const BP_BANDS: ReferenceBand[] = [
  { from: 140, to: 200, label: 'bp.stage2', tone: 'danger' },
  { from: 130, to: 140, label: 'bp.stage1', tone: 'warning' },
  { from: 120, to: 130, label: 'bp.elevated', tone: 'warning' },
  { from: 60, to: 120, label: 'bp.normal', tone: 'success' },
];

@Component({
  selector: 'app-blood-pressure-scatter',
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
  templateUrl: './blood-pressure-scatter.html',
  styleUrl: './blood-pressure-scatter.scss',
})
export class BloodPressureScatter {
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly destroyRef = inject(DestroyRef);
  private readonly locale = inject(LocaleStore);

  readonly data = input.required<BloodPressureReading[]>();
  readonly height = input(320);

  readonly width = observeWidth(this.host.nativeElement, this.destroyRef, 720);

  readonly legend: LegendItem[] = [
    { label: 'bp.systolic', variant: 'dot' },
    { label: 'bp.diastolic', variant: 'line' },
  ];

  readonly layout = computed(() =>
    buildScatterChartLayout(this.toData(this.data()), this.width(), {
      padding: DEFAULT_PADDING,
      height: this.height(),
      bands: BP_BANDS,
    }),
  );

  private readonly readingsByDate = computed(
    () => new Map(this.data().map((reading) => [reading.date, reading])),
  );

  private readonly systolicPoints = computed<SeriesPoint[]>(() =>
    this.layout()
      .points.filter((point) => point.kind === 'primary')
      .map((point) => ({ x: point.x, y: point.y, date: point.date, value: point.value })),
  );

  readonly hover = useNearestHover({
    points: () => this.systolicPoints(),
    plot: () => this.layout().frame.plot,
    viewWidth: () => this.layout().frame.width,
    lines: (point) => {
      const reading = this.readingsByDate().get(point.date);
      if (!reading) {
        return [point.date];
      }
      const systolic = translate(this.locale.locale(), 'bp.systolic');
      const diastolic = translate(this.locale.locale(), 'bp.diastolic');
      return [
        point.date,
        `${systolic}: ${reading.systolic} mmHg`,
        `${diastolic}: ${reading.diastolic} mmHg`,
      ];
    },
  });

  private toData(readings: readonly BloodPressureReading[]): ScatterDatum[] {
    return readings.map((reading) => ({
      date: reading.date,
      primary: reading.systolic,
      secondary: reading.diastolic,
    }));
  }
}
