import { Component, OnInit, inject } from '@angular/core';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { AdminSidebar } from '../../components/organisms/admin-sidebar/admin-sidebar';
import { TopNavbar } from '../../components/organisms/top-navbar/top-navbar';
import { AnalyticsStore } from '../../core/stores/analytics.store';
import { VectorInspectorStore } from '../../core/stores/vector-inspector.store';
import { MobileUsage } from '../../components/organisms/mobile-usage/mobile-usage';
import { AiPerformanceComponent } from '../../components/organisms/ai-performance/ai-performance';
import { VectorInspector } from '../../components/organisms/vector-inspector/vector-inspector';

@Component({
  selector: 'app-analytics-page',
  imports: [
    AdminSidebar,
    TopNavbar,
    MobileUsage,
    AiPerformanceComponent,
    VectorInspector,
    MatProgressSpinnerModule,
  ],
  templateUrl: './analytics.page.html',
  styleUrl: './analytics.page.scss',
})
export class AnalyticsPage implements OnInit {
  readonly analytics = inject(AnalyticsStore);
  readonly vectorInspector = inject(VectorInspectorStore);

  ngOnInit(): void {
    this.analytics.load();
    this.vectorInspector.loadTables();
  }
}