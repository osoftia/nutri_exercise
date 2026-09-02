import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { AiPerformance } from '../models/analytics.model';
import { mockAiPerformance } from '../mocks/mock-analytics.data';

@Service()
export class AiMetricsService {
  private readonly http = inject(HttpClient);

  getPerformance(): Observable<AiPerformance> {
    if (environment.useMocks) {
      return of(mockAiPerformance).pipe(delay(500));
    }
    return this.http.get<AiPerformance>(`${environment.apiUrl}/analytics/ai-performance`);
  }
}