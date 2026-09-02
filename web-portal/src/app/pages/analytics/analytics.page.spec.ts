import { describe, it, expect, beforeEach } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of, Subject } from 'rxjs';
import { signal } from '@angular/core';
import { provideRouter } from '@angular/router';

import { AnalyticsPage } from './analytics.page';
import { AnalyticsStore } from '../../core/stores/analytics.store';
import { VectorInspectorStore } from '../../core/stores/vector-inspector.store';
import { DashboardStore } from '../../core/stores/dashboard.store';
import { AiMetricsService } from '../../core/services/ai-metrics.service';
import { TelemetryService } from '../../core/services/telemetry.service';
import { DatabaseService } from '../../core/services/database.service';
import { mockAiPerformance, mockTelemetrySnapshot } from '../../core/mocks/mock-analytics.data';

describe('AnalyticsPage', () => {
  let fixture: ComponentFixture<AnalyticsPage>;
  let tablesSubject: Subject<unknown[]>;

  beforeEach(async () => {
    tablesSubject = new Subject<unknown[]>();

    await TestBed.configureTestingModule({
      imports: [AnalyticsPage],
      providers: [
        provideRouter([]),
        AnalyticsStore,
        VectorInspectorStore,
        { provide: TelemetryService, useValue: { getSnapshot: () => of(mockTelemetrySnapshot) } },
        { provide: AiMetricsService, useValue: { getPerformance: () => of(mockAiPerformance) } },
        {
          provide: DatabaseService,
          useValue: { getTables: () => tablesSubject.asObservable() },
        },
        {
          provide: DashboardStore,
          useValue: { analytics: signal({ positiveCount: 0, negativeCount: 0, reviewedCount: 0 }) },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(AnalyticsPage);
    fixture.detectChanges();
  });

  it('loads the analytics stores on initialization', () => {
    const analytics = TestBed.inject(AnalyticsStore);
    const vector = TestBed.inject(VectorInspectorStore);

    expect(analytics.telemetry()).toEqual(mockTelemetrySnapshot);
    expect(analytics.aiPerformance()).toEqual(mockAiPerformance);
    expect(vector.loading()).toBe(true);
  });

  it('renders the three analytics sections', () => {
    expect(fixture.nativeElement.querySelector('app-mobile-usage')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-ai-performance')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-vector-inspector')).not.toBeNull();
  });
});