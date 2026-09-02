import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import {
  HttpClient,
  HttpErrorResponse,
  provideHttpClient,
  withInterceptors,
} from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';

import { errorInterceptor } from './error.interceptor';

describe('errorInterceptor', () => {
  let http: HttpClient;
  let controller: HttpTestingController;
  let consoleError: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    consoleError = vi.spyOn(console, 'error').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([errorInterceptor])),
        provideHttpClientTesting(),
      ],
    });
    http = TestBed.inject(HttpClient);
    controller = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    consoleError.mockRestore();
    controller.verify();
  });

  it('logs the error and rethrows it to the caller', () => {
    let caught: unknown;
    http.get('/api/interactions').subscribe({ error: (err) => (caught = err) });

    const req = controller.expectOne('/api/interactions');
    req.flush('boom', { status: 500, statusText: 'Server Error' });

    expect(consoleError).toHaveBeenCalled();
    expect(caught).toBeInstanceOf(HttpErrorResponse);
    expect((caught as HttpErrorResponse).status).toBe(500);
  });
});