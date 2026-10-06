import { Injectable, computed, inject, signal } from '@angular/core';

import { MOCK_CONDITIONS, MOCK_FOODS, MOCK_PROFILES, MOCK_SUGGESTIONS } from '../mocks/medical-profile.data';
import {
  AiSuggestion,
  ConditionId,
  EvaluatedFood,
} from '../models/medical-profile.model';
import { AiEvaluatorMockService } from '../services/ai-evaluator.mock.service';

@Injectable({ providedIn: 'root' })
export class MedicalProfileStore {
  private readonly evaluator = inject(AiEvaluatorMockService);

  readonly profiles = signal(MOCK_PROFILES);
  readonly foods = signal(MOCK_FOODS);
  readonly selectedProfile = signal(MOCK_PROFILES[0]);
  readonly activeConditionId = signal<ConditionId>(MOCK_PROFILES[0].conditionIds[0]);
  readonly evaluatedFoods = signal<EvaluatedFood[]>([]);
  readonly suggestions = signal<AiSuggestion[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);

  readonly warnings = computed(() => this.evaluatedFoods().filter((e) => e.verdict === 'WARNING'));
  readonly recommended = computed(() => this.evaluatedFoods().filter((e) => e.verdict === 'RECOMMENDED'));
  readonly activeCondition = computed(
    () => MOCK_CONDITIONS.find((c) => c.id === this.activeConditionId()) ?? MOCK_CONDITIONS[0],
  );
  readonly suggestionsForActive = computed(() =>
    this.suggestions().filter((s) => s.context === this.activeConditionId() || s.context === 'general'),
  );

  constructor() {
    this.evaluateAll();
  }

  selectProfile(id: string): void {
    const found = this.profiles().find((p) => p.id === id);
    if (!found) return;
    this.selectedProfile.set(found);
    this.activeConditionId.set(found.conditionIds[0]);
    this.evaluateAll();
  }

  setActiveCondition(id: ConditionId): void {
    if (!this.selectedProfile().conditionIds.includes(id)) return;
    this.activeConditionId.set(id);
    this.evaluateAll();
  }

  evaluateAll(): void {
    this.evaluatedFoods.set(this.evaluator.evaluateAll(this.foods(), this.activeConditionId()));
    this.suggestions.set(
      MOCK_SUGGESTIONS.filter((s) => s.context === this.activeConditionId() || s.context === 'general'),
    );
  }

  reset(): void {
    this.profiles.set(MOCK_PROFILES);
    this.foods.set(MOCK_FOODS);
    this.selectedProfile.set(MOCK_PROFILES[0]);
    this.activeConditionId.set(MOCK_PROFILES[0].conditionIds[0]);
    this.loading.set(false);
    this.error.set(null);
    this.evaluateAll();
  }
}
