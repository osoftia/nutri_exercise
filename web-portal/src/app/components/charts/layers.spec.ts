import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import { Type } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ChartAxisX } from './chart-axis-x/chart-axis-x';
import { ChartAxisY } from './chart-axis-y/chart-axis-y';
import { ChartGrid } from './chart-grid/chart-grid';
import { ChartLegend } from './chart-legend/chart-legend';
import { ChartReferenceBands } from './chart-reference-bands/chart-reference-bands';
import { ChartTooltip } from './chart-tooltip/chart-tooltip';

const PLOT = { x: 40, y: 20, width: 600, height: 240 };
const TICKS = [
  { value: 0, position: 260, label: '0' },
  { value: 50, position: 20, label: '50' },
];

async function create<T>(component: Type<T>): Promise<ComponentFixture<T>> {
  await TestBed.configureTestingModule({ imports: [component] }).compileComponents();
  return TestBed.createComponent(component);
}

describe('chart layers', () => {
  it('renders grid lines per y tick', async () => {
    const fixture = await create(ChartGrid);
    fixture.componentRef.setInput('plot', PLOT);
    fixture.componentRef.setInput('yTicks', TICKS);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelectorAll('.chart-grid__line')).toHaveLength(2);
  });

  it('renders y axis labels on the requested side', async () => {
    const fixture = await create(ChartAxisY);
    fixture.componentRef.setInput('plot', PLOT);
    fixture.componentRef.setInput('ticks', TICKS);
    fixture.componentRef.setInput('side', 'right');
    fixture.detectChanges();
    const labels = fixture.nativeElement.querySelectorAll('.chart-axis-y__label');
    expect(labels).toHaveLength(2);
    expect(labels[0].getAttribute('text-anchor')).toBe('start');
  });

  it('renders x axis labels', async () => {
    const fixture = await create(ChartAxisX);
    fixture.componentRef.setInput('plot', PLOT);
    fixture.componentRef.setInput('ticks', TICKS);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelectorAll('.chart-axis-x__label')).toHaveLength(2);
  });

  it('renders reference bands with tone data attributes', async () => {
    const fixture = await create(ChartReferenceBands);
    fixture.componentRef.setInput('plot', PLOT);
    fixture.componentRef.setInput('bands', [
      { from: 70, to: 99, label: 'glucose.target', tone: 'success', y: 40, height: 60 },
    ]);
    fixture.detectChanges();
    const rect = fixture.nativeElement.querySelector('.chart-reference-band');
    expect(rect).not.toBeNull();
    expect(rect.getAttribute('data-tone')).toBe('success');
  });

  it('renders tooltip box and lines', async () => {
    const fixture = await create(ChartTooltip);
    fixture.componentRef.setInput('x', 10);
    fixture.componentRef.setInput('y', 20);
    fixture.componentRef.setInput('width', 160);
    fixture.componentRef.setInput('height', 50);
    fixture.componentRef.setInput('lines', ['2026-08-17', 'Cholesterol: 198 mg/dL']);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.chart-tooltip__box')).not.toBeNull();
    expect(fixture.nativeElement.querySelectorAll('.chart-tooltip__line')).toHaveLength(2);
  });

  it('renders legend items', async () => {
    const fixture = await create(ChartLegend);
    fixture.componentRef.setInput('items', [
      { label: 'bp.systolic', variant: 'dot' },
      { label: 'bp.diastolic', variant: 'line' },
    ]);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelectorAll('.chart-legend__item')).toHaveLength(2);
  });
});
