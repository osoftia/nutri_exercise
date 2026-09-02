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
}