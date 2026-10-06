import '@angular/compiler';
import { describe, it, expect, beforeEach } from 'vitest';

import { MOCK_FOODS } from '../mocks/medical-profile.data';
import { FoodItem } from '../models/medical-profile.model';
import { AiEvaluatorMockService } from './ai-evaluator.mock.service';

function byName(name: string): FoodItem {
  const found = MOCK_FOODS.find((f) => f.name === name);
  if (!found) throw new Error(`Missing mock food: ${name}`);
  return found;
}

describe('AiEvaluatorMockService', () => {
  let service: AiEvaluatorMockService;

  beforeEach(() => {
    service = new AiEvaluatorMockService();
  });

  it('warns on Bacon under high-cholesterol', () => {
    const result = service.evaluateFood(byName('Bacon'), ['high-cholesterol']);
    expect(result.verdict).toBe('WARNING');
    expect(result.reason).toContain('saturated fat');
  });

  it('recommends Oatmeal under high-cholesterol (single id form)', () => {
    const result = service.evaluateFood(byName('Oatmeal'), 'high-cholesterol');
    expect(result.verdict).toBe('RECOMMENDED');
    expect(result.reason).toContain('fiber');
  });

  it('warns on Shrimp and Red Meat under gout', () => {
    const shrimp = service.evaluateFood(byName('Shrimp'), 'gout');
    const redMeat = service.evaluateFood(byName('Red Meat'), ['gout']);
    expect(shrimp.verdict).toBe('WARNING');
    expect(shrimp.reason).toContain('purine');
    expect(redMeat.verdict).toBe('WARNING');
    expect(redMeat.reason).toContain('purine');
  });

  it('warns on Sugary Soda under diabetes', () => {
    const result = service.evaluateFood(byName('Sugary Soda'), 'type-2-diabetes');
    expect(result.verdict).toBe('WARNING');
    expect(result.reason).toContain('glucose spike');
  });

  it('recommends Salmon and Lentils by default', () => {
    expect(service.evaluateFood(byName('Salmon'), 'gout').verdict).toBe('RECOMMENDED');
    expect(service.evaluateFood(byName('Lentils'), 'high-cholesterol').verdict).toBe('RECOMMENDED');
  });

  it('returns NEUTRAL fallback otherwise', () => {
    const result = service.evaluateFood(byName('Broccoli'), 'gout');
    expect(result.verdict).toBe('NEUTRAL');
    expect(result.reason).toContain('No strong signal');
  });

  it('evaluateAll preserves order and length', () => {
    const foods = [byName('Bacon'), byName('Oatmeal'), byName('Broccoli')];
    const results = service.evaluateAll(foods, 'high-cholesterol');
    expect(results).toHaveLength(foods.length);
    expect(results.map((r) => r.food.name)).toEqual(['Bacon', 'Oatmeal', 'Broccoli']);
    expect(results.map((r) => r.verdict)).toEqual(['WARNING', 'RECOMMENDED', 'NEUTRAL']);
  });
});
