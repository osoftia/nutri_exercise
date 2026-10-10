import { Service, inject } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpResponse } from '@angular/common/http';
import { Observable, catchError, map, of, timeout, TimeoutError } from 'rxjs';

import { environment } from '../../../environments/environment';
import { TelemetryService } from './telemetry.service';

export type ConnectionState = 'idle' | 'checking' | 'online' | 'unreachable' | 'timeout';

export interface ConnectionResult {
  state: Exclude<ConnectionState, 'idle' | 'checking'>;
  latencyMs: number | null;
  detail: string;
}

const DEFAULT_TIMEOUT_MS = 5000;

/**
 * Verifies connectivity to the .NET backend (Mac on the LAN) with a
 * lightweight `GET {backendUrl}/api/routine`. Any HTTP response — even an
 * error status — proves the server is reachable; status 0 means the request
 * never left the browser (CORS block, DNS failure, or dead IP).
 */
@Service()
export class HealthService {
  private readonly http = inject(HttpClient);
  private readonly telemetry = inject(TelemetryService);
  private readonly pingUrl = `${environment.backendUrl}/api/routine`;

  checkConnection(timeoutMs = DEFAULT_TIMEOUT_MS): Observable<ConnectionResult> {
    const started = Date.now();
    return this.http
      .get(this.pingUrl, { observe: 'response', responseType: 'text' })
      .pipe(
        timeout(timeoutMs),
        map((res: HttpResponse<string>) => this.online(res.status, started)),
        catchError((error: unknown) => of(this.toFailure(error, started))),
      );
  }

  private online(status: number, started: number): ConnectionResult {
    const latencyMs = Date.now() - started;
    return { state: 'online', latencyMs, detail: `Reachable (HTTP ${status}) in ${latencyMs} ms.` };
  }

  private toFailure(error: unknown, started: number): ConnectionResult {
    if (error instanceof TimeoutError || (error as Error)?.name === 'TimeoutError') {
      this.telemetry.warn('Backend connection timed out.', { url: this.pingUrl });
      return { state: 'timeout', latencyMs: null, detail: 'No answer before the timeout. The Mac may be asleep or overloaded.' };
    }
    if (error instanceof HttpErrorResponse) {
      if (error.status !== 0) return this.online(error.status, started);
      this.telemetry.warn('Backend unreachable (status 0).', { url: this.pingUrl });
      return {
        state: 'unreachable',
        latencyMs: null,
        detail: 'No response: wrong IP, server down, or CORS block (origin not allow-listed in Program.cs).',
      };
    }
    this.telemetry.warn('Backend check failed with an unknown error.', { url: this.pingUrl });
    return { state: 'unreachable', latencyMs: null, detail: 'Unexpected failure while contacting the backend.' };
  }
}
