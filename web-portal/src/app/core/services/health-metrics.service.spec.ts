import '@angular/compiler';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { MOCK_HEALTH_METRICS } from '../mocks/mock-health-metrics.data';
import { HealthMetricsService } from './health-metrics.service';

describe('HealthMetricsService', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('emits a deterministic mock payload after a short delay', async () => {
    const injector = Injector.create({ providers: [HealthMetricsService] });
    const service = runInInjectionContext(injector, () => injector.get(HealthMetricsService));

    vi.useFakeTimers();
    const pending = firstValueFrom(service.load());
    await vi.advanceTimersByTimeAsync(600);

    const payload = await pending;
    expect(payload).toEqual(MOCK_HEALTH_METRICS);
    expect(payload.bloodPressure).toHaveLength(365);
  });
});
