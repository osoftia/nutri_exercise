import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { of, Subject, throwError } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';

import { AiInteraction } from '../models/interaction.model';
import { InteractionService } from '../services/interaction.service';
import { DashboardStore } from './dashboard.store';

const iso = (year: number, month: number, day: number, hour = 12): string =>
  new Date(year, month - 1, day, hour).toISOString();

const interaction = (id: string, overrides: Partial<AiInteraction> = {}): AiInteraction => ({
  id,
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: iso(2026, 8, 17, 9),
  model: 'llama3.2',
  status: 'completed',
  ...overrides,
});

describe('DashboardStore', () => {
  let getSubject: Subject<AiInteraction[]>;
  let service: { getInteractions: ReturnType<typeof vi.fn>; updateFeedback: ReturnType<typeof vi.fn> };
  let snackBar: { open: ReturnType<typeof vi.fn> };
  let store: DashboardStore;

  beforeEach(() => {
    getSubject = new Subject<AiInteraction[]>();
    service = { getInteractions: vi.fn(), updateFeedback: vi.fn() };
    service.getInteractions.mockReturnValue(getSubject.asObservable());
    snackBar = { open: vi.fn() };

    TestBed.configureTestingModule({
      providers: [
        DashboardStore,
        { provide: InteractionService, useValue: service },
        { provide: MatSnackBar, useValue: snackBar },
      ],
    });

    store = TestBed.inject(DashboardStore);
  });

  it('loads interactions and stops loading', () => {
    store.load();
    expect(store.loading()).toBe(true);

    getSubject.next([interaction('a'), interaction('b')]);
    getSubject.complete();

    expect(store.loading()).toBe(false);
    expect(store.error()).toBeNull();
    expect(store.interactions()).toHaveLength(2);
    expect(store.total()).toBe(2);
  });

  it('computes totals and feedback count', () => {
    store.load();
    getSubject.next([interaction('a', { feedbackText: 'Great volume' }), interaction('b')]);
    getSubject.complete();

    expect(store.total()).toBe(2);
    expect(store.hasFeedback()).toBe(1);
  });

  it('surfaces an error when loading fails', () => {
    store.load();
    getSubject.error(new Error('boom'));

    expect(store.loading()).toBe(false);
    expect(store.error()).toBe('Could not load AI-generated routines.');
    expect(store.interactions()).toHaveLength(0);
  });

  it('retry reloads after an error', () => {
    store.load();
    getSubject.error(new Error('boom'));

    store.retry();

    expect(service.getInteractions).toHaveBeenCalledTimes(2);
  });

  it('applies feedback and shows a success snackbar', () => {
    const updated = interaction('a', { feedbackText: 'Nice volume' });
    service.updateFeedback.mockReturnValue(of(updated));

    store.load();
    getSubject.next([interaction('a')]);
    getSubject.complete();

    store.submitFeedback('a', 'Nice volume');

    expect(service.updateFeedback).toHaveBeenCalledWith('a', { feedbackText: 'Nice volume' });
    expect(store.interactions()[0].feedbackText).toBe('Nice volume');
    expect(store.submittingIds().has('a')).toBe(false);
    expect(snackBar.open).toHaveBeenCalledWith('Feedback saved.', 'OK', { duration: 3000 });
  });

  it('keeps the interaction unchanged and shows an error snackbar on failure', () => {
    service.updateFeedback.mockReturnValue(throwError(() => new Error('boom')));

    store.load();
    getSubject.next([interaction('a')]);
    getSubject.complete();

    store.submitFeedback('a', 'Nice volume');

    expect(store.interactions()[0].feedbackText).toBeNull();
    expect(store.submittingIds().has('a')).toBe(false);
    expect(snackBar.open).toHaveBeenCalledWith(
      'Could not save feedback. Please try again.',
      'OK',
      { duration: 5000 },
    );
  });

  it('filters visible interactions by search query', () => {
    store.load();
    getSubject.next([
      interaction('a', { generatedRoutine: 'Push day\nBench press 4x8' }),
      interaction('b', { generatedRoutine: 'Pull day\nDeadlift 3x5' }),
    ]);
    getSubject.complete();

    store.setSearchQuery('push');

    expect(store.visibleInteractions().map((i) => i.id)).toEqual(['a']);
    expect(store.visibleTotal()).toBe(1);
    expect(store.filtersActive()).toBe(true);
  });

  it('filters visible interactions by a date range', () => {
    store.load();
    getSubject.next([
      interaction('a', { createdAt: iso(2026, 8, 16, 10) }),
      interaction('b', { createdAt: iso(2026, 8, 15, 9) }),
    ]);
    getSubject.complete();

    store.setDateRange(new Date(2026, 7, 16, 12), new Date(2026, 7, 16, 12));

    expect(store.visibleInteractions().map((i) => i.id)).toEqual(['a']);
  });

  it('applies query and date range together', () => {
    store.load();
    getSubject.next([
      interaction('a', { generatedRoutine: 'Push day\nBench press 4x8', createdAt: iso(2026, 8, 16, 10) }),
      interaction('b', { generatedRoutine: 'Pull day\nDeadlift 3x5', createdAt: iso(2026, 8, 15, 9) }),
    ]);
    getSubject.complete();

    store.setSearchQuery('push');
    store.setDateRange(new Date(2026, 7, 16, 12), null);

    expect(store.visibleInteractions().map((i) => i.id)).toEqual(['a']);
  });

  it('clearFilters resets every filter', () => {
    store.load();
    getSubject.next([
      interaction('a', { generatedRoutine: 'Push day\nBench press 4x8' }),
      interaction('b', { generatedRoutine: 'Pull day\nDeadlift 3x5' }),
    ]);
    getSubject.complete();

    store.setSearchQuery('push');
    store.setDateRange(new Date(2026, 7, 16, 12), new Date(2026, 7, 18, 12));

    expect(store.filtersActive()).toBe(true);
    expect(store.visibleTotal()).toBe(1);

    store.clearFilters();

    expect(store.filtersActive()).toBe(false);
    expect(store.visibleTotal()).toBe(2);
  });

  it('computes the exportable interactions and count', () => {
    store.load();
    getSubject.next([
      interaction('a', { rating: 'thumbs_up', feedbackText: 'Great volume.' }),
      interaction('b', { rating: 'thumbs_down', feedbackText: 'Too short.' }),
      interaction('c', { rating: 'thumbs_up', feedbackText: null }),
      interaction('d', { rating: null, feedbackText: 'No rating.' }),
    ]);
    getSubject.complete();

    expect(store.exportableInteractions().map((i) => i.id)).toEqual(['a', 'b']);
    expect(store.exportableCount()).toBe(2);
  });

  it('grows the exportable count when feedback is submitted', () => {
    const updated = interaction('a', { rating: 'thumbs_up', feedbackText: 'Nice volume' });
    service.updateFeedback.mockReturnValue(of(updated));

    store.load();
    getSubject.next([interaction('a')]);
    getSubject.complete();

    expect(store.exportableCount()).toBe(0);

    store.submitFeedback('a', 'Nice volume');

    expect(store.exportableCount()).toBe(1);
  });

  it('reset clears the loaded data and all filters', () => {
    store.load();
    getSubject.next([interaction('a')]);
    getSubject.complete();
    store.setSearchQuery('push');
    store.setDateRange(new Date(2026, 7, 16, 12), null);

    store.reset();

    expect(store.interactions()).toHaveLength(0);
    expect(store.loading()).toBe(false);
    expect(store.error()).toBeNull();
    expect(store.submittingIds().size).toBe(0);
    expect(store.searchQuery()).toBe('');
    expect(store.dateFrom()).toBeNull();
    expect(store.dateTo()).toBeNull();
  });
});