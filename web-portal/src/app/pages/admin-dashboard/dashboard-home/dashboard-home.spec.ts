import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { of, Subject } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';

import { DashboardHome } from './dashboard-home';
import { DashboardStore } from '../../../core/stores/dashboard.store';
import { Diet } from '../../../core/services/diet';
import { ExportService } from '../../../core/services/export.service';
import { InteractionService } from '../../../core/services/interaction.service';
import { Routine } from '../../../core/services/routine';
import { AiInteraction } from '../../../core/models/interaction.model';

const interaction = (id: string, overrides: Partial<AiInteraction> = {}): AiInteraction => ({
  id,
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: '2026-08-17T09:30:00Z',
  model: 'llama3.2',
  status: 'completed',
  ...overrides,
});

describe('DashboardHome', () => {
  let getSubject: Subject<AiInteraction[]>;
  let getInteractions: ReturnType<typeof vi.fn>;
  let fixture: ComponentFixture<DashboardHome>;

  beforeEach(async () => {
    getSubject = new Subject<AiInteraction[]>();
    getInteractions = vi.fn(() => getSubject.asObservable());

    await TestBed.configureTestingModule({
      imports: [DashboardHome],
      providers: [
        provideRouter([]),
        DashboardStore,
        { provide: Diet, useValue: { getDailyMenus: () => of([]) } },
        { provide: Routine, useValue: { getWeeklyRoutine: () => of([]) } },
        {
          provide: InteractionService,
          useValue: { getInteractions, updateFeedback: vi.fn() },
        },
        { provide: MatSnackBar, useValue: { open: vi.fn() } },
        { provide: ExportService, useValue: { downloadDpoDataset: vi.fn() } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(DashboardHome);
    fixture.detectChanges();
  });

  it('requests interactions on initialization', () => {
    expect(getInteractions).toHaveBeenCalledTimes(1);
  });

  it('shows a loading spinner while the request is in flight', () => {
    expect(fixture.nativeElement.querySelector('mat-spinner')).not.toBeNull();

    getSubject.next([interaction('a')]);
    getSubject.complete();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('mat-spinner')).toBeNull();
    expect(fixture.nativeElement.querySelector('app-routine-card')).not.toBeNull();
  });

  it('shows an error state with a Retry action when the fetch fails', () => {
    getSubject.error(new Error('boom'));
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Could not load AI-generated routines.');

    const retryButton = el.querySelector('button');
    expect(retryButton).not.toBeNull();
    retryButton?.click();
    fixture.detectChanges();

    expect(getInteractions).toHaveBeenCalledTimes(2);
  });

  it('shows an empty state when there are no interactions', () => {
    getSubject.next([]);
    getSubject.complete();
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain(
      'No AI-generated routines yet.',
    );
  });

  it('renders a routine card for each interaction', () => {
    getSubject.next([interaction('a'), interaction('b')]);
    getSubject.complete();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('app-routine-card').length).toBe(2);
  });

  it('filters the rendered cards by search query', () => {
    getSubject.next([
      interaction('a', { generatedRoutine: 'Push day\nBench press 4x8' }),
      interaction('b', { generatedRoutine: 'Pull day\nDeadlift 3x5' }),
    ]);
    getSubject.complete();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('app-routine-card').length).toBe(2);

    fixture.componentInstance.store.setSearchQuery('push');
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('app-routine-card').length).toBe(1);
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('1 of 2 routines');
  });

  it('shows the filtered empty state when nothing matches', () => {
    getSubject.next([interaction('a')]);
    getSubject.complete();
    fixture.detectChanges();

    fixture.componentInstance.store.setSearchQuery('zzz');
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('No routines match your filters.');
    expect(fixture.nativeElement.querySelectorAll('app-routine-card').length).toBe(0);
  });

  it('clears filters and restores the full list', () => {
    getSubject.next([
      interaction('a', { generatedRoutine: 'Push day\nBench press 4x8' }),
      interaction('b', { generatedRoutine: 'Pull day\nDeadlift 3x5' }),
    ]);
    getSubject.complete();
    fixture.detectChanges();

    fixture.componentInstance.store.setSearchQuery('push');
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelectorAll('app-routine-card').length).toBe(1);

    fixture.componentInstance.store.clearFilters();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelectorAll('app-routine-card').length).toBe(2);
  });

  it('renders the search filter once interactions are loaded', () => {
    getSubject.next([interaction('a')]);
    getSubject.complete();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('app-search-filter')).not.toBeNull();
  });

  it('renders the export action with the eligible count', () => {
    getSubject.next([
      interaction('a', { rating: 'thumbs_up', feedbackText: 'Great volume.' }),
      interaction('b', { rating: null }),
    ]);
    getSubject.complete();
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain(
      'Export DPO Dataset (1)',
    );
  });

  it('disables export when no interaction is eligible', () => {
    getSubject.next([interaction('a', { rating: null })]);
    getSubject.complete();
    fixture.detectChanges();

    const exportButton = Array.from(
      (fixture.nativeElement as HTMLElement).querySelectorAll('button'),
    ).find((button) => button.textContent?.includes('Export DPO Dataset'));

    expect(exportButton).toBeDefined();
    expect(exportButton?.disabled).toBe(true);
  });
});