import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';

import { mockTelemetrySnapshot } from '../mocks/mock-analytics.data';
import { TelemetrySnapshot } from '../models/analytics.model';
import { TelemetryService } from './telemetry.service';

describe('TelemetryService', () => {
  let service: TelemetryService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [TelemetryService] });
    service = TestBed.inject(TelemetryService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns the mock telemetry snapshot in mock mode', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getSnapshot());
    await vi.advanceTimersByTimeAsync(500);

    const snapshot = await result;
    expect(snapshot.activeWorkoutSessions).toBe(3);
    expect(snapshot.pendingSyncItems).toBe(2);
    expect(snapshot.lastSyncAt).toBe('2026-08-18T08:00:00Z');
    expect(snapshot.events.length).toBeGreaterThan(0);
  });

  it('returns a snapshot of the TelemetrySnapshot type', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getSnapshot());
    await vi.advanceTimersByTimeAsync(500);

    const snapshot = await result;
    const telemetry: TelemetrySnapshot = snapshot;
    expect(telemetry).toBeDefined();
    expect(telemetry.events[0]).toHaveProperty('type');
    expect(telemetry.events[0]).toHaveProperty('occurredAt');
  });

  it('serves the exact mock snapshot object', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getSnapshot());
    await vi.advanceTimersByTimeAsync(500);

    expect(await result).toEqual(mockTelemetrySnapshot);
  });
});