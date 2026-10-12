import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { AxisTick, Rect } from '../../../core/charts/models/chart.model';

@Component({
  selector: 'g[chartAxisY]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg width="100%" height="100%" overflow="visible">
      @for (tick of ticks(); track tick.value) {
        <text
          class="chart-axis-y__label"
          [attr.x]="side() === 'left' ? plot().x - 10 : plot().x + plot().width + 10"
          [attr.y]="tick.position + 4"
          [attr.text-anchor]="side() === 'left' ? 'end' : 'start'"
        >{{ tick.label }}</text>
      }
    </svg>
  `,
  styles: [
    `
      .chart-axis-y__label {
        fill: var(--color-text-low);
        font-family: var(--font-family);
        font-size: 12px;
        font-weight: 600;
      }
    `,
  ],
})
export class ChartAxisY {
  readonly plot = input.required<Rect>();
  readonly ticks = input.required<AxisTick[]>();
  readonly side = input<'left' | 'right'>('left');
}
