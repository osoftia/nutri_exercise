import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FeedbackForm } from './feedback-form';

describe('FeedbackForm', () => {
  let fixture: ComponentFixture<FeedbackForm>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [FeedbackForm] }).compileComponents();
    fixture = TestBed.createComponent(FeedbackForm);
    fixture.detectChanges();
  });

  it('pre-fills the form with saved feedback', () => {
    fixture.componentRef.setInput('initialFeedback', 'Great volume');
    fixture.detectChanges();

    expect(fixture.componentInstance.form.controls['feedback'].value).toBe('Great volume');
    expect(fixture.componentInstance.form.pristine).toBe(true);
  });

  it('marks the form invalid and does not emit for empty feedback', () => {
    const spy = vi.fn();
    fixture.componentInstance.feedbackSubmitted.subscribe(spy);
    fixture.componentInstance.form.controls['feedback'].setValue('');
    fixture.componentInstance.submit();
    fixture.detectChanges();

    expect(fixture.componentInstance.form.invalid).toBe(true);
    expect(spy).not.toHaveBeenCalled();
    expect(fixture.nativeElement.textContent).toContain('Feedback required');
  });

  it('emits the text for valid feedback', () => {
    const spy = vi.fn();
    fixture.componentInstance.feedbackSubmitted.subscribe(spy);
    fixture.componentInstance.form.controls['feedback'].setValue('Great routine');
    fixture.componentInstance.submit();

    expect(spy).toHaveBeenCalledWith('Great routine');
  });

  it('does not emit while submitting', () => {
    fixture.componentRef.setInput('submitting', true);
    fixture.detectChanges();

    const spy = vi.fn();
    fixture.componentInstance.feedbackSubmitted.subscribe(spy);
    fixture.componentInstance.form.controls['feedback'].setValue('Great routine');
    fixture.componentInstance.submit();

    expect(spy).not.toHaveBeenCalled();
  });

  it('keeps the entered text after submit for retry', () => {
    const spy = vi.fn();
    fixture.componentInstance.feedbackSubmitted.subscribe(spy);
    fixture.componentInstance.form.controls['feedback'].setValue('Adjust sets');
    fixture.componentInstance.submit();

    expect(fixture.componentInstance.form.controls['feedback'].value).toBe('Adjust sets');
    expect(spy).toHaveBeenCalledWith('Adjust sets');
  });
});