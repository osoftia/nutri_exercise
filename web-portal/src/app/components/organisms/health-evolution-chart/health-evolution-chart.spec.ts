import '@angular/compiler';
import { describe, expect, it } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';

import { MOCK_CLINICAL_EVOLUTION } from '../../../core/mocks/mock-clinical-evolution.data';
import { ClinicalEvolutionStore } from '../../../core/stores/clinical-evolution.store';
import { buildChartLayout } from '../../../core/utils/clinical-chart.util';
import { HealthEvolutionChart } from './health-evolution-chart';

async function build(): Promise<ComponentFixture<HealthEvolutionChart>> {
  const layout = buildChartLayout(MOCK_CLINICAL_EVOLUTION);
  await TestBed.configureTestingModule({
    imports: [HealthEvolutionChart],
    providers: [
      {
        provide: ClinicalEvolutionStore,
        useValue: {
          chartLayout: signal(layout),
          metric: signal(MOCK_CLINICAL_EVOLUTION.metric),
        },
      },
    ],
  }).compileComponents();
  const fixture = TestBed.createComponent(HealthEvolutionChart);
  fixture.detectChanges();
  return fixture;
}

describe('HealthEvolutionChart', () => {
  it('renders bars, both trend lines, the today marker and hover bands', async () => {
    const fixture = await build();
    const element: HTMLElement = fixture.nativeElement;

    expect(element.querySelectorAll('.evolution-chart__bar')).toHaveLength(8);
    expect(element.querySelectorAll('.evolution-chart__line')).toHaveLength(2);
    expect(element.querySelector('.evolution-chart__line--actual')).toBeTruthy();
    expect(element.querySelector('.evolution-chart__line--projected')).toBeTruthy();
    expect(element.querySelector('.evolution-chart__today')).toBeTruthy();
    expect(element.querySelectorAll('.evolution-chart__hit')).toHaveLength(12);
  });

  it('shows and hides the tooltip around the hovered band', async () => {
    const fixture = await build();
    const component = fixture.componentInstance;
    const layout = component.layout();

    expect(layout).not.toBeNull();
    expect(fixture.nativeElement.querySelector('.evolution-chart__tooltip')).toBeNull();

    component.hoverBand(layout!.bands[3]);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.evolution-chart__tooltip')).toBeTruthy();
    expect(component.isActiveBand(layout!.bands[3].key)).toBe(true);
    expect(component.isActiveBand(layout!.bands[4].key)).toBe(false);

    component.clearHover();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.evolution-chart__tooltip')).toBeNull();
  });
});
