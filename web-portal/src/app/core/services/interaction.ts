import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { Interaction, mockInteractions } from '../mocks/mock-interaction.data';

@Service()
export class InteractionService {
  private readonly http = inject(HttpClient);

  getHistory(): Observable<Interaction[]> {
    if (environment.useMocks) {
      return of(mockInteractions).pipe(delay(500));
    }
    return this.http.get<Interaction[]>(`${environment.apiUrl}/api/interaction/history`);
  }

  submitFeedback(id: string, isCorrect: boolean): Observable<unknown> {
    if (environment.useMocks) {
      return of({ isCorrect }).pipe(delay(300));
    }
    return this.http.put(`${environment.apiUrl}/api/interaction/${id}/feedback`, { isCorrect });
  }
}
