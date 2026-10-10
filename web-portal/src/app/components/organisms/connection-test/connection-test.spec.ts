import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { environment } from '../../../../environments/environment';
import { ConnectionResult, HealthService } from '../../../core/services/health.service';
import { ConnectionTest } from './connection-test';

describe('ConnectionTest', () => {
  let fixture: ComponentFixture<ConnectionTest>;
  let component: ConnectionTest;
  let checkSubject: Subject<ConnectionResult>;
  let healthService: { checkConnection: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    checkSubject = new Subject<ConnectionResult>();
    healthService = { checkConnection: vi.fn(() => checkSubject.asObservable()) };

    await TestBed.configureTestingModule({
      imports: [ConnectionTest],
      providers: [{ provide: HealthService, useValue: healthService }],
    }).compileComponents();

    fixture = TestBed.createComponent(ConnectionTest);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('starts idle showing the backend URL', () => {
    expect(component.status()).toBe('idle');
    expect(component.headline()).toBe('READY');
    expect(fixture.nativeElement.textContent).toContain(environment.backendUrl);
  });

  it('shows checking state while the request is in flight', () => {
    component.testConnection();
    fixture.detectChanges();

    expect(component.status()).toBe('checking');
    expect(component.isChecking()).toBe(true);
    expect(component.headline()).toBe('…');
    expect(healthService.checkConnection).toHaveBeenCalledTimes(1);
  });

  it('ignores repeated clicks while checking', () => {
    component.testConnection();
    component.testConnection();
    expect(healthService.checkConnection).toHaveBeenCalledTimes(1);
  });

  it('renders ONLINE with latency when the Mac answers', () => {
    component.testConnection();
    checkSubject.next({ state: 'online', latencyMs: 42, detail: 'Reachable (HTTP 200).' });
    checkSubject.complete();
    fixture.detectChanges();

    expect(component.status()).toBe('online');
    expect(component.latencyMs()).toBe(42);
    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('ONLINE');
    expect(text).toContain('42');
  });

  it('renders OFFLINE with the failure detail on unreachable', () => {
    component.testConnection();
    checkSubject.next({ state: 'unreachable', latencyMs: null, detail: 'No response: CORS block.' });
    checkSubject.complete();
    fixture.detectChanges();

    expect(component.status()).toBe('unreachable');
    expect(component.headline()).toBe('OFFLINE');
    expect(fixture.nativeElement.textContent).toContain('CORS block');
  });
});
