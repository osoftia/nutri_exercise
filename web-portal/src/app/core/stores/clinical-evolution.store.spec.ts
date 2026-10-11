import '@angular/compiler';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { NEVER, throwError } from 'rxjs';

import { MOCK_CLINICAL_EVOLUTION } from '../mocks/mock-clinical-evolution.data';
import { ClinicalEvolutionPayload } from '../models/clinical-evolution.model';
import { ClinicalEvolutionService } from '../services/clinical-evolution.service';
import { ClinicalEvolutionStore } from './clinical-evolution.store';

function createStore(service: unknown): ClinicalEvolutionStore {
  const injector = Injector.create({
    providers: [
      { provide: ClinicalEvolutionService, useValue: service },
      ClinicalEvolutionStore,
    ],
  });
  return runInInjectionContext(injector, () => injector.get(ClinicalEvolutionStore));
}

describe('ClinicalEvolutionStore', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('loads the payload and derives the risk level and layout', async () => {
    const store = createStore(new ClinicalEvolutionService());

    vi.useFakeTimers();
    store.load();
    expect(store.isLoading()).toBe(true);
    await vi.advanceTimersByTimeAsync(600);

    expect(store.payload()).toEqual(MOCK_CLINICAL_EVOLUTION);
    expect(store.isLoading()).toBe(false);
    expect(store.healthScore()).toBe(32);
    expect(store.riskLevel()).toBe('medium');
    expect(store.chartLayout()?.bars).toHaveLength(8);
  });

  it('maps scores into the three risk bands', () => {
    const store = createStore(new ClinicalEvolutionService());

    for (const [score, level] of [
      [10, 'low'],
      [19, 'low'],
      [20, 'medium'],
      [49, 'medium'],
      [50, 'high'],
      [80, 'high'],
    ] as const) {
      store.payload.set({ ...MOCK_CLINICAL_EVOLUTION, health_score: score });
      expect(store.riskLevel()).toBe(level);
    }
  });

  it('surfaces an error message when the load fails', () => {
    const store = createStore({ load: () => throwError(() => new Error('boom')) });

    store.load();

    expect(store.error()).toBe('Could not load clinical evolution data.');
    expect(store.isLoading()).toBe(false);
    expect(store.payload()).toBeNull();
  });

  it('ignores load requests while a load is already in flight', () => {
    const load = vi.fn(() => NEVER);
    const store = createStore({ load });

    store.load();
    store.load();

    expect(load).toHaveBeenCalledTimes(1);
    expect(store.isLoading()).toBe(true);
  });
});

describe('ClinicalEvolutionPayload typing', () => {
  it('matches the mock contract', () => {
    const payload: ClinicalEvolutionPayload = MOCK_CLINICAL_EVOLUTION;
    expect(payload.historical_data).toHaveLength(8);
    expect(payload.projected_data).toHaveLength(4);
  });
});
