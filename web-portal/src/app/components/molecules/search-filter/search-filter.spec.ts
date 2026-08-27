import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SearchFilter } from './search-filter';

describe('SearchFilter', () => {
  let fixture: ComponentFixture<SearchFilter>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SearchFilter] }).compileComponents();
    fixture = TestBed.createComponent(SearchFilter);
    fixture.detectChanges();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('debounces rapid keystrokes into a single query emission', () => {
    vi.useFakeTimers();
    const spy = vi.fn();
    fixture.componentInstance.queryChange.subscribe(spy);

    fixture.componentInstance.onQueryInput('a');
    vi.advanceTimersByTime(100);
    fixture.componentInstance.onQueryInput('ab');
    vi.advanceTimersByTime(100);
    fixture.componentInstance.onQueryInput('abc');
    vi.advanceTimersByTime(300);

    expect(spy).toHaveBeenCalledTimes(1);
    expect(spy).toHaveBeenCalledWith('abc');
  });

  it('emits the query once typing pauses', () => {
    vi.useFakeTimers();
    const spy = vi.fn();
    fixture.componentInstance.queryChange.subscribe(spy);

    fixture.componentInstance.onQueryInput('deadlift');
    expect(spy).not.toHaveBeenCalled();

    vi.advanceTimersByTime(300);
    expect(spy).toHaveBeenCalledWith('deadlift');
  });

  it('emits the date range when a start date is chosen', () => {
    const spy = vi.fn();
    fixture.componentInstance.dateRangeChange.subscribe(spy);

    const from = new Date(2026, 7, 16);
    fixture.componentInstance.onFromChange(from);

    expect(spy).toHaveBeenCalledWith({ from, to: null });
  });

  it('emits the date range when an end date is chosen', () => {
    const spy = vi.fn();
    fixture.componentInstance.dateRangeChange.subscribe(spy);

    const to = new Date(2026, 7, 18);
    fixture.componentInstance.onToChange(to);

    expect(spy).toHaveBeenCalledWith({ from: null, to });
  });

  it('tracks whether any filter is active', () => {
    expect(fixture.componentInstance.filtersActive()).toBe(false);

    fixture.componentInstance.onQueryInput('push');
    expect(fixture.componentInstance.filtersActive()).toBe(true);

    fixture.componentInstance.onFromChange(new Date(2026, 7, 16));
    fixture.componentInstance.onToChange(new Date(2026, 7, 18));
    expect(fixture.componentInstance.filtersActive()).toBe(true);
  });

  it('clears all fields and emits the clear event', () => {
    const spy = vi.fn();
    fixture.componentInstance.clear.subscribe(spy);

    fixture.componentInstance.onQueryInput('push');
    fixture.componentInstance.onFromChange(new Date(2026, 7, 16));

    fixture.componentInstance.clearFilters();

    expect(fixture.componentInstance.query()).toBe('');
    expect(fixture.componentInstance.from()).toBeNull();
    expect(fixture.componentInstance.to()).toBeNull();
    expect(fixture.componentInstance.filtersActive()).toBe(false);
    expect(spy).toHaveBeenCalledTimes(1);
  });

  it('renders the search input and date pickers', () => {
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('input')).not.toBeNull();
    expect(el.querySelectorAll('mat-datepicker-toggle').length).toBe(2);
  });

  it('does not render the clear button until a filter is active', () => {
    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).not.toContain('Clear filters');

    fixture.componentInstance.onFromChange(new Date(2026, 7, 16));
    fixture.detectChanges();

    expect(el.textContent).toContain('Clear filters');
  });
});