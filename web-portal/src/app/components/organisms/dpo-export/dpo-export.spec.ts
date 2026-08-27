import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AiInteraction } from '../../../core/models/interaction.model';
import { ExportService } from '../../../core/services/export.service';
import { DpoExport } from './dpo-export';

const interaction = (overrides: Partial<AiInteraction> = {}): AiInteraction => ({
  id: 'interaction-1',
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: 'thumbs_up',
  feedbackText: 'Great volume but reduce rest to 60s.',
  createdAt: '2026-08-17T09:30:00Z',
  model: 'llama3.2',
  status: 'completed',
  ...overrides,
});

describe('DpoExport', () => {
  let fixture: ComponentFixture<DpoExport>;
  let downloadSpy: ReturnType<typeof vi.fn>;

  beforeEach(async () => {
    downloadSpy = vi.fn();
    await TestBed.configureTestingModule({
      imports: [DpoExport],
      providers: [{ provide: ExportService, useValue: { downloadDpoDataset: downloadSpy } }],
    }).compileComponents();

    fixture = TestBed.createComponent(DpoExport);
    fixture.componentRef.setInput('interactions', []);
    fixture.detectChanges();
  });

  const button = (): HTMLButtonElement =>
    fixture.nativeElement.querySelector('button') as HTMLButtonElement;

  it('shows the eligible count on the button', () => {
    fixture.componentRef.setInput('interactions', [
      interaction({ rating: 'thumbs_up' }),
      interaction({ rating: null }),
      interaction({ feedbackText: null }),
    ]);
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain(
      'Export DPO Dataset (1)',
    );
  });

  it('disables the button when nothing is eligible', () => {
    fixture.componentRef.setInput('interactions', [
      interaction({ rating: null }),
      interaction({ feedbackText: null }),
    ]);
    fixture.detectChanges();

    expect(button().disabled).toBe(true);
  });

  it('enables the button when interactions are eligible', () => {
    fixture.componentRef.setInput('interactions', [
      interaction({ rating: 'thumbs_down', feedbackText: 'Shorten the sessions.' }),
    ]);
    fixture.detectChanges();

    expect(button().disabled).toBe(false);
  });

  it('triggers the export service with the full list when clicked', () => {
    const items = [interaction({ rating: 'thumbs_up' })];
    fixture.componentRef.setInput('interactions', items);
    fixture.detectChanges();

    button().click();

    expect(downloadSpy).toHaveBeenCalledWith(items);
  });

  it('does not trigger the export service when disabled', () => {
    fixture.componentRef.setInput('interactions', [interaction({ rating: null })]);
    fixture.detectChanges();

    button().click();

    expect(downloadSpy).not.toHaveBeenCalled();
  });
});