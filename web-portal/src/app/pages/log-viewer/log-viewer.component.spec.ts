import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { provideRouter } from '@angular/router';

import { LogViewerComponent } from './log-viewer.component';
import { LogService } from '../../core/services/log.service';
import { LogEntry, PagedLogResponse } from '../../core/models/log.model';

const entries: LogEntry[] = [
  {
    timestamp: '2026-10-01T12:00:00Z',
    level: 'Error',
    message: '[OLLAMA-ERROR] connection refused',
    exception: 'System.Net.Http.HttpRequestException: Connection refused',
    properties: {},
    sourceFile: 'nutriexercise-20261001.json',
  },
  {
    timestamp: '2026-10-01T11:00:00Z',
    level: 'Information',
    message: '[RAG-INFO] routine generated',
    exception: null,
    properties: {},
    sourceFile: 'nutriexercise-20261001.json',
  },
];

const response: PagedLogResponse = {
  items: entries,
  pageNumber: 1,
  pageSize: 10,
  totalCount: 2,
};

describe('LogViewerComponent', () => {
  let fixture: ComponentFixture<LogViewerComponent>;
  let getLogs: ReturnType<typeof vi.fn>;

  beforeEach(async () => {
    getLogs = vi.fn().mockReturnValue(of(response));

    await TestBed.configureTestingModule({
      imports: [LogViewerComponent],
      providers: [
        provideRouter([]),
        { provide: LogService, useValue: { getLogs } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(LogViewerComponent);
    fixture.detectChanges();
  });

  it('loads and renders the logs on initialization', () => {
    expect(getLogs).toHaveBeenCalledTimes(1);
    expect(fixture.nativeElement.querySelectorAll('.log-viewer__row').length).toBe(2);
  });

  it('applies the filters through the service', () => {
    const component = fixture.componentInstance;
    component.logLevel.set('Error');
    component.applyFilters();

    expect(getLogs).toHaveBeenCalledTimes(2);
    expect(getLogs.mock.calls[1][0]).toMatchObject({ logLevel: 'Error', pageNumber: 1 });
  });

  it('expands a row to reveal the exception detail', () => {
    const component = fixture.componentInstance;
    component.toggleRow(0);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.log-viewer__exception')).not.toBeNull();
  });

  it('navigates to the next page through the service', () => {
    const component = fixture.componentInstance;
    component.totalCount.set(30);
    component.goToPage(2);

    expect(getLogs).toHaveBeenCalledTimes(2);
    expect(getLogs.mock.calls[1][0]).toMatchObject({ pageNumber: 2 });
  });
});
