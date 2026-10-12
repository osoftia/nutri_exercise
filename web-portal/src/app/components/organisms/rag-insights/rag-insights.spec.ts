import '@angular/compiler';
import { describe, expect, it, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HealthDashboardUiStore } from '../../../core/stores/health-dashboard-ui.store';
import { RagInsights } from './rag-insights';

async function build(): Promise<{ fixture: ComponentFixture<RagInsights>; ui: HealthDashboardUiStore }> {
  await TestBed.configureTestingModule({ imports: [RagInsights] }).compileComponents();
  const fixture = TestBed.createComponent(RagInsights);
  fixture.detectChanges();
  return { fixture, ui: TestBed.inject(HealthDashboardUiStore) };
}

describe('RagInsights', () => {
  it('renders the four categorized tables with rows', async () => {
    const { fixture } = await build();
    expect(fixture.nativeElement.querySelectorAll('.rag-report__category')).toHaveLength(4);
    expect(fixture.nativeElement.querySelectorAll('.rag-report__table')).toHaveLength(4);
    expect(
      fixture.nativeElement.querySelectorAll('.rag-report__row').length,
    ).toBeGreaterThanOrEqual(12);
  });

  it('deep-links a linked row to its chart and switches to the dashboard', async () => {
    const { fixture, ui } = await build();
    ui.setTab('rag');

    const linkedRow = fixture.nativeElement.querySelector(
      '.rag-report__row--linked',
    ) as HTMLTableRowElement;
    expect(linkedRow).not.toBeNull();
    linkedRow.click();
    fixture.detectChanges();

    expect(ui.activeTab()).toBe('dashboard');
    expect(ui.focusedChartId()).not.toBeNull();
    ui.clearFocus();
  });

  it('ignores clicks on rows without a chart link', async () => {
    const { fixture, ui } = await build();
    const unlinked = fixture.nativeElement.querySelectorAll(
      '.rag-report__row:not(.rag-report__row--linked)',
    ) as NodeListOf<HTMLTableRowElement>;
    expect(unlinked.length).toBeGreaterThan(0);

    unlinked[0].click();
    expect(ui.focusedChartId()).toBeNull();
  });

  it('builds and downloads the report PDF from the download button', async () => {
    const { fixture } = await build();
    const createSpy = vi.fn(() => 'blob:mock');
    const originalCreate = URL.createObjectURL;
    const originalRevoke = URL.revokeObjectURL;
    const clickSpy = vi
      .spyOn(HTMLAnchorElement.prototype, 'click')
      .mockImplementation(() => undefined);
    Object.defineProperty(URL, 'createObjectURL', { configurable: true, value: createSpy });
    Object.defineProperty(URL, 'revokeObjectURL', { configurable: true, value: () => undefined });

    try {
      const button = fixture.nativeElement.querySelector(
        '.rag-report__download',
      ) as HTMLButtonElement;
      button.click();
      fixture.detectChanges();
      expect(createSpy).toHaveBeenCalledTimes(1);
      expect(clickSpy).toHaveBeenCalledTimes(1);
      expect(button.disabled).toBe(false);
    } finally {
      clickSpy.mockRestore();
      Object.defineProperty(URL, 'createObjectURL', { configurable: true, value: originalCreate });
      Object.defineProperty(URL, 'revokeObjectURL', { configurable: true, value: originalRevoke });
    }
  });
});
