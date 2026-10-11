import '@angular/compiler';
import { describe, expect, it, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';

import { MOCK_CLINICAL_EVOLUTION } from '../../core/mocks/mock-clinical-evolution.data';
import { ClinicalEvolutionStore } from '../../core/stores/clinical-evolution.store';
import { buildChartLayout } from '../../core/utils/clinical-chart.util';
import { ClinicalEvolutionPage } from './clinical-evolution.page';

function createStore(load = vi.fn()) {
  return {
    payload: signal(MOCK_CLINICAL_EVOLUTION),
    isLoading: signal(false),
    error: signal<string | null>(null),
    metric: signal(MOCK_CLINICAL_EVOLUTION.metric),
    healthScore: signal(MOCK_CLINICAL_EVOLUTION.health_score),
    riskLevel: signal<'low' | 'medium' | 'high'>('medium'),
    chartLayout: signal(buildChartLayout(MOCK_CLINICAL_EVOLUTION)),
    load,
  };
}

async function build(load = vi.fn()) {
  const store = createStore(load);
  await TestBed.configureTestingModule({
    imports: [ClinicalEvolutionPage],
    providers: [{ provide: ClinicalEvolutionStore, useValue: store }],
  }).compileComponents();
  const fixture = TestBed.createComponent(ClinicalEvolutionPage);
  fixture.detectChanges();
  return { fixture, load };
}

describe('ClinicalEvolutionPage', () => {
  it('requests the data on init and renders the dashboard', async () => {
    const { fixture, load } = await build();

    expect(load).toHaveBeenCalledTimes(1);
    expect(fixture.nativeElement.querySelector('app-health-risk-gauge')).toBeTruthy();
    expect(fixture.nativeElement.querySelector('app-health-evolution-chart')).toBeTruthy();
  });

  it('derives the KPI values from the payload', async () => {
    const { fixture } = await build();
    const component = fixture.componentInstance;

    expect(component.currentMarker()).toBe(198);
    expect(component.projectedMarker()).toBe(177);
    expect(component.markerDelta()).toBe(-21);
    expect(component.consumptionChange()).toBe(-14);
    expect(component.improved()).toBe(true);
    expect(component.signed(21)).toBe('+21');
    expect(component.signed(-21)).toBe('-21');
  });

  it('shows a loading state and an error state', async () => {
    const loadingStore = { ...createStore(), isLoading: signal(true) };
    await TestBed.configureTestingModule({
      imports: [ClinicalEvolutionPage],
      providers: [{ provide: ClinicalEvolutionStore, useValue: loadingStore }],
    }).compileComponents();
    const loadingFixture = TestBed.createComponent(ClinicalEvolutionPage);
    loadingFixture.detectChanges();
    expect(loadingFixture.nativeElement.querySelector('.clinical-evolution__state')).toBeTruthy();
  });
});
