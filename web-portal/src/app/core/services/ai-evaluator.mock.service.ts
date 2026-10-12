import { Injectable } from '@angular/core';

import {
  ConditionId,
  EvaluatedFood,
  FoodItem,
} from '../models/medical-profile.model';

const NEUTRAL_REASON = 'No strong signal for this condition (mock).';

function normalize(conditions: ConditionId[] | ConditionId): ConditionId[] {
  return Array.isArray(conditions) ? conditions : [conditions];
}

interface FoodSignals {
  isBacon: boolean;
  isOatmeal: boolean;
  isHighPurine: boolean;
  isSugary: boolean;
  isSalmon: boolean;
  isLentil: boolean;
}

function detectSignals(food: FoodItem): FoodSignals {
  const name = food.name.toLowerCase();
  const tags = food.tags.map((tag) => tag.toLowerCase());
  const tagged = (...keys: string[]): boolean => keys.some((key) => tags.includes(key));
  return {
    isBacon: name.includes('bacon') || (tagged('red-meat', 'high-saturated-fat') && name.includes('bacon')),
    isOatmeal: name.includes('oatmeal') || name.includes('oat'),
    isHighPurine:
      tagged('high-purine') || name.includes('shrimp') || name.includes('red meat') || name.includes('steak'),
    isSugary: tagged('high-sugar') || name.includes('soda'),
    isSalmon: name.includes('salmon') || tagged('omega-3'),
    isLentil: name.includes('lentil'),
  };
}

@Injectable({ providedIn: 'root' })
export class AiEvaluatorMockService {
  evaluateFood(food: FoodItem, conditions: ConditionId[] | ConditionId): EvaluatedFood {
    const list = normalize(conditions);
    const has = (condition: ConditionId): boolean => list.includes(condition);
    const { isBacon, isOatmeal, isHighPurine, isSugary, isSalmon, isLentil } = detectSignals(food);

    const rules: { test: () => boolean; verdict: EvaluatedFood['verdict']; reason: string }[] = [
      {
        test: () => has('high-cholesterol') && isBacon,
        verdict: 'WARNING',
        reason: 'High saturated fat — raises LDL.',
      },
      {
        test: () => has('high-cholesterol') && isOatmeal,
        verdict: 'RECOMMENDED',
        reason: 'Soluble fiber helps lower LDL.',
      },
      {
        test: () => has('gout') && isHighPurine,
        verdict: 'WARNING',
        reason: 'High purine — may trigger gout flare.',
      },
      {
        test: () => has('type-2-diabetes') && isSugary,
        verdict: 'WARNING',
        reason: 'Rapid glucose spike — avoid.',
      },
      {
        test: () => isSalmon,
        verdict: 'RECOMMENDED',
        reason: 'Rich in omega-3 — heart friendly.',
      },
      {
        test: () => isLentil,
        verdict: 'RECOMMENDED',
        reason: 'High fiber — steady glucose, heart friendly.',
      },
    ];

    const match = rules.find((rule) => rule.test());
    if (!match) {
      return { food, verdict: 'NEUTRAL', reason: NEUTRAL_REASON };
    }
    return { food, verdict: match.verdict, reason: match.reason };
  }

  evaluateAll(foods: FoodItem[], conditions: ConditionId[] | ConditionId): EvaluatedFood[] {
    return foods.map((food) => this.evaluateFood(food, conditions));
  }
}
