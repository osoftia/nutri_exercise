import { Service } from '@angular/core';
import { Observable, delay, of } from 'rxjs';

import { MOCK_CLINICAL_EVOLUTION } from '../mocks/mock-clinical-evolution.data';
import { ClinicalEvolutionPayload } from '../models/clinical-evolution.model';

@Service()
export class ClinicalEvolutionService {
  load(): Observable<ClinicalEvolutionPayload> {
    return of(MOCK_CLINICAL_EVOLUTION).pipe(delay(600));
  }
}
