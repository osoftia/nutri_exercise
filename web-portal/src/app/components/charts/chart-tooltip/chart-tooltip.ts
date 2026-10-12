import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { TooltipRow } from '../../../core/charts/models/chart.model';

@Component({
  selector: 'g[chartTooltip]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg width="100%" height="100%" overflow="visible">
      <g [attr.transform]="'translate(' + x() + ',' + y() + ')'" pointer-events="none">
        <rect class="chart-tooltip__box" [attr.width]="width()" [attr.height]="height()"></rect>
        @for (row of rows(); track $index; let index = $index) {
          <text
            class="chart-tooltip__row"
            [attr.data-kind]="row.kind"
            x="12"
            [attr.y]="20 + index * 17"
          >{{ row.text }}</text>
        }
      </g>
    </svg>
  `,
  styles: [
    `
      .chart-tooltip__box {
        fill: var(--color-surface);
        stroke: var(--color-text-high);
        stroke-width: 1.5;
      }
      .chart-tooltip__row {
        fill: var(--color-text-medium);
        font-family: var(--font-family);
        font-size: 12px;
        font-weight: 600;
      }
      .chart-tooltip__row[data-kind='title'] {
        fill: var(--color-text-high);
        font-size: 13px;
        font-weight: 700;
      }
      .chart-tooltip__row[data-kind='risk'] {
        fill: var(--color-danger);
      }
      .chart-tooltip__row[data-kind='warning'] {
        fill: var(--color-warning);
      }
      .chart-tooltip__row[data-kind='advice'] {
        fill: var(--color-success);
      }
    `,
  ],
})
export class ChartTooltip {
  readonly x = input.required<number>();
  readonly y = input.required<number>();
  readonly width = input.required<number>();
  readonly height = input.required<number>();
  readonly rows = input.required<TooltipRow[]>();
}
