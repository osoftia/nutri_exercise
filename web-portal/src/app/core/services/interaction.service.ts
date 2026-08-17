import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { AiInteraction, UpdateFeedbackRequest } from '../models/interaction.model';
import { mockInteractions, mockApplyFeedback } from '../mocks/mock-interactions.data';

@Service()
export class InteractionService {
  private readonly http = inject(HttpClient);
  private readonly interactionsUrl = `${environment.apiUrl}/interactions`;

  getInteractions(): Observable<AiInteraction[]> {
    if (environment.useMocks) {
      return of(mockInteractions).pipe(delay(500));
    }
    return this.http.get<AiInteraction[]>(this.interactionsUrl);
  }

  updateFeedback(id: string, payload: UpdateFeedbackRequest): Observable<AiInteraction> {
    if (environment.useMocks) {
      return of(mockApplyFeedback(id, payload.feedbackText)).pipe(delay(300));
    }
    return this.http.patch<AiInteraction>(`${this.interactionsUrl}/${id}/feedback`, payload);
  }
}