import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { MedicalProfileStore } from '../../../core/stores/medical-profile.store';
import { TranslatePipe } from '../../../core/pipes/translate.pipe';

@Component({
  selector: 'app-food-evaluator-grid',
  standalone: true,
  imports: [TranslatePipe],
  templateUrl: './food-evaluator-grid.html',
  styleUrl: './food-evaluator-grid.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FoodEvaluatorGrid {
  readonly store = inject(MedicalProfileStore);

  verdictClass(verdict: string): string {
    if (verdict === 'WARNING') return 'is-warning';
    if (verdict === 'RECOMMENDED') return 'is-recommended';
    return 'is-neutral';
  }
}
