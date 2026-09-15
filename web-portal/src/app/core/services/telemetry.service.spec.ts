import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom, of } from 'rxjs';

import { mockTelemetrySnapshot } from '../mocks/mock-analytics.data';
import { TelemetrySnapshot } from '../models/analytics.model';
import { TelemetryService } from './telemetry.service';

describe('TelemetryService', () => {
  let service: TelemetryService;
  let httpGet: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    httpGet = vi.fn();
    const injector = Injector.create([
      { provide: HttpClient, useValue: { get: httpGet } },
      TelemetryService,
    ]);
    service = runInInjectionContext(injector, () => injector.get(TelemetryService));
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
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

  it.each([
    ['debug', 'debug'],
    ['info', 'info'],
    ['warn', 'warn'],
    ['error', 'error'],
  ] as const)('routes %s() through console.%s with telemetry prefix', (method, consoleMethod) => {
    const spy = vi.spyOn(console, consoleMethod).mockImplementation(() => undefined);
    service[method]('hello');
    expect(spy).toHaveBeenCalledWith('[Telemetry:' + method + '] hello');
  });

  it('forwards context to the console call', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    service.error('boom', { status: 500 });
    expect(spy).toHaveBeenCalledWith('[Telemetry:error] boom', { status: 500 });
  });

  it.each([
    ['debug', 'debug'],
    ['info', 'info'],
    ['warn', 'warn'],
  ] as const)('forwards context for %s()', (method, consoleMethod) => {
    const spy = vi.spyOn(console, consoleMethod).mockImplementation(() => undefined);
    service[method]('hello', { source: 'board' });
    expect(spy).toHaveBeenCalledWith(`[Telemetry:${method}] hello`, { source: 'board' });
  });

  it('fetches the snapshot from the API when mocks are disabled', async () => {
    const { environment } = await import('../../../environments/environment');
    environment.useMocks = false;
    try {
      httpGet.mockReturnValue(of(mockTelemetrySnapshot));
      const snapshot = await firstValueFrom(service.getSnapshot());
      expect(httpGet).toHaveBeenCalledWith(expect.stringContaining('/telemetry/snapshot'));
      expect(snapshot).toEqual(mockTelemetrySnapshot);
    } finally {
      environment.useMocks = true;
    }
  });
});
