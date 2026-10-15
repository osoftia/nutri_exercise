import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import {
  provideHttpClient,
  withInterceptors,
} from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';

import { environment } from '../../../environments/environment';
import { LogQuery, PagedLogResponse } from '../models/log.model';
import { errorInterceptor } from '../interceptors/error.interceptor';
import { LogService } from './log.service';

const baseQuery: LogQuery = { pageNumber: 1, pageSize: 10 };

describe('LogService', () => {
  let service: LogService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        LogService,
        provideHttpClient(withInterceptors([errorInterceptor])),
        provideHttpClientTesting(),
      ],
    });
    service = TestBed.inject(LogService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    environment.useMocks = true;
    vi.useRealTimers();
    http.verify();
  });

  describe('mock mode', () => {
    it('returns filtered log pages', async () => {
      vi.useFakeTimers();
      const result = firstValueFrom(service.getLogs({ ...baseQuery, logLevel: 'Error' }));
      await vi.advanceTimersByTimeAsync(400);

      const response: PagedLogResponse = await result;
      expect(response.totalCount).toBeGreaterThan(0);
      expect(response.items.every((entry) => entry.level === 'Error')).toBe(true);
    });
  });

  describe('http mode', () => {
    beforeEach(() => {
      environment.useMocks = false;
    });

    it('GETs logs with the filter query parameters', () => {
      let result: PagedLogResponse | undefined;
      service
        .getLogs({
          logLevel: 'Error',
          tag: '[RAG-ERROR]',
          startDate: '2026-10-01T00:00:00Z',
          pageNumber: 2,
          pageSize: 25,
        })
        .subscribe((data) => (result = data));

      const req = http.expectOne(
        (request) => request.url === 'http://localhost:5000/api/admin/logs',
      );
      expect(req.request.method).toBe('GET');
      expect(req.request.params.get('logLevel')).toBe('Error');
      expect(req.request.params.get('tag')).toBe('[RAG-ERROR]');
      expect(req.request.params.get('pageNumber')).toBe('2');
      expect(req.request.params.get('pageSize')).toBe('25');

      const payload: PagedLogResponse = {
        items: [],
        pageNumber: 2,
        pageSize: 25,
        totalCount: 0,
      };
      req.flush(payload);

      expect(result?.pageNumber).toBe(2);
    });

    it('omits the level parameter when set to All', () => {
      service.getLogs({ ...baseQuery, logLevel: 'All' }).subscribe();

      const req = http.expectOne(
        (request) => request.url === 'http://localhost:5000/api/admin/logs',
      );
      expect(req.request.params.has('logLevel')).toBe(false);

      req.flush({ items: [], pageNumber: 1, pageSize: 10, totalCount: 0 });
    });
  });
});
