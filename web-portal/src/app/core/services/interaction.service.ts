import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import {
  AiInteraction,
  DEFAULT_TEST_USER_ID,
  UpdateFeedbackPayload,
  UpdateFeedbackRequest,
  resolveTestUserId,
} from '../models/interaction.model';
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

  updateFeedback(
    id: string,
    payload: UpdateFeedbackPayload,
    userId: unknown = DEFAULT_TEST_USER_ID,
  ): Observable<AiInteraction> {
    const validUserId = resolveTestUserId(userId);
    const body: UpdateFeedbackRequest = { ...payload, userId: validUserId };
    if (environment.useMocks) {
      return of(mockApplyFeedback(id, body.feedbackText)).pipe(delay(300));
    }
    return this.http.patch<AiInteraction>(`${this.interactionsUrl}/${id}/feedback`, body);
  }
}