import { describe, it, expect } from 'vitest';

import { AiInteraction } from '../models/interaction.model';
import { computeAnalytics } from './analytics.util';

const interaction = (overrides: Partial<AiInteraction> = {}): AiInteraction => ({
  id: 'interaction-1',
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: '2026-08-17T09:30:00Z',
  model: 'llama3.2',
  status: 'completed',
  ...overrides,
});

describe('computeAnalytics', () => {
  it('returns zeros for an empty list', () => {
    expect(computeAnalytics([])).toEqual({
      totalRoutines: 0,
      reviewedCount: 0,
      positiveCount: 0,
      negativeCount: 0,
      positivePercent: 0,
      negativePercent: 0,
    });
  });

  it('counts total routines and reviewed routines', () => {
    const analytics = computeAnalytics([
      interaction({ rating: 'thumbs_up' }),
      interaction({ rating: 'thumbs_down' }),
      interaction({ rating: null }),
      interaction({ rating: null }),
    ]);
    expect(analytics.totalRoutines).toBe(4);
    expect(analytics.reviewedCount).toBe(2);
    expect(analytics.positiveCount).toBe(1);
    expect(analytics.negativeCount).toBe(1);
  });

  it('computes percentages relative to reviewed routines only', () => {
    const analytics = computeAnalytics([
      interaction({ rating: 'thumbs_up' }),
      interaction({ rating: null }),
      interaction({ rating: null }),
    ]);
    expect(analytics.reviewedCount).toBe(1);
    expect(analytics.positivePercent).toBe(100);
    expect(analytics.negativePercent).toBe(0);
  });

  it('rounds percentages to whole numbers', () => {
    const analytics = computeAnalytics([
      interaction({ rating: 'thumbs_up' }),
      interaction({ rating: 'thumbs_down' }),
      interaction({ rating: 'thumbs_down' }),
    ]);
    expect(analytics.positivePercent).toBe(33);
    expect(analytics.negativePercent).toBe(67);
  });

  it('sums percentages to 100 when at least one routine is reviewed', () => {
    const analytics = computeAnalytics([
      interaction({ rating: 'thumbs_up' }),
      interaction({ rating: 'thumbs_up' }),
      interaction({ rating: 'thumbs_down' }),
      interaction({ rating: 'thumbs_down' }),
      interaction({ rating: 'thumbs_down' }),
      interaction({ rating: 'thumbs_down' }),
    ]);
    expect(analytics.positivePercent + analytics.negativePercent).toBe(100);
  });

  it('returns zero percentages when nothing has been reviewed', () => {
    const analytics = computeAnalytics([
      interaction({ rating: null }),
      interaction({ rating: null }),
    ]);
    expect(analytics.reviewedCount).toBe(0);
    expect(analytics.positivePercent).toBe(0);
    expect(analytics.negativePercent).toBe(0);
  });
});