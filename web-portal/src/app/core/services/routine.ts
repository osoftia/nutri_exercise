import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { WorkoutDay, mockWorkoutRoutines } from '../mocks/mock-routine.data';

@Service()
export class Routine {
  private readonly http = inject(HttpClient);

  getWeeklyRoutine(): Observable<WorkoutDay[]> {
    if (environment.useMocks) {
      return of(mockWorkoutRoutines).pipe(delay(500));
    }
    return this.http.get<WorkoutDay[]>(`${environment.apiUrl}/api/v1/routines/week`);
  }
}
