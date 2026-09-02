import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';

import { mockAiPerformance } from '../mocks/mock-analytics.data';
import { AiPerformance } from '../models/analytics.model';
import { AiMetricsService } from './ai-metrics.service';

describe('AiMetricsService', () => {
  let service: AiMetricsService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [AiMetricsService] });
    service = TestBed.inject(AiMetricsService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns the mock AI performance in mock mode', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getPerformance());
    await vi.advanceTimersByTimeAsync(500);

    const performance = await result;
    expect(performance.averageLatencyMs).toBe(1842);
    expect(performance.averageTokensPerSecond).toBe(38);
    expect(performance.samples.length).toBeGreaterThan(0);
  });

  it('returns a performance of the AiPerformance type', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getPerformance());
    await vi.advanceTimersByTimeAsync(500);

    const performance: AiPerformance = await result;
    expect(performance.samples[0]).toHaveProperty('latencyMs');
    expect(performance.samples[0]).toHaveProperty('tokensPerSecond');
  });

  it('serves the exact mock performance object', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getPerformance());
    await vi.advanceTimersByTimeAsync(500);

    expect(await result).toEqual(mockAiPerformance);
  });
});