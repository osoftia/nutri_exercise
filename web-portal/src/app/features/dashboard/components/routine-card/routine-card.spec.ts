import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AiInteraction } from '../../../../core/models/interaction.model';
import { RoutineCard } from './routine-card';

const interaction = (overrides: Partial<AiInteraction> = {}): AiInteraction => ({
  id: 'id-1',
  userPrompt: 'Age: 28, Goal: build_muscle, Level: intermediate',
  generatedRoutine: 'Weekly routine\nDay 1 - Push: Bench press 4x8',
  rating: null,
  feedbackText: null,
  createdAt: '2026-08-17T09:30:00Z',
  model: 'llama3.2',
  status: 'completed',
  ...overrides,
});

describe('RoutineCard', () => {
  let fixture: ComponentFixture<RoutineCard>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [RoutineCard] }).compileComponents();
    fixture = TestBed.createComponent(RoutineCard);
    fixture.componentRef.setInput('interaction', interaction());
    fixture.detectChanges();
  });

  it('renders the prompt, model, status, and generated routine', () => {
    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Age: 28, Goal: build_muscle, Level: intermediate');
    expect(el.textContent).toContain('llama3.2');
    expect(el.textContent).toContain('completed');
    expect(el.textContent).toContain('Bench press 4x8');
  });

  it('shows saved feedback when present', () => {
    fixture.componentRef.setInput('interaction', interaction({ feedbackText: 'Great volume' }));
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain(
      'Saved feedback: Great volume',
    );
  });

  it('emits id and text when feedback is submitted', () => {
    const spy = vi.fn();
    fixture.componentInstance.feedbackSubmitted.subscribe(spy);
    fixture.componentInstance.onFeedback('Reduce rest');

    expect(spy).toHaveBeenCalledWith({ id: 'id-1', text: 'Reduce rest' });
  });
});