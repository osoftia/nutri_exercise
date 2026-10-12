import '@angular/compiler';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';

import { HealthDashboardUiStore } from './health-dashboard-ui.store';

function createStore(): HealthDashboardUiStore {
  const injector = Injector.create({ providers: [HealthDashboardUiStore] });
  return runInInjectionContext(injector, () => injector.get(HealthDashboardUiStore));
}

describe('HealthDashboardUiStore', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('starts on the dashboard tab and switches tabs', () => {
    const store = createStore();
    expect(store.activeTab()).toBe('dashboard');
    store.setTab('rag');
    expect(store.activeTab()).toBe('rag');
  });

  it('focuses a chart, returns to the dashboard and auto-clears', () => {
    const store = createStore();
    vi.useFakeTimers();
    store.setTab('rag');

    store.focusChart('sleep');
    expect(store.activeTab()).toBe('dashboard');
    expect(store.focusedChartId()).toBe('sleep');

    vi.advanceTimersByTime(2800);
    expect(store.focusedChartId()).toBeNull();
  });

  it('clears focus when leaving the dashboard', () => {
    const store = createStore();
    store.focusChart('bmi');
    store.setTab('rag');
    expect(store.focusedChartId()).toBeNull();
  });

  it('clears focus explicitly', () => {
    const store = createStore();
    store.focusChart('glucose');
    store.clearFocus();
    expect(store.focusedChartId()).toBeNull();
  });
});
