import { describe, it, expect, beforeEach } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BarChart } from './bar-chart';

describe('BarChart', () => {
  let fixture: ComponentFixture<BarChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [BarChart] }).compileComponents();
    fixture = TestBed.createComponent(BarChart);
    fixture.componentRef.setInput('data', []);
    fixture.detectChanges();
  });

  it('renders one progress block per data point', () => {
    fixture.componentRef.setInput('data', [
      { label: 'gen-1', value: 100 },
      { label: 'gen-2', value: 200 },
      { label: 'gen-3', value: 300 },
    ]);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('.bar-chart__group').length).toBe(3);
  });

  it('renders nothing when there is no data', () => {
    fixture.componentRef.setInput('data', []);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('.bar-chart__group').length).toBe(0);
    expect(fixture.nativeElement.querySelectorAll('rect').length).toBe(0);
  });

  it('normalizes block heights relative to the maximum value', () => {
    fixture.componentRef.setInput('data', [
      { label: 'gen-1', value: 50 },
      { label: 'gen-2', value: 100 },
    ]);
    fixture.detectChanges();

    const blocks = Array.from(fixture.nativeElement.querySelectorAll('.bar-chart__block')).map(
      (rect) => Number((rect as SVGRectElement).getAttribute('height')),
    );
    expect(blocks[0]).toBeLessThan(blocks[1]);
    expect(blocks[1]).toBeGreaterThan(0);
  });

  it('marks the chart with an accessible label', () => {
    const svg = fixture.nativeElement.querySelector('svg');
    expect(svg?.getAttribute('role')).toBe('img');
    expect(svg?.getAttribute('aria-label')).toBeTruthy();
  });
});
