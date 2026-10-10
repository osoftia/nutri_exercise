import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { TelemetrySnapshot } from '../models/analytics.model';
import { mockTelemetrySnapshot } from '../mocks/mock-analytics.data';

@Service()
export class TelemetryService {
  private readonly http = inject(HttpClient);

  getSnapshot(): Observable<TelemetrySnapshot> {
    if (environment.useMocks) {
      return of(mockTelemetrySnapshot).pipe(delay(500));
    }
    return this.http.get<TelemetrySnapshot>(`${environment.apiUrl}/telemetry/snapshot`);
  }

  // Global logger: the only place allowed to call console.* (see ARCHITECTURE.md).
  debug(message: string, context?: unknown): void {
    this.write('debug', message, context);
  }

  info(message: string, context?: unknown): void {
    this.write('info', message, context);
  }

  warn(message: string, context?: unknown): void {
    this.write('warn', message, context);
  }

  error(message: string, context?: unknown): void {
    this.write('error', message, context);
  }

  private write(level: 'debug' | 'info' | 'warn' | 'error', message: string, context?: unknown): void {
    const line = `[Telemetry:${level}] ${message}`;
    if (level === 'error') {
      if (context === undefined) console.error(line);
      else console.error(line, context);
    } else if (level === 'warn') {
      if (context === undefined) console.warn(line);
      else console.warn(line, context);
    } else if (level === 'debug') {
      if (context === undefined) console.debug(line);
      else console.debug(line, context);
    } else {
      if (context === undefined) console.info(line);
      else console.info(line, context);
    }
  }
}