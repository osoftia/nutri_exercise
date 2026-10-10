import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpResponse } from '@angular/common/http';
import { Subject, firstValueFrom } from 'rxjs';

import { environment } from '../../../environments/environment';
import { HealthService } from './health.service';
import { TelemetryService } from './telemetry.service';

describe('HealthService', () => {
  let service: HealthService;
  let httpGet: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    httpGet = vi.fn();
    vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    const injector = Injector.create({
      providers: [
        { provide: HttpClient, useValue: { get: httpGet } },
        TelemetryService,
        HealthService,
      ],
    });
    service = runInInjectionContext(injector, () => injector.get(HealthService));
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('pings the Mac backend URL and reports online on HTTP 200', async () => {
    const { of } = await import('rxjs');
    httpGet.mockReturnValue(of(new HttpResponse<string>({ status: 200, body: '[]' })));
    const result = await firstValueFrom(service.checkConnection());
    expect(httpGet).toHaveBeenCalledWith(
      `${environment.backendUrl}/api/routine`,
      { observe: 'response', responseType: 'text' },
    );
    expect(result.state).toBe('online');
    expect(result.latencyMs).not.toBeNull();
    expect(result.detail).toContain('HTTP 200');
  });

  it('treats HTTP error statuses as reachable', async () => {
    const { of } = await import('rxjs');
    httpGet.mockReturnValue(of(new HttpResponse<string>({ status: 500, body: 'x' })));
    const result = await firstValueFrom(service.checkConnection());
    expect(result.state).toBe('online');
    expect(result.detail).toContain('HTTP 500');
  });

  it('reports timeout when the Mac stays silent', async () => {
    vi.useFakeTimers();
    httpGet.mockReturnValue(new Subject());
    const pending = firstValueFrom(service.checkConnection(50));
    await vi.advanceTimersByTimeAsync(200);
    const result = await pending;
    expect(result).toEqual({
      state: 'timeout',
      latencyMs: null,
      detail: expect.stringContaining('timeout'),
    });
  });

  it('treats HTTP error statuses as a reachable server', async () => {
    const { throwError } = await import('rxjs');
    httpGet.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 500 })));
    const result = await firstValueFrom(service.checkConnection());
    expect(result.state).toBe('online');
    expect(result.detail).toContain('HTTP 500');
  });

  it('reports unreachable on status 0 (CORS, DNS, or dead IP)', async () => {
    const { throwError } = await import('rxjs');
    httpGet.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 0 })));
    const result = await firstValueFrom(service.checkConnection());
    expect(result.state).toBe('unreachable');
    expect(result.detail).toContain('CORS');
  });

  it('reports unreachable on unknown failures', async () => {
    const { throwError } = await import('rxjs');
    httpGet.mockReturnValue(throwError(() => new Error('weird')));
    const result = await firstValueFrom(service.checkConnection());
    expect(result.state).toBe('unreachable');
  });
});
