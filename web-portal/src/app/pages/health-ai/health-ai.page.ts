import { Component, OnInit, inject } from '@angular/core';

import { MedicalDashboard } from '../../components/organisms/medical-dashboard/medical-dashboard';
import { FoodEvaluatorGrid } from '../../components/organisms/food-evaluator-grid/food-evaluator-grid';
import { MedicalProfileStore } from '../../core/stores/medical-profile.store';

@Component({
  selector: 'app-health-ai-page',
  imports: [MedicalDashboard, FoodEvaluatorGrid],
  templateUrl: './health-ai.page.html',
  styleUrl: './health-ai.page.scss',
})
export class HealthAiPage implements OnInit {
  readonly store = inject(MedicalProfileStore);

  ngOnInit(): void {
    this.store.evaluateAll();
  }
}
