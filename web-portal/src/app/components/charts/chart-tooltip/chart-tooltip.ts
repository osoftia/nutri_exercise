import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'g[chartTooltip]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg width="100%" height="100%" overflow="visible">
      <g [attr.transform]="'translate(' + x() + ',' + y() + ')'" pointer-events="none">
        <rect class="chart-tooltip__box" [attr.width]="width()" [attr.height]="height()"></rect>
        @for (line of lines(); track $index; let index = $index) {
          <text
            class="chart-tooltip__line"
            [class.chart-tooltip__line--title]="index === 0"
            x="12"
            [attr.y]="20 + index * 18"
          >{{ line }}</text>
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
      .chart-tooltip__line {
        fill: var(--color-text-medium);
        font-family: var(--font-family);
        font-size: 13px;
        font-weight: 600;
      }
      .chart-tooltip__line--title {
        fill: var(--color-text-high);
        font-weight: 700;
      }
    `,
  ],
})
export class ChartTooltip {
  readonly x = input.required<number>();
  readonly y = input.required<number>();
  readonly width = input.required<number>();
  readonly height = input.required<number>();
  readonly lines = input.required<string[]>();
}
