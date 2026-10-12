import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';

export type LegendVariant = 'bar' | 'line' | 'dashed' | 'dot' | 'area';

export interface LegendItem {
  label: string;
  variant: LegendVariant;
}

@Component({
  selector: 'chart-legend',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <ul class="chart-legend">
      @for (item of items(); track item.label) {
        <li class="chart-legend__item">
          <span
            class="chart-legend__swatch"
            [attr.data-variant]="item.variant"
            aria-hidden="true"
          ></span>
          {{ item.label | translate }}
        </li>
      }
    </ul>
  `,
  styles: [
    `
      .chart-legend {
        display: flex;
        flex-wrap: wrap;
        gap: 18px;
        margin: 0;
        padding: 0;
        list-style: none;
        font-family: var(--font-family);
        font-size: var(--font-size-caption);
        font-weight: var(--font-weight-medium);
        letter-spacing: var(--letter-spacing-overline);
        text-transform: uppercase;
        color: var(--color-text-low);
      }
      .chart-legend__item {
        display: inline-flex;
        align-items: center;
        gap: 8px;
      }
      .chart-legend__swatch {
        display: inline-block;
        width: 22px;
        height: 12px;
      }
      .chart-legend__swatch[data-variant='bar'] {
        background-color: var(--color-block-primary);
      }
      .chart-legend__swatch[data-variant='line'] {
        height: 3px;
        background-color: var(--color-text-high);
      }
      .chart-legend__swatch[data-variant='dashed'] {
        height: 0;
        border-top: 3px dashed var(--color-success);
      }
      .chart-legend__swatch[data-variant='dot'] {
        width: 12px;
        height: 12px;
        border-radius: 50%;
        background-color: var(--color-accent);
      }
      .chart-legend__swatch[data-variant='area'] {
        height: 12px;
        background-color: var(--color-primary);
        opacity: 0.35;
      }
    `,
  ],
})
export class ChartLegend {
  readonly items = input.required<LegendItem[]>();
}
