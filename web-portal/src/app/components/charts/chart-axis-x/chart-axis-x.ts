import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { AxisTick, Rect } from '../../../core/charts/models/chart.model';

@Component({
  selector: 'g[chartAxisX]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg width="100%" height="100%" overflow="visible">
      @for (tick of ticks(); track tick.value) {
        <text
          class="chart-axis-x__label"
          [attr.x]="tick.position"
          [attr.y]="plot().y + plot().height + 20"
          text-anchor="middle"
        >{{ tick.label }}</text>
      }
    </svg>
  `,
  styles: [
    `
      .chart-axis-x__label {
        fill: var(--color-text-low);
        font-family: var(--font-family);
        font-size: 12px;
        font-weight: 600;
      }
    `,
  ],
})
export class ChartAxisX {
  readonly plot = input.required<Rect>();
  readonly ticks = input.required<AxisTick[]>();
}
