import { describe, it, expect } from 'vitest';

import { AiInteraction } from '../models/interaction.model';
import { filterInteractions } from './interaction-filter.util';

const iso = (year: number, month: number, day: number, hour = 12): string =>
  new Date(year, month - 1, day, hour).toISOString();

const item = (id: string, overrides: Partial<AiInteraction> = {}): AiInteraction => ({
  id,
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: iso(2026, 8, 16, 10),
  model: 'llama3.2',
  status: 'completed',
  ...overrides,
});

describe('filterInteractions', () => {
  const items = [
    item('a', { createdAt: iso(2026, 8, 16, 10) }),
    item('b', {
      userPrompt: 'Age: 35, Goal: fat_loss',
      generatedRoutine: 'Pull day\nDeadlift 3x5',
      createdAt: iso(2026, 8, 15, 9),
    }),
    item('c', {
      userPrompt: 'Age: 42, Goal: strength',
      generatedRoutine: 'HIIT circuits\nSprints 8x30s',
      createdAt: iso(2026, 8, 17, 14),
    }),
  ];

  it('returns everything when no filters are set', () => {
    expect(filterInteractions(items, { query: '', from: null, to: null })).toHaveLength(3);
  });

  it('matches the prompt case-insensitively', () => {
    const result = filterInteractions(items, { query: 'BUILD_MUSCLE', from: null, to: null });
    expect(result.map((i) => i.id)).toEqual(['a']);
  });

  it('matches the generated routine text', () => {
    const result = filterInteractions(items, { query: 'deadlift', from: null, to: null });
    expect(result.map((i) => i.id)).toEqual(['b']);
  });

  it('matches the model name', () => {
    const result = filterInteractions(items, { query: 'llama3.2', from: null, to: null });
    expect(result.map((i) => i.id)).toEqual(['a', 'b', 'c']);
  });

  it('trims surrounding whitespace from the query', () => {
    const result = filterInteractions(items, { query: '  push  ', from: null, to: null });
    expect(result.map((i) => i.id)).toEqual(['a']);
  });

  it('filters by a start date inclusively', () => {
    const from = new Date(2026, 7, 16, 12);
    const result = filterInteractions(items, { query: '', from, to: null });
    expect(result.map((i) => i.id)).toEqual(['a', 'c']);
  });

  it('filters by an end date inclusively', () => {
    const to = new Date(2026, 7, 15, 12);
    const result = filterInteractions(items, { query: '', from: null, to });
    expect(result.map((i) => i.id)).toEqual(['b']);
  });

  it('includes the same day when from equals to', () => {
    const from = new Date(2026, 7, 16, 12);
    const to = new Date(2026, 7, 16, 12);
    const result = filterInteractions(items, { query: '', from, to });
    expect(result.map((i) => i.id)).toEqual(['a']);
  });

  it('combines a query with a date range', () => {
    const from = new Date(2026, 7, 16, 12);
    const to = new Date(2026, 7, 17, 12);
    const result = filterInteractions(items, { query: 'age', from, to });
    expect(result.map((i) => i.id)).toEqual(['a', 'c']);
  });

  it('returns an empty list when nothing matches', () => {
    const result = filterInteractions(items, { query: 'zzz', from: null, to: null });
    expect(result).toHaveLength(0);
  });
});