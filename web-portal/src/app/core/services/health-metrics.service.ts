import { Service } from '@angular/core';
import { Observable, delay, of } from 'rxjs';

import { MOCK_HEALTH_METRICS } from '../mocks/mock-health-metrics.data';
import { HealthMetricsPayload } from '../models/health-metrics.model';

@Service()
export class HealthMetricsService {
  load(): Observable<HealthMetricsPayload> {
    return of(MOCK_HEALTH_METRICS).pipe(delay(600));
  }
}
