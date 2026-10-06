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

@Injectable({ providedIn: 'root' })
export class AiEvaluatorMockService {
  evaluateFood(food: FoodItem, conditions: ConditionId[] | ConditionId): EvaluatedFood {
    const list = normalize(conditions);
    const name = food.name.toLowerCase();
    const tags = food.tags.map((t) => t.toLowerCase());
    const has = (c: ConditionId): boolean => list.includes(c);
    const tagged = (...keys: string[]): boolean => keys.some((k) => tags.includes(k));

    const isBacon = name.includes('bacon') || (tagged('red-meat', 'high-saturated-fat') && name.includes('bacon'));
    const isOatmeal = name.includes('oatmeal') || name.includes('oat');
    const isHighPurine =
      tagged('high-purine') || name.includes('shrimp') || name.includes('red meat') || name.includes('steak');
    const isSugary = tagged('high-sugar') || name.includes('soda');
    const isSalmon = name.includes('salmon') || tagged('omega-3');
    const isLentil = name.includes('lentil');

    if (has('high-cholesterol') && isBacon) {
      return { food, verdict: 'WARNING', reason: 'High saturated fat — raises LDL.' };
    }
    if (has('high-cholesterol') && isOatmeal) {
      return { food, verdict: 'RECOMMENDED', reason: 'Soluble fiber helps lower LDL.' };
    }
    if (has('gout') && isHighPurine) {
      return { food, verdict: 'WARNING', reason: 'High purine — may trigger gout flare.' };
    }
    if (has('type-2-diabetes') && isSugary) {
      return { food, verdict: 'WARNING', reason: 'Rapid glucose spike — avoid.' };
    }
    if (isSalmon) {
      return { food, verdict: 'RECOMMENDED', reason: 'Rich in omega-3 — heart friendly.' };
    }
    if (isLentil) {
      return { food, verdict: 'RECOMMENDED', reason: 'High fiber — steady glucose, heart friendly.' };
    }
    return { food, verdict: 'NEUTRAL', reason: NEUTRAL_REASON };
  }

  evaluateAll(foods: FoodItem[], conditions: ConditionId[] | ConditionId): EvaluatedFood[] {
    return foods.map((food) => this.evaluateFood(food, conditions));
  }
}
