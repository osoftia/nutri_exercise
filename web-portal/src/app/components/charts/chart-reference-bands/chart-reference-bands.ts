import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { Rect, RenderedBand } from '../../../core/charts/models/chart.model';

@Component({
  selector: 'g[chartReferenceBands]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <svg width="100%" height="100%" overflow="visible">
      @for (band of bands(); track band.label) {
        <rect
          class="chart-reference-band"
          [attr.data-tone]="band.tone"
          [attr.x]="plot().x"
          [attr.y]="band.y"
          [attr.width]="plot().width"
          [attr.height]="band.height"
        ></rect>
        <text
          class="chart-reference-band__label"
          [attr.x]="plot().x + plot().width - 6"
          [attr.y]="band.y + 14"
          text-anchor="end"
        >{{ band.label | translate }}</text>
      }
    </svg>
  `,
  styles: [
    `
      .chart-reference-band {
        fill: var(--color-neutral);
        fill-opacity: 0.08;
      }
      .chart-reference-band[data-tone='success'] {
        fill: var(--color-success);
      }
      .chart-reference-band[data-tone='warning'] {
        fill: var(--color-warning);
      }
      .chart-reference-band[data-tone='danger'] {
        fill: var(--color-danger);
      }
      .chart-reference-band[data-tone='primary'] {
        fill: var(--color-primary);
      }
      .chart-reference-band__label {
        fill: var(--color-text-low);
        font-family: var(--font-family);
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }
    `,
  ],
})
export class ChartReferenceBands {
  readonly plot = input.required<Rect>();
  readonly bands = input.required<RenderedBand[]>();
}
