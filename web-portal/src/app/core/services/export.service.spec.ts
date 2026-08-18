import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { AiInteraction } from '../models/interaction.model';
import { ExportService } from './export.service';

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

describe('ExportService', () => {
  let service: ExportService;
  let createObjectUrl: ReturnType<typeof vi.fn>;
  let revokeObjectUrl: ReturnType<typeof vi.fn>;
  let clickSpy: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    createObjectUrl = vi.fn(() => 'blob:mock-url');
    revokeObjectUrl = vi.fn();
    URL.createObjectURL = createObjectUrl as unknown as typeof URL.createObjectURL;
    URL.revokeObjectURL = revokeObjectUrl as unknown as typeof URL.revokeObjectURL;
    clickSpy = vi.fn();
    HTMLAnchorElement.prototype.click = clickSpy as unknown as () => void;

    TestBed.configureTestingModule({ providers: [ExportService] });
    service = TestBed.inject(ExportService);
  });

  it('creates a download link and triggers a click', () => {
    const appendChild = vi.spyOn(document.body, 'appendChild');

    service.downloadDpoDataset([interaction()]);

    const anchor = appendChild.mock.calls[0][0] as HTMLAnchorElement;
    expect(createObjectUrl).toHaveBeenCalledTimes(1);
    expect(anchor.href).toBe('blob:mock-url');
    expect(anchor.download).toMatch(/^dpo-dataset-\d{4}-\d{2}-\d{2}\.jsonl$/);
    expect(clickSpy).toHaveBeenCalledTimes(1);
    expect(revokeObjectUrl).toHaveBeenCalledWith('blob:mock-url');
  });

  it('exports eligible interactions as NDJSON content', async () => {
    service.downloadDpoDataset([
      interaction({ id: 'a', rating: 'thumbs_up' }),
      interaction({ id: 'b', rating: 'thumbs_down', feedbackText: 'Too short.' }),
      interaction({ id: 'c', rating: null }),
    ]);

    const blob = createObjectUrl.mock.calls[0][0] as Blob;
    expect(blob.type).toBe('application/x-ndjson');
    const content = await blob.text();
    const lines = content.trimEnd().split('\n');
    expect(lines).toHaveLength(2);
    expect(JSON.parse(lines[0])).toMatchObject({ interaction_id: 'a' });
    expect(JSON.parse(lines[1])).toMatchObject({ interaction_id: 'b' });
  });

  it('does nothing when no interaction is eligible', () => {
    service.downloadDpoDataset([
      interaction({ rating: null }),
      interaction({ feedbackText: null }),
      interaction({ feedbackText: '   ' }),
    ]);

    expect(createObjectUrl).not.toHaveBeenCalled();
    expect(clickSpy).not.toHaveBeenCalled();
    expect(revokeObjectUrl).not.toHaveBeenCalled();
  });
});