import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { DbTable, DbTableRow, VectorMatch } from '../models/analytics.model';
import { mockDbTables, mockRowsByTable, mockSemanticSearch } from '../mocks/mock-analytics.data';

@Service()
export class DatabaseService {
  private readonly http = inject(HttpClient);
  private readonly dbUrl = `${environment.apiUrl}/db`;

  getTables(): Observable<DbTable[]> {
    if (environment.useMocks) {
      return of(mockDbTables).pipe(delay(400));
    }
    return this.http.get<DbTable[]>(`${this.dbUrl}/tables`);
  }

  getTableRows(tableName: string): Observable<DbTableRow[]> {
    if (environment.useMocks) {
      return of(mockRowsByTable[tableName] ?? []).pipe(delay(400));
    }
    return this.http.get<DbTableRow[]>(`${this.dbUrl}/tables/${tableName}/rows`);
  }

  searchVectors(query: string, k = 5): Observable<VectorMatch[]> {
    if (environment.useMocks) {
      return of(mockSemanticSearch(query)).pipe(delay(400));
    }
    return this.http.post<VectorMatch[]>(`${this.dbUrl}/vector/search`, { query, k });
  }
}