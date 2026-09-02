import { describe, it, expect, beforeEach } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { mockAiPerformance } from '../../../core/mocks/mock-analytics.data';
import { AiPerformance } from '../../../core/models/analytics.model';
import { AiPerformanceComponent } from './ai-performance';

describe('AiPerformance', () => {
  let fixture: ComponentFixture<AiPerformanceComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AiPerformanceComponent] }).compileComponents();
    fixture = TestBed.createComponent(AiPerformanceComponent);
    fixture.componentRef.setInput('performance', null);
    fixture.componentRef.setInput('distribution', { positive: 0, negative: 0, reviewed: 0 });
    fixture.detectChanges();
  });

  it('shows a placeholder when there is no performance data', () => {
    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('No AI performance data yet.');
  });

  it('renders the average latency, token throughput, and total generations', () => {
    const performance: AiPerformance = mockAiPerformance;
    fixture.componentRef.setInput('performance', performance);
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Average Latency');
    expect(el.textContent).toContain('1842');
    expect(el.textContent).toContain('Token Throughput');
    expect(el.textContent).toContain('38');
    expect(el.textContent).toContain('Total Generations');
    expect(el.textContent).toContain(String(performance.totalGenerations));
  });

  it('renders one block per latency sample', () => {
    fixture.componentRef.setInput('performance', mockAiPerformance);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('app-bar-chart .bar-chart__group').length).toBe(
      mockAiPerformance.samples.length,
    );
  });

  it('renders the RLHF feedback distribution counts', () => {
    fixture.componentRef.setInput('performance', mockAiPerformance);
    fixture.componentRef.setInput('distribution', { positive: 3, negative: 1, reviewed: 4 });
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Positive');
    expect(el.textContent).toContain('Negative');
    expect(el.textContent).toContain('3');
    expect(el.textContent).toContain('1');
  });

  it('shows the distribution split segments', () => {
    fixture.componentRef.setInput('performance', mockAiPerformance);
    fixture.componentRef.setInput('distribution', { positive: 3, negative: 1, reviewed: 4 });
    fixture.detectChanges();

    const segments = fixture.nativeElement.querySelectorAll('.ai-performance__segment');
    expect(segments.length).toBe(2);
  });
});