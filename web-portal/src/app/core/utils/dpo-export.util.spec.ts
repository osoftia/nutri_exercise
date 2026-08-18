import { describe, it, expect } from 'vitest';

import { AiInteraction } from '../models/interaction.model';
import {
  buildDpoFileName,
  buildDpoJsonl,
  isDpoEligible,
  toDpoRow,
} from './dpo-export.util';

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

describe('isDpoEligible', () => {
  it('accepts an interaction with a rating and feedback', () => {
    expect(isDpoEligible(interaction())).toBe(true);
  });

  it('rejects an interaction without a rating', () => {
    expect(isDpoEligible(interaction({ rating: null }))).toBe(false);
  });

  it('rejects an interaction without feedback', () => {
    expect(isDpoEligible(interaction({ feedbackText: null }))).toBe(false);
  });

  it('rejects an interaction with blank feedback', () => {
    expect(isDpoEligible(interaction({ feedbackText: '   ' }))).toBe(false);
  });
});

describe('toDpoRow', () => {
  it('maps a thumbs-up interaction with the routine as chosen', () => {
    const row = toDpoRow(interaction());
    expect(row.prompt).toBe('Age: 28, Goal: build_muscle, Level: intermediate');
    expect(row.chosen).toBe('Weekly routine\nDay 1 - Push: Bench press 4x8');
    expect(row.rejected).toBe('Great volume but reduce rest to 60s.');
    expect(row.model).toBe('llama3.2');
    expect(row.interaction_id).toBe('interaction-1');
    expect(row.created_at).toBe('2026-08-17T09:30:00Z');
  });

  it('maps a thumbs-down interaction with the feedback as chosen', () => {
    const row = toDpoRow(
      interaction({ rating: 'thumbs_down', feedbackText: 'Too much volume, reduce sets.' }),
    );
    expect(row.chosen).toBe('Too much volume, reduce sets.');
    expect(row.rejected).toBe('Weekly routine\nDay 1 - Push: Bench press 4x8');
  });
});

describe('buildDpoJsonl', () => {
  it('returns an empty string when nothing is eligible', () => {
    const items = [
      interaction({ rating: null }),
      interaction({ feedbackText: null }),
    ];
    expect(buildDpoJsonl(items)).toBe('');
  });

  it('outputs one JSON object per eligible interaction', () => {
    const items = [
      interaction({ id: 'a', rating: 'thumbs_up' }),
      interaction({ id: 'b', rating: 'thumbs_down', feedbackText: 'Shorten the sessions.' }),
      interaction({ id: 'c', rating: null }),
    ];
    const jsonl = buildDpoJsonl(items);
    const lines = jsonl.trimEnd().split('\n');

    expect(lines).toHaveLength(2);
    const parsed = lines.map((line) => JSON.parse(line));
    expect(parsed.map((row) => row.interaction_id)).toEqual(['a', 'b']);
  });

  it('escapes newlines and quotes inside string fields', () => {
    const jsonl = buildDpoJsonl([
      interaction({ generatedRoutine: 'Line one\nLine "two"' }),
    ]);
    const parsed = JSON.parse(jsonl.trimEnd());
    expect(parsed.chosen).toBe('Line one\nLine "two"');
  });

  it('ends with a trailing newline', () => {
    const jsonl = buildDpoJsonl([interaction()]);
    expect(jsonl.endsWith('\n')).toBe(true);
  });
});

describe('buildDpoFileName', () => {
  it('formats the filename with a local date', () => {
    const name = buildDpoFileName(new Date(2026, 7, 5));
    expect(name).toBe('dpo-dataset-2026-08-05.jsonl');
  });

  it('pads months and days to two digits', () => {
    const name = buildDpoFileName(new Date(2026, 0, 9));
    expect(name).toBe('dpo-dataset-2026-01-09.jsonl');
  });
});