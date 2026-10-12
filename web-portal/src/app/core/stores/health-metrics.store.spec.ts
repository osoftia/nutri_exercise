import '@angular/compiler';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { NEVER, throwError } from 'rxjs';

import { HealthMetricsService } from '../services/health-metrics.service';
import { HealthMetricsStore } from './health-metrics.store';

function createStore(service: unknown): HealthMetricsStore {
  const injector = Injector.create({
    providers: [
      { provide: HealthMetricsService, useValue: service },
      HealthMetricsStore,
    ],
  });
  return runInInjectionContext(injector, () => injector.get(HealthMetricsStore));
}

describe('HealthMetricsStore', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('loads a full year of metrics and derives each series', async () => {
    const store = createStore(new HealthMetricsService());

    vi.useFakeTimers();
    store.load();
    expect(store.isLoading()).toBe(true);
    await vi.advanceTimersByTimeAsync(600);

    expect(store.isLoading()).toBe(false);
    expect(store.bloodPressure()).toHaveLength(365);
    expect(store.glucose()).toHaveLength(365);
    expect(store.bmi()).toHaveLength(365);
    expect(store.sleep()).toHaveLength(365);
    expect(store.activeCalories()).toHaveLength(365);
    expect(store.glucose()[0]).toHaveProperty('date');
    expect(store.glucose()[0]).toHaveProperty('value');
  });

  it('surfaces an error message when the load fails', () => {
    const store = createStore({ load: () => throwError(() => new Error('boom')) });
    store.load();
    expect(store.error()).toBe('Could not load health metrics data.');
    expect(store.payload()).toBeNull();
  });

  it('ignores load requests while a load is already in flight', () => {
    const load = vi.fn(() => NEVER);
    const store = createStore({ load });
    store.load();
    store.load();
    expect(load).toHaveBeenCalledTimes(1);
  });
});
