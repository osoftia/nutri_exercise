import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { mockTelemetrySnapshot } from '../../../core/mocks/mock-analytics.data';
import { TelemetrySnapshot } from '../../../core/models/analytics.model';
import { MobileUsage } from './mobile-usage';

describe('MobileUsage', () => {
  let fixture: ComponentFixture<MobileUsage>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [MobileUsage] }).compileComponents();
    fixture = TestBed.createComponent(MobileUsage);
    fixture.componentRef.setInput('snapshot', null);
    fixture.componentRef.setInput('loading', false);
    fixture.detectChanges();
  });

  it('shows a spinner while loading', () => {
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('mat-spinner')).not.toBeNull();
  });

  it('shows an error state with a retry action when there is no snapshot', () => {
    const spy = vi.fn();
    fixture.componentInstance.retry.subscribe(spy);
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Could not load mobile telemetry.');

    const button = Array.from(el.querySelectorAll('button')).find(
      (b) => b.textContent?.trim() === 'Retry',
    );
    button?.click();
    expect(spy).toHaveBeenCalledTimes(1);
  });

  it('renders the active workout sessions, pending sync items, and last sync time', () => {
    fixture.componentRef.setInput('snapshot', mockTelemetrySnapshot);
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Active Workout Sessions');
    expect(el.textContent).toContain('3');
    expect(el.textContent).toContain('Pending Offline Sync Items');
    expect(el.textContent).toContain('2');
    expect(el.textContent).toContain('Last Sync');
  });

  it('renders one telemetry event row per event', () => {
    fixture.componentRef.setInput('snapshot', mockTelemetrySnapshot);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('tbody tr').length).toBe(
      mockTelemetrySnapshot.events.length,
    );
  });

  it('shows an empty state when there are no telemetry events', () => {
    const empty: TelemetrySnapshot = {
      activeWorkoutSessions: 0,
      pendingSyncItems: 0,
      lastSyncAt: null,
      events: [],
    };
    fixture.componentRef.setInput('snapshot', empty);
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('No telemetry events yet.');
    expect(fixture.nativeElement.querySelectorAll('tbody tr').length).toBe(0);
  });
});