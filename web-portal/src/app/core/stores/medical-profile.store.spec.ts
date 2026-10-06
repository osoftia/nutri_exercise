import '@angular/compiler';
import { describe, it, expect, beforeEach } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';

import { AiEvaluatorMockService } from '../services/ai-evaluator.mock.service';
import { MOCK_FOODS, MOCK_PROFILES, MOCK_SUGGESTIONS } from '../mocks/medical-profile.data';
import { MedicalProfileStore } from './medical-profile.store';

function setup(): MedicalProfileStore {
  const injector = Injector.create({
    providers: [{ provide: AiEvaluatorMockService, useValue: new AiEvaluatorMockService() }, MedicalProfileStore],
  });
  return runInInjectionContext(injector, () => injector.get(MedicalProfileStore));
}

describe('MedicalProfileStore', () => {
  let store: MedicalProfileStore;

  beforeEach(() => {
    store = setup();
  });

  it('defaults to first mock profile with its first condition and evaluated foods', () => {
    expect(store.selectedProfile().id).toBe(MOCK_PROFILES[0].id);
    expect(store.activeConditionId()).toBe(MOCK_PROFILES[0].conditionIds[0]);
    expect(store.activeCondition()?.id).toBe(MOCK_PROFILES[0].conditionIds[0]);
    expect(store.evaluatedFoods()).toHaveLength(MOCK_FOODS.length);
  });

  it('selectProfile switches profile, active condition, and re-evaluates foods', () => {
    store.selectProfile('user-cara');
    expect(store.selectedProfile().id).toBe('user-cara');
    expect(store.activeConditionId()).toBe('gout');
    expect(store.activeCondition()?.id).toBe('gout');
    const shrimp = store.evaluatedFoods().find((e) => e.food.id === 'shrimp');
    expect(shrimp?.verdict).toBe('WARNING');
  });

  it('setActiveCondition updates context and re-evaluates (cholesterol + bacon = WARNING)', () => {
    // Default profile Anna has high-cholesterol; bacon must warn.
    store.evaluateAll();
    const bacon = store.evaluatedFoods().find((e) => e.food.id === 'bacon');
    expect(store.activeConditionId()).toBe('high-cholesterol');
    expect(bacon?.verdict).toBe('WARNING');

    // Guard: condition outside selected profile is ignored.
    store.setActiveCondition('gout');
    expect(store.activeConditionId()).toBe('high-cholesterol');
  });

  it('evaluateAll populates evaluatedFoods with warnings for active condition', () => {
    store.evaluateAll();
    expect(store.evaluatedFoods()).toHaveLength(MOCK_FOODS.length);
    const names = store.warnings().map((w) => w.food.name);
    expect(names).toContain('Bacon');
    expect(store.recommended().length).toBeGreaterThan(0);
  });

  it('suggestions filtered for active condition', () => {
    expect(store.suggestions().length).toBeGreaterThan(0);
    for (const s of store.suggestions()) {
      expect([store.activeConditionId(), 'general']).toContain(s.context);
    }
    expect(store.suggestionsForActive().length).toBeGreaterThan(0);
    const expected = MOCK_SUGGESTIONS.filter(
      (s) => s.context === store.activeConditionId() || s.context === 'general',
    );
    expect(store.suggestions().map((s) => s.id).sort()).toEqual(expected.map((s) => s.id).sort());
  });

  it('reset restores defaults', () => {
    store.selectProfile('user-ben');
    expect(store.selectedProfile().id).toBe('user-ben');
    store.reset();
    expect(store.selectedProfile().id).toBe(MOCK_PROFILES[0].id);
    expect(store.activeConditionId()).toBe(MOCK_PROFILES[0].conditionIds[0]);
    expect(store.evaluatedFoods()).toHaveLength(MOCK_FOODS.length);
    expect(store.loading()).toBe(false);
    expect(store.error()).toBeNull();
  });
});
