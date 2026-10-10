import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { TelemetryService } from '../services/telemetry.service';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const telemetry = inject(TelemetryService);
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      telemetry.error(`[HTTP ${error.status}] ${req.method} ${req.url}`, error.message);
      return throwError(() => error);
    }),
  );
};