import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { of, Subject, throwError } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';

import { AiInteraction } from '../models/interaction.model';
import { InteractionService } from '../services/interaction.service';
import { DashboardStore } from './dashboard.store';

const interaction = (id: string, feedbackText: string | null = null): AiInteraction => ({
  id,
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText,
  createdAt: '2026-08-17T09:30:00Z',
  model: 'llama3.2',
  status: 'completed',
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
    getSubject.next([interaction('a', 'Great volume'), interaction('b')]);
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
    const updated = interaction('a', 'Nice volume');
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

  it('resets all state', () => {
    store.load();
    getSubject.next([interaction('a')]);
    getSubject.complete();

    store.reset();

    expect(store.interactions()).toHaveLength(0);
    expect(store.loading()).toBe(false);
    expect(store.error()).toBeNull();
    expect(store.submittingIds().size).toBe(0);
  });
});