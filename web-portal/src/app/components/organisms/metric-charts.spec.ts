import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import { Type } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MOCK_HEALTH_METRICS } from '../../core/mocks/mock-health-metrics.data';
import { DataPoint } from '../../core/charts/models/chart.model';
import { ActiveCaloriesBar } from './active-calories-bar/active-calories-bar';
import { BloodPressureScatter } from './blood-pressure-scatter/blood-pressure-scatter';
import { BmiArea } from './bmi-area/bmi-area';
import { GlucoseLine } from './glucose-line/glucose-line';
import { SleepQualityHeatmap } from './sleep-quality-heatmap/sleep-quality-heatmap';

const glucose: DataPoint[] = MOCK_HEALTH_METRICS.glucose
  .slice(0, 60)
  .map((reading) => ({ date: reading.date, value: reading.value }));
const bmi: DataPoint[] = MOCK_HEALTH_METRICS.bmi
  .slice(0, 60)
  .map((reading) => ({ date: reading.date, value: reading.value }));
const calories: DataPoint[] = MOCK_HEALTH_METRICS.activeCalories
  .slice(0, 60)
  .map((record) => ({ date: record.date, value: record.value }));

async function render<T>(
  component: Type<T>,
  inputs: Record<string, unknown>,
): Promise<ComponentFixture<T>> {
  await TestBed.configureTestingModule({ imports: [component] }).compileComponents();
  const fixture = TestBed.createComponent(component);
  for (const [key, value] of Object.entries(inputs)) {
    fixture.componentRef.setInput(key, value);
  }
  fixture.detectChanges();
  return fixture;
}

describe('blood-pressure-scatter', () => {
  it('renders a dot per systolic/diastolic reading plus reference bands', async () => {
    const fixture = await render(BloodPressureScatter, {
      data: MOCK_HEALTH_METRICS.bloodPressure.slice(0, 60),
    });
    expect(fixture.nativeElement.querySelectorAll('.metric-chart__dot')).toHaveLength(120);
    expect(fixture.nativeElement.querySelectorAll('.chart-reference-band')).toHaveLength(4);
  });
});

describe('glucose-line', () => {
  it('renders the area, the line and the target band', async () => {
    const fixture = await render(GlucoseLine, { data: glucose });
    expect(fixture.nativeElement.querySelector('.metric-chart__area')).not.toBeNull();
    expect(fixture.nativeElement.querySelectorAll('.metric-chart__line')).toHaveLength(1);
    expect(fixture.nativeElement.querySelectorAll('.chart-reference-band')).toHaveLength(1);
  });
});

describe('bmi-area', () => {
  it('renders the area with category bands', async () => {
    const fixture = await render(BmiArea, { data: bmi });
    expect(fixture.nativeElement.querySelector('.metric-chart__area')).not.toBeNull();
    expect(fixture.nativeElement.querySelectorAll('.chart-reference-band')).toHaveLength(4);
  });
});

describe('active-calories-bar', () => {
  it('renders one bar per day plus the rolling average', async () => {
    const fixture = await render(ActiveCaloriesBar, { data: calories });
    expect(fixture.nativeElement.querySelectorAll('.metric-chart__bar')).toHaveLength(60);
    expect(fixture.nativeElement.querySelector('.metric-chart__rolling')).not.toBeNull();
  });
});

describe('sleep-quality-heatmap', () => {
  it('renders one heatmap cell per night', async () => {
    const fixture = await render(SleepQualityHeatmap, {
      data: MOCK_HEALTH_METRICS.sleep.slice(0, 30),
    });
    expect(fixture.nativeElement.querySelectorAll('.metric-chart__heatmap-cell')).toHaveLength(30);
  });
});
