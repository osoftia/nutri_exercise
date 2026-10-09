import { Injectable } from '@angular/core';
import { Observable, delay, of } from 'rxjs';

import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import { mockPromptLabResponse } from '../mocks/mock-prompt-lab.data';

@Injectable({ providedIn: 'root' })
export class PromptLabService {
  private static readonly MOCK_DELAY_MS = 1200;

  runQuery(request: PromptLabRequest): Observable<PromptLabResult> {
    return of(mockPromptLabResponse(request.query)).pipe(
      delay(PromptLabService.MOCK_DELAY_MS),
    );
  }
}