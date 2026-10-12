import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { AxisTick, Rect } from '../../../core/charts/models/chart.model';

@Component({
  selector: 'g[chartGrid]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg width="100%" height="100%" overflow="visible">
      @for (tick of yTicks(); track tick.value) {
        <line
          class="chart-grid__line"
          [attr.x1]="plot().x"
          [attr.x2]="plot().x + plot().width"
          [attr.y1]="tick.position"
          [attr.y2]="tick.position"
        ></line>
      }
    </svg>
  `,
  styles: [
    `
      .chart-grid__line {
        stroke: var(--color-border);
        stroke-width: 1;
        opacity: 0.35;
      }
    `,
  ],
})
export class ChartGrid {
  readonly plot = input.required<Rect>();
  readonly yTicks = input.required<AxisTick[]>();
}
