import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { of, Subject } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';

import { DashboardHome } from './dashboard-home';
import { DashboardStore } from '../../../core/stores/dashboard.store';
import { Diet } from '../../../core/services/diet';
import { InteractionService } from '../../../core/services/interaction.service';
import { Routine } from '../../../core/services/routine';
import { AiInteraction } from '../../../core/models/interaction.model';

const interaction = (id: string): AiInteraction => ({
  id,
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: '2026-08-17T09:30:00Z',
  model: 'llama3.2',
  status: 'completed',
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
});