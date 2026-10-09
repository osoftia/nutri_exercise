import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { MOCK_PROMPT_LAB_RESULT } from '../../../core/mocks/mock-prompt-lab.data';
import { PromptLabRequest, PromptLabResult } from '../../../core/models/prompt-lab.model';
import { PromptLabService } from '../../../core/services/prompt-lab.service';
import { PromptLabStore } from '../../../core/stores/prompt-lab.store';
import { PromptLab } from './prompt-lab';

describe('PromptLab', () => {
  let fixture: ComponentFixture<PromptLab>;
  let store: PromptLabStore;
  let resultSubject: Subject<PromptLabResult>;
  let promptLabService: {
    runQuery: ReturnType<typeof vi.fn>;
  };

  const queryText = 'Recovery routine after intense dance rehearsal';

  beforeEach(async () => {
    resultSubject = new Subject<PromptLabResult>();
    promptLabService = {
      runQuery: vi.fn(() => resultSubject.asObservable()),
    };

    await TestBed.configureTestingModule({
      imports: [PromptLab],
      providers: [{ provide: PromptLabService, useValue: promptLabService }],
    }).compileComponents();

    store = TestBed.inject(PromptLabStore);
    fixture = TestBed.createComponent(PromptLab);
    fixture.detectChanges();
  });

  it('loads with default temperature of 0.7', () => {
    expect(store.temperature()).toBe(0.7);
    expect(fixture.nativeElement.textContent).toContain('0.7');
  });

  it('loads with default similarity threshold of 0.8', () => {
    expect(store.similarityThreshold()).toBe(0.8);
    expect(fixture.nativeElement.textContent).toContain('0.8');
  });

  it('loads with an empty system prompt, query, and no result panel', () => {
    expect(store.systemPrompt()).toBe('');
    expect(store.query()).toBe('');
    expect(store.hasResult()).toBe(false);
    expect(fixture.nativeElement.textContent).not.toContain('Generated Answer');
  });

  it('binds the system prompt textarea reactively without a button press', () => {
    const textarea = fixture.nativeElement.querySelector('textarea') as HTMLTextAreaElement;
    const typed = 'You are a sports nutrition expert focused on dance recovery';
    textarea.value = typed;
    textarea.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.systemPrompt()).toBe(typed);
    expect(promptLabService.runQuery).not.toHaveBeenCalled();
  });

  it('clearing the system prompt textarea clears the reactive state', () => {
    store.setSystemPrompt('You are a sports nutrition expert');
    fixture.detectChanges();

    const textarea = fixture.nativeElement.querySelector('textarea') as HTMLTextAreaElement;
    textarea.value = '';
    textarea.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.systemPrompt()).toBe('');
  });

  it('updates the temperature slider value', () => {
    const range = fixture.nativeElement.querySelectorAll('input[type="range"]')[0] as HTMLInputElement;
    range.value = '1.1';
    range.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.temperature()).toBe(1.1);
    expect(fixture.nativeElement.textContent).toContain('1.1');
  });

  it('updates the similarity threshold slider value', () => {
    const range = fixture.nativeElement.querySelectorAll('input[type="range"]')[1] as HTMLInputElement;
    range.value = '0.65';
    range.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.similarityThreshold()).toBe(0.65);
    expect(fixture.nativeElement.textContent).toContain('0.65');
  });

  it('binds the test query input reactively', () => {
    const input = fixture.nativeElement.querySelector(
      '.prompt-lab__input',
    ) as HTMLInputElement;
    input.value = queryText;
    input.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(store.query()).toBe(queryText);
  });

  it('shows a loading state and disables the run button while executing', () => {
    store.setQuery(queryText);
    fixture.detectChanges();

    store.runQuery();
    fixture.detectChanges();

    expect(store.loading()).toBe(true);
    expect(fixture.nativeElement.textContent).toContain('Processing');
    const runButton = Array.from(
      fixture.nativeElement.querySelectorAll('button'),
    ).find((button) => (button as HTMLButtonElement).textContent?.trim() === 'Run Query');
    expect((runButton as HTMLButtonElement).disabled).toBe(true);
    expect(fixture.nativeElement.textContent).not.toContain('Generated Answer');
  });

  it('does not call the service for an empty query', () => {
    store.runQuery();
    fixture.detectChanges();

    expect(promptLabService.runQuery).not.toHaveBeenCalled();
    expect(store.loading()).toBe(false);
  });

  it('renders the mock answer and latency metrics after delivery', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.runQuery();
    fixture.detectChanges();

    resultSubject.next(MOCK_PROMPT_LAB_RESULT);
    resultSubject.complete();
    fixture.detectChanges();

    expect(store.loading()).toBe(false);
    expect(store.hasResult()).toBe(true);
    expect(fixture.nativeElement.textContent).toContain('Cool-down');
    expect(fixture.nativeElement.textContent).toContain('1842');
    expect(fixture.nativeElement.textContent).toContain('ms');
    expect(fixture.nativeElement.textContent).toContain('38 tok/s');
  });

  it('renders the matched sources ordered by descending score', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.runQuery();
    fixture.detectChanges();

    resultSubject.next(MOCK_PROMPT_LAB_RESULT);
    resultSubject.complete();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('Dance-specific recovery protocols');
    expect(text).toContain('94.0%');
    expect(text).toContain('87.0%');
    expect(text).toContain('79.0%');
    const firstScoreIndex = text.indexOf('94.0%');
    const secondScoreIndex = text.indexOf('87.0%');
    const thirdScoreIndex = text.indexOf('79.0%');
    expect(firstScoreIndex).toBeGreaterThan(-1);
    expect(secondScoreIndex).toBeGreaterThan(firstScoreIndex);
    expect(thirdScoreIndex).toBeGreaterThan(secondScoreIndex);
  });

  it('sends the query, system prompt, and parameters in the request', () => {
    store.setSystemPrompt('You are a dance recovery expert');
    store.setTemperature(0.5);
    store.setSimilarityThreshold(0.9);
    store.setQuery(queryText);
    fixture.detectChanges();

    store.runQuery();
    fixture.detectChanges();

    const request: PromptLabRequest = promptLabService.runQuery.mock.calls[0][0];
    expect(request.query).toBe(queryText);
    expect(request.systemPrompt).toBe('You are a dance recovery expert');
    expect(request.temperature).toBe(0.5);
    expect(request.similarityThreshold).toBe(0.9);
  });

  it('renders an error state when the query fails', () => {
    store.setQuery(queryText);
    fixture.detectChanges();
    store.runQuery();
    fixture.detectChanges();

    resultSubject.error(new Error('boom'));
    fixture.detectChanges();

    expect(store.loading()).toBe(false);
    expect(store.error()).toBe('Could not execute the prompt query.');
    expect(fixture.nativeElement.textContent).toContain('Could not execute the prompt query.');
  });

  it('reset restores every default and removes the result panel', () => {
    store.setSystemPrompt('custom prompt');
    store.setTemperature(1.3);
    store.setSimilarityThreshold(0.5);
    store.setQuery(queryText);
    store.runQuery();
    fixture.detectChanges();
    resultSubject.next(MOCK_PROMPT_LAB_RESULT);
    resultSubject.complete();
    fixture.detectChanges();

    store.reset();
    fixture.detectChanges();

    expect(store.temperature()).toBe(0.7);
    expect(store.similarityThreshold()).toBe(0.8);
    expect(store.systemPrompt()).toBe('');
    expect(store.query()).toBe('');
    expect(store.result()).toBeNull();
    expect(store.hasResult()).toBe(false);
    expect(fixture.nativeElement.textContent).not.toContain('Generated Answer');
  });

  it('clicking the Run Query button executes the query', () => {
    store.setQuery(queryText);
    fixture.detectChanges();

    const runButton = Array.from(
      fixture.nativeElement.querySelectorAll('button'),
    ).find((button) => (button as HTMLButtonElement).textContent?.trim() === 'Run Query');
    (runButton as HTMLButtonElement).click();
    fixture.detectChanges();

    expect(promptLabService.runQuery).toHaveBeenCalled();
    expect(store.loading()).toBe(true);
  });

  it('clicking the Reset button restores defaults', () => {
    store.setSystemPrompt('custom');
    store.setTemperature(1.2);
    store.setSimilarityThreshold(0.4);
    store.setQuery(queryText);
    fixture.detectChanges();

    const resetButton = Array.from(
      fixture.nativeElement.querySelectorAll('button'),
    ).find((button) => (button as HTMLButtonElement).textContent?.trim() === 'Reset');
    (resetButton as HTMLButtonElement).click();
    fixture.detectChanges();

    expect(store.temperature()).toBe(0.7);
    expect(store.similarityThreshold()).toBe(0.8);
    expect(store.systemPrompt()).toBe('');
    expect(store.query()).toBe('');
  });
});