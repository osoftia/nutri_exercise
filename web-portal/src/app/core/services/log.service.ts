import { Service, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { LogQuery, PagedLogResponse } from '../models/log.model';
import { queryMockLogs } from '../mocks/mock-logs.data';

@Service()
export class LogService {
  private readonly http = inject(HttpClient);
  private readonly logsUrl = `${environment.apiUrl}/admin/logs`;

  getLogs(query: LogQuery): Observable<PagedLogResponse> {
    if (environment.useMocks) {
      return of(queryMockLogs(query)).pipe(delay(400));
    }

    return this.http.get<PagedLogResponse>(this.logsUrl, { params: toParams(query) });
  }
}

function toParams(query: LogQuery): HttpParams {
  let params = new HttpParams()
    .set('pageNumber', query.pageNumber)
    .set('pageSize', query.pageSize);

  if (query.logLevel && query.logLevel !== 'All') {
    params = params.set('logLevel', query.logLevel);
  }

  if (query.tag) {
    params = params.set('tag', query.tag);
  }

  if (query.startDate) {
    params = params.set('startDate', query.startDate);
  }

  if (query.endDate) {
    params = params.set('endDate', query.endDate);
  }

  return params;
}
