import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { DailyMenu, mockDailyMenus } from '../mocks/mock-diet.data';

@Service()
export class Diet {
  private readonly http = inject(HttpClient);

  getDailyMenus(): Observable<DailyMenu[]> {
    if (environment.useMocks) {
      return of(mockDailyMenus).pipe(delay(500));
    }
    return this.http.get<DailyMenu[]>(`${environment.apiUrl}/api/v1/diets/menus`);
  }
}
