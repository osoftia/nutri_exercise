import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { MOCK_PROMPT_LAB_RESULT } from '../../../core/mocks/mock-prompt-lab.data';
import { MatchedSource } from '../../../core/models/prompt-lab.model';
import { RagService } from '../../../core/services/rag.service';
import { RagLabStore } from '../../../core/stores/rag-lab.store';
import { RagLabResults } from './rag-lab-results';

describe('RagLabResults (Step 4 — Semantic Results Display)', () => {
  let fixture: ComponentFixture<RagLabResults>;
  let store: RagLabStore;
  let resultSubject: Subject<import('../../../core/models/prompt-lab.model').PromptLabResult>;
  let ragService: { runPromptLab: ReturnType<typeof vi.fn> };

  const queryText = 'Recovery routine after intense dance rehearsal';

  function cards(): NodeListOf<HTMLElement> {
    return fixture.nativeElement.querySelectorAll('.rag-lab-results__card');
  }

  function feedbackButtons(card: Element): HTMLButtonElement[] {
    return Array.from(
      card.querySelectorAll('.rag-lab-results__feedback-btn'),
    ) as HTMLButtonElement[];
  }

  function distributionText(): string {
    return (
      fixture.nativeElement.querySelector('.rag-lab-results__feedback-count')?.textContent ?? ''
    );
  }

  beforeEach(async () => {
    resultSubject = new Subject<import('../../../core/models/prompt-lab.model').PromptLabResult>();
    ragService = { runPromptLab: vi.fn(() => resultSubject.asObservable()) };

    await TestBed.configureTestingModule({
      imports: [RagLabResults],
      providers: [{ provide: RagService, useValue: ragService }],
    }).compileComponents();

    store = TestBed.inject(RagLabStore);
    fixture = TestBed.createComponent(RagLabResults);
    fixture.detectChanges();
  });

  it('renders a clean empty state when no results are present', () => {
    expect(store.hasResults()).toBe(false);
    expect(fixture.nativeElement.textContent).toContain('No semantic results yet');
    expect(cards().length).toBe(0);
  });

  it('renders a loading indicator while the store is loading', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.executeQuery();
    fixture.detectChanges();

    expect(store.isLoading()).toBe(true);
    const loading = fixture.nativeElement.querySelector('.rag-lab-results__loading');
    expect(loading).toBeTruthy();
    expect(loading.textContent).toContain('Retrieving semantic matches');
    expect(fixture.nativeElement.textContent).not.toContain('No semantic results yet');
  });

  it('renders one card per matched source with title and large similarity score', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    expect(cards().length).toBe(3);
    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('Dance-specific recovery protocols');
    expect(text).toContain('94.0%');
    expect(text).toContain('87.0%');
    expect(text).toContain('79.0%');
    const scores = Array.from(
      fixture.nativeElement.querySelectorAll('.rag-lab-results__score-number'),
    ).map((el) => (el as HTMLElement).textContent?.trim());
    expect(scores).toEqual(['94.0%', '87.0%', '79.0%']);
  });

  it('summarizes match count, latency telemetry, and the generated answer', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.rag-lab-results__count')?.textContent).toContain('3');
    expect(fixture.nativeElement.textContent).toContain('1842');
    expect(fixture.nativeElement.textContent).toContain('38 tok/s');
    expect(fixture.nativeElement.textContent).toContain('Cool-down');
  });

  it('renders content excerpts and body-zone chips when present', () => {
    store.results.set({
      ...MOCK_PROMPT_LAB_RESULT,
      matchedSources: [
        {
          id: 'e1',
          title: 'Legs protocol',
          score: 0.91,
          content: 'Deep squat excerpt for match day',
          bodyZone: 'Legs',
        } as unknown as MatchedSource,
      ],
    });
    fixture.detectChanges();

    expect(cards().length).toBe(1);
    expect(fixture.nativeElement.textContent).toContain('Legs protocol');
    expect(fixture.nativeElement.textContent).toContain('Deep squat excerpt for match day');
    expect(fixture.nativeElement.querySelector('.rag-lab-results__chip')?.textContent).toContain(
      'Legs',
    );
    expect(fixture.nativeElement.textContent).toContain('91.0%');
  });

  it('normalizes the PascalCase RagMatchItem wire shape', () => {
    store.results.set({
      answer: 'wire answer',
      matchedSources: [
        {
          Id: 'w1',
          Title: 'Wire doc',
          Score: 0.88,
          Content: 'wire excerpt',
          BodyZone: 'Core',
        } as unknown as MatchedSource,
      ],
      latencyMs: 900,
      tokensPerSecond: 42,
    });
    fixture.detectChanges();

    expect(cards().length).toBe(1);
    expect(fixture.nativeElement.textContent).toContain('Wire doc');
    expect(fixture.nativeElement.textContent).toContain('wire excerpt');
    expect(fixture.nativeElement.querySelector('.rag-lab-results__chip')?.textContent).toContain(
      'Core',
    );
    expect(fixture.nativeElement.textContent).toContain('88.0%');
  });

  it('falls back gracefully for sources with missing fields', () => {
    store.results.set({
      answer: 'partial',
      matchedSources: [
        {} as unknown as MatchedSource,
        {
          title: 'Zoned doc',
          score: 0.5,
          bodyZones: ['Back'],
        } as unknown as MatchedSource,
        {
          title: 'Muscled doc',
          score: 0.6,
          muscleGroup: 'Chest',
        } as unknown as MatchedSource,
      ],
      latencyMs: 100,
      tokensPerSecond: 10,
    });
    fixture.detectChanges();

    expect(cards().length).toBe(3);
    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('Untitled source');
    expect(text).toContain('0.0%');
    expect(text).toContain('Back');
    expect(text).toContain('Chest');
  });

  it('renders a no-matches state when results carry zero sources', () => {
    store.results.set({ ...MOCK_PROMPT_LAB_RESULT, matchedSources: [] });
    fixture.detectChanges();

    expect(cards().length).toBe(0);
    expect(fixture.nativeElement.textContent).toContain('No matches above threshold');
  });

  it('renders the store error when the query fails', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.executeQuery();
    fixture.detectChanges();

    resultSubject.error(new Error('boom'));
    fixture.detectChanges();

    const error = fixture.nativeElement.querySelector('.rag-lab-results__error');
    expect(error).toBeTruthy();
    expect(error.textContent).toContain('Could not execute the RAG query.');
    expect(cards().length).toBe(0);
  });

  it('opens a brutalist modal with full source details on card click', () => {
    store.results.set({
      ...MOCK_PROMPT_LAB_RESULT,
      matchedSources: [
        {
          id: 'e1',
          title: 'Legs protocol',
          score: 0.91,
          content: 'Deep squat excerpt for match day',
          bodyZone: 'Legs',
        } as unknown as MatchedSource,
      ],
    });
    fixture.detectChanges();

    (cards()[0] as HTMLElement).click();
    fixture.detectChanges();

    const dialog = fixture.nativeElement.querySelector('[role="dialog"]');
    expect(dialog).toBeTruthy();
    expect(dialog.textContent).toContain('Legs protocol');
    expect(dialog.textContent).toContain('Deep squat excerpt for match day');
    expect(dialog.textContent).toContain('91.0%');
    expect(dialog.textContent).toContain('ID: e1');
  });

  it('opens the modal via keyboard and shows a muted fallback without an excerpt', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    (cards()[0] as HTMLElement).dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    fixture.detectChanges();

    const dialog = fixture.nativeElement.querySelector('[role="dialog"]');
    expect(dialog).toBeTruthy();
    expect(dialog.textContent).toContain('Dance-specific recovery protocols');
    expect(dialog.textContent).toContain('No excerpt indexed for this source.');
  });

  it('closes the modal via CLOSE and via the backdrop', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    (cards()[0] as HTMLElement).click();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('[role="dialog"]')).not.toBeNull();

    const close = fixture.nativeElement.querySelector(
      '.rag-lab-results__modal-close',
    ) as HTMLButtonElement;
    close.click();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('[role="dialog"]')).toBeNull();

    (cards()[0] as HTMLElement).click();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('[role="dialog"]')).not.toBeNull();

    const backdrop = fixture.nativeElement.querySelector(
      '.rag-lab-results__modal-backdrop',
    ) as HTMLElement;
    backdrop.click();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('[role="dialog"]')).toBeNull();
  });

  it('records a positive vote and reports it in the distribution strip', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();
    expect(distributionText()).toContain('+ 0');

    const [positive] = feedbackButtons(cards()[0]);
    positive.click();
    fixture.detectChanges();

    expect(positive.getAttribute('aria-pressed')).toBe('true');
    expect(fixture.componentInstance.feedbackDistribution()).toEqual({
      positive: 1,
      negative: 0,
      reviewed: 1,
    });
    expect(distributionText()).toContain('+ 1');
  });

  it('toggles a vote off when the same sentiment is clicked twice', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    const [positive] = feedbackButtons(cards()[0]);
    positive.click();
    fixture.detectChanges();
    positive.click();
    fixture.detectChanges();

    expect(positive.getAttribute('aria-pressed')).toBe('false');
    expect(fixture.componentInstance.feedbackDistribution()).toEqual({
      positive: 0,
      negative: 0,
      reviewed: 0,
    });
  });

  it('switches a vote from positive to negative', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    const [positive, negative] = feedbackButtons(cards()[0]);
    positive.click();
    fixture.detectChanges();
    negative.click();
    fixture.detectChanges();

    expect(positive.getAttribute('aria-pressed')).toBe('false');
    expect(negative.getAttribute('aria-pressed')).toBe('true');
    expect(fixture.componentInstance.feedbackDistribution()).toEqual({
      positive: 0,
      negative: 1,
      reviewed: 1,
    });
    expect(distributionText()).toContain('− 1');
  });

  it('does not open the modal when a feedback button is clicked', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    const [, negative] = feedbackButtons(cards()[0]);
    negative.click();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('[role="dialog"]')).toBeNull();
    expect(fixture.componentInstance.feedback()['src-001']).toBe('negative');
  });

  it('scopes the distribution to the current result set', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    feedbackButtons(cards()[0])[0].click();
    fixture.detectChanges();
    expect(fixture.componentInstance.feedbackDistribution().reviewed).toBe(1);

    store.results.set({ ...MOCK_PROMPT_LAB_RESULT, matchedSources: [] });
    fixture.detectChanges();

    expect(fixture.componentInstance.feedbackDistribution()).toEqual({
      positive: 0,
      negative: 0,
      reviewed: 0,
    });
  });
});
