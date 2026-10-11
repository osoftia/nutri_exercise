import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { computed, signal } from '@angular/core';

import { HealthRiskLevel } from '../../../core/models/clinical-evolution.model';
import { ClinicalEvolutionStore } from '../../../core/stores/clinical-evolution.store';
import { HealthRiskGauge } from './health-risk-gauge';

function createStore(score: number): {
  healthScore: ReturnType<typeof signal<number>>;
  riskLevel: ReturnType<typeof computed<HealthRiskLevel>>;
} {
  const healthScore = signal(score);
  const riskLevel = computed<HealthRiskLevel>(() => {
    const value = healthScore();
    if (value < 20) {
      return 'low';
    }
    if (value < 50) {
      return 'medium';
    }
    return 'high';
  });
  return { healthScore, riskLevel };
}

async function build(score: number): Promise<HealthRiskGauge> {
  await TestBed.configureTestingModule({
    imports: [HealthRiskGauge],
    providers: [{ provide: ClinicalEvolutionStore, useValue: createStore(score) }],
  }).compileComponents();
  return TestBed.createComponent(HealthRiskGauge).componentInstance;
}

describe('HealthRiskGauge', () => {
  it('maps a medium score to the warning color and a partial arc', async () => {
    const component = await build(32);

    expect(component.score()).toBe(32);
    expect(component.level()).toBe('medium');
    expect(component.color()).toBe('var(--color-warning)');
    expect(component.dashOffset()).toBeCloseTo(component.circumference * 0.68, 5);
  });

  it('maps a low score to the success color', async () => {
    const component = await build(10);

    expect(component.level()).toBe('low');
    expect(component.color()).toBe('var(--color-success)');
    expect(component.levelLabelKey()).toBe('evolution.low');
  });

  it('maps a high score to the danger color', async () => {
    const component = await build(72);

    expect(component.level()).toBe('high');
    expect(component.color()).toBe('var(--color-danger)');
    expect(component.levelLabelKey()).toBe('evolution.high');
  });
});
