import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { signal } from '@angular/core';

import { DashboardStore } from './dashboard.store';
import { AiMetricsService } from '../services/ai-metrics.service';
import { TelemetryService } from '../services/telemetry.service';
import { mockAiPerformance, mockTelemetrySnapshot } from '../mocks/mock-analytics.data';
import { AnalyticsStore } from './analytics.store';

describe('AnalyticsStore', () => {
  let telemetryService: { getSnapshot: ReturnType<typeof vi.fn> };
  let aiMetricsService: { getPerformance: ReturnType<typeof vi.fn> };
  let store: AnalyticsStore;

  beforeEach(() => {
    telemetryService = { getSnapshot: vi.fn(() => of(mockTelemetrySnapshot)) };
    aiMetricsService = { getPerformance: vi.fn(() => of(mockAiPerformance)) };

    TestBed.configureTestingModule({
      providers: [
        AnalyticsStore,
        { provide: TelemetryService, useValue: telemetryService },
        { provide: AiMetricsService, useValue: aiMetricsService },
        {
          provide: DashboardStore,
          useValue: {
            analytics: signal({ positiveCount: 2, negativeCount: 1, reviewedCount: 3 }),
          },
        },
      ],
    });

    store = TestBed.inject(AnalyticsStore);
  });

  it('loads telemetry and AI performance in parallel', () => {
    store.load();

    expect(telemetryService.getSnapshot).toHaveBeenCalledTimes(1);
    expect(aiMetricsService.getPerformance).toHaveBeenCalledTimes(1);
    expect(store.loading()).toBe(false);
    expect(store.telemetry()).toEqual(mockTelemetrySnapshot);
    expect(store.aiPerformance()).toEqual(mockAiPerformance);
    expect(store.error()).toBeNull();
  });

  it('surfaces an error when loading fails', () => {
    telemetryService.getSnapshot.mockReturnValue(throwError(() => new Error('boom')));

    store.load();

    expect(store.error()).toBe('Could not load analytics data.');
    expect(store.loading()).toBe(false);
    expect(store.telemetry()).toBeNull();
  });

  it('retry reloads the analytics data', () => {
    store.load();
    store.retry();

    expect(telemetryService.getSnapshot).toHaveBeenCalledTimes(2);
  });

  it('derives the RLHF feedback distribution from the dashboard store', () => {
    expect(store.feedbackDistribution()).toEqual({ positive: 2, negative: 1, reviewed: 3 });
  });

  it('reset clears all signals', () => {
    store.load();

    store.reset();

    expect(store.telemetry()).toBeNull();
    expect(store.aiPerformance()).toBeNull();
    expect(store.loading()).toBe(false);
    expect(store.error()).toBeNull();
  });
});