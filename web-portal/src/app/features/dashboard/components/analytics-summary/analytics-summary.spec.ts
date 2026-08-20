import { describe, it, expect, beforeEach } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AnalyticsMetrics } from '../../../../core/utils/analytics.util';
import { AnalyticsSummary } from './analytics-summary';

const metrics: AnalyticsMetrics = {
  totalRoutines: 5,
  reviewedCount: 3,
  positiveCount: 2,
  negativeCount: 1,
  positivePercent: 67,
  negativePercent: 33,
};

describe('AnalyticsSummary', () => {
  let fixture: ComponentFixture<AnalyticsSummary>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AnalyticsSummary] }).compileComponents();
    fixture = TestBed.createComponent(AnalyticsSummary);
    fixture.componentRef.setInput('analytics', metrics);
    fixture.detectChanges();
  });

  it('renders the total routines generated', () => {
    expect((fixture.nativeElement as HTMLElement).textContent).toContain(
      'Total Routines Generated',
    );
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('5');
  });

  it('renders the total reviewed', () => {
    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Total Reviewed');
    expect(el.textContent).toContain('3');
  });

  it('renders the positive and negative percentages', () => {
    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Positive');
    expect(el.textContent).toContain('67%');
    expect(el.textContent).toContain('Negative');
    expect(el.textContent).toContain('33%');
  });

  it('renders the editorial solid blocks', () => {
    expect(fixture.nativeElement.querySelectorAll('.analytics-summary__block').length).toBe(2);
    expect(fixture.nativeElement.querySelectorAll('.analytics-summary__split-tile').length).toBe(
      2,
    );
  });

  it('updates reactively when the metrics input changes', () => {
    fixture.componentRef.setInput('analytics', {
      ...metrics,
      reviewedCount: 4,
      positivePercent: 75,
      negativePercent: 25,
    });
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('75%');
    expect(el.textContent).toContain('25%');
  });
});