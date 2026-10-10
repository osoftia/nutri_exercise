import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { MOCK_PROMPT_LAB_RESULT } from '../../../core/mocks/mock-prompt-lab.data';
import { PromptLabResult } from '../../../core/models/prompt-lab.model';
import { RagService } from '../../../core/services/rag.service';
import { RagLabStore } from '../../../core/stores/rag-lab.store';
import { RagLabControls } from './rag-lab-controls';

describe('RagLabControls (Step 3 — Controls UI Panel)', () => {
  let fixture: ComponentFixture<RagLabControls>;
  let store: RagLabStore;
  let resultSubject: Subject<PromptLabResult>;
  let ragService: { runPromptLab: ReturnType<typeof vi.fn> };

  const queryText = 'Recovery routine after intense dance rehearsal';

  function executeButton(): HTMLButtonElement {
    return fixture.nativeElement.querySelector(
      '.rag-lab-controls__button--execute',
    ) as HTMLButtonElement;
  }

  function resetButton(): HTMLButtonElement {
    return Array.from(fixture.nativeElement.querySelectorAll('button')).find(
      (button) => (button as HTMLButtonElement).textContent?.trim() === 'Reset',
    ) as HTMLButtonElement;
  }

  beforeEach(async () => {
    resultSubject = new Subject<PromptLabResult>();
    ragService = { runPromptLab: vi.fn(() => resultSubject.asObservable()) };

    await TestBed.configureTestingModule({
      imports: [RagLabControls],
      providers: [{ provide: RagService, useValue: ragService }],
    }).compileComponents();

    store = TestBed.inject(RagLabStore);
    fixture = TestBed.createComponent(RagLabControls);
    fixture.detectChanges();
  });

  it('renders with store defaults (temperature 0.7, threshold 0.8, empty inputs)', () => {
    expect(store.temperature()).toBe(0.7);
    expect(store.similarityThreshold()).toBe(0.8);
    expect(store.systemPrompt()).toBe('');
    expect(store.query()).toBe('');
    expect(fixture.nativeElement.textContent).toContain('0.7');
    expect(fixture.nativeElement.textContent).toContain('0.8');
    expect(fixture.nativeElement.textContent).toContain('Execute Semantic Search');
  });

  it('bounds both sliders to 0.0 – 1.0', () => {
    const ranges = fixture.nativeElement.querySelectorAll(
      'input[type="range"]',
    ) as NodeListOf<HTMLInputElement>;
    expect(ranges.length).toBe(2);
    for (const range of Array.from(ranges)) {
      expect(range.min).toBe('0');
      expect(range.max).toBe('1');
    }
  });

  it('binds the system prompt textarea reactively without triggering a query', () => {
    const textarea = fixture.nativeElement.querySelector('textarea') as HTMLTextAreaElement;
    textarea.value = 'You are a sports nutrition expert';
    textarea.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.systemPrompt()).toBe('You are a sports nutrition expert');
    expect(ragService.runPromptLab).not.toHaveBeenCalled();
  });

  it('updates temperature through the slider', () => {
    const range = fixture.nativeElement.querySelectorAll('input[type="range"]')[0] as HTMLInputElement;
    range.value = '0.4';
    range.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.temperature()).toBe(0.4);
    expect(fixture.nativeElement.textContent).toContain('0.4');
  });

  it('updates the similarity threshold through the slider', () => {
    const range = fixture.nativeElement.querySelectorAll('input[type="range"]')[1] as HTMLInputElement;
    range.value = '0.65';
    range.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.similarityThreshold()).toBe(0.65);
    expect(fixture.nativeElement.textContent).toContain('0.65');
  });

  it('binds the search query input reactively', () => {
    const input = fixture.nativeElement.querySelector('.rag-lab-controls__input') as HTMLInputElement;
    input.value = queryText;
    input.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.query()).toBe(queryText);
  });

  it('clicking Execute Semantic Search triggers store.executeQuery()', () => {
    store.setQuery(queryText);
    fixture.detectChanges();

    executeButton().click();
    fixture.detectChanges();

    expect(ragService.runPromptLab).toHaveBeenCalledTimes(1);
    expect(store.isLoading()).toBe(true);
  });

  it('disables the execute button and swaps its label while loading', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.executeQuery();
    fixture.detectChanges();

    const button = executeButton();
    expect(store.isLoading()).toBe(true);
    expect(button.disabled).toBe(true);
    expect(button.textContent).toContain('Executing');

    resultSubject.next(MOCK_PROMPT_LAB_RESULT);
    resultSubject.complete();
    fixture.detectChanges();

    expect(store.isLoading()).toBe(false);
    expect(executeButton().disabled).toBe(false);
    expect(executeButton().textContent).toContain('Execute Semantic Search');
  });

  it('does not call the service for an empty query', () => {
    executeButton().click();
    fixture.detectChanges();

    expect(ragService.runPromptLab).not.toHaveBeenCalled();
    expect(store.isLoading()).toBe(false);
  });

  it('renders the store error when the query fails', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.executeQuery();
    fixture.detectChanges();

    resultSubject.error(new Error('boom'));
    fixture.detectChanges();

    expect(store.error()).toBe('Could not execute the RAG query.');
    expect(fixture.nativeElement.textContent).toContain('Could not execute the RAG query.');
  });

  it('clicking Reset restores every default', () => {
    store.setSystemPrompt('custom');
    store.setTemperature(0.2);
    store.setSimilarityThreshold(0.4);
    store.setQuery(queryText);
    fixture.detectChanges();

    resetButton().click();
    fixture.detectChanges();

    expect(store.systemPrompt()).toBe('');
    expect(store.temperature()).toBe(0.7);
    expect(store.similarityThreshold()).toBe(0.8);
    expect(store.query()).toBe('');
  });
});
