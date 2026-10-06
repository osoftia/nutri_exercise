import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { MOCK_CONDITIONS } from '../../../core/mocks/medical-profile.data';
import { ConditionId } from '../../../core/models/medical-profile.model';
import { MedicalProfileStore } from '../../../core/stores/medical-profile.store';

@Component({
  selector: 'app-medical-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './medical-dashboard.html',
  styleUrl: './medical-dashboard.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MedicalDashboard {
  readonly store = inject(MedicalProfileStore);
  readonly conditions = MOCK_CONDITIONS;

  conditionName(id: ConditionId): string {
    return this.conditions.find((c) => c.id === id)?.name ?? id;
  }

  onSelectProfile(id: string): void {
    this.store.selectProfile(id);
  }

  onSelectCondition(id: ConditionId): void {
    this.store.setActiveCondition(id);
  }
}
