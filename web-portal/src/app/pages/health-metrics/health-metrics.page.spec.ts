import '@angular/compiler';
import { describe, expect, it, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';

import { MOCK_HEALTH_METRICS } from '../../core/mocks/mock-health-metrics.data';
import { HealthMetricsStore } from '../../core/stores/health-metrics.store';
import { HealthMetricsPage } from './health-metrics.page';

function createStore(load = vi.fn()) {
  return {
    payload: signal(MOCK_HEALTH_METRICS),
    isLoading: signal(false),
    error: signal<string | null>(null),
    bloodPressure: signal(MOCK_HEALTH_METRICS.bloodPressure.slice(0, 10)),
    glucose: signal(
      MOCK_HEALTH_METRICS.glucose.slice(0, 10).map((reading) => ({
        date: reading.date,
        value: reading.value,
      })),
    ),
    bmi: signal(
      MOCK_HEALTH_METRICS.bmi.slice(0, 10).map((reading) => ({
        date: reading.date,
        value: reading.value,
      })),
    ),
    sleep: signal(MOCK_HEALTH_METRICS.sleep.slice(0, 10)),
    activeCalories: signal(
      MOCK_HEALTH_METRICS.activeCalories.slice(0, 10).map((record) => ({
        date: record.date,
        value: record.value,
      })),
    ),
    load,
  };
}

describe('HealthMetricsPage', () => {
  it('requests the data on init and renders every metric chart', async () => {
    const load = vi.fn();
    await TestBed.configureTestingModule({
      imports: [HealthMetricsPage],
      providers: [{ provide: HealthMetricsStore, useValue: createStore(load) }],
    }).compileComponents();

    const fixture = TestBed.createComponent(HealthMetricsPage);
    fixture.detectChanges();

    expect(load).toHaveBeenCalledTimes(1);
    expect(fixture.nativeElement.querySelector('app-blood-pressure-scatter')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-glucose-line')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-bmi-area')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-sleep-quality-heatmap')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-active-calories-bar')).not.toBeNull();
  });
});
