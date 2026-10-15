import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';

import { AdminSidebar } from '../../components/organisms/admin-sidebar/admin-sidebar';
import { TopNavbar } from '../../components/organisms/top-navbar/top-navbar';
import { LogService } from '../../core/services/log.service';
import {
  LOG_LEVELS,
  LogEntry,
  LogLevelOption,
  LogQuery,
} from '../../core/models/log.model';

@Component({
  selector: 'app-log-viewer',
  imports: [
    AdminSidebar,
    TopNavbar,
    DatePipe,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSelectModule,
  ],
  templateUrl: './log-viewer.component.html',
  styleUrl: './log-viewer.component.scss',
})
export class LogViewerComponent implements OnInit {
  private readonly logService = inject(LogService);

  readonly levels: LogLevelOption[] = [...LOG_LEVELS];
  readonly logs = signal<LogEntry[]>([]);
  readonly loading = signal(false);
  readonly pageNumber = signal(1);
  readonly pageSize = signal(10);
  readonly totalCount = signal(0);
  readonly logLevel = signal<LogLevelOption>('All');
  readonly tag = signal('');
  readonly startDate = signal('');
  readonly endDate = signal('');
  readonly expandedIndex = signal<number | null>(null);

  readonly totalPages = computed(() =>
    Math.max(1, Math.ceil(this.totalCount() / this.pageSize())),
  );

  readonly rangeStart = computed(() =>
    this.totalCount() === 0 ? 0 : (this.pageNumber() - 1) * this.pageSize() + 1,
  );

  readonly rangeEnd = computed(() =>
    Math.min(this.pageNumber() * this.pageSize(), this.totalCount()),
  );

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.logService.getLogs(this.buildQuery()).subscribe({
      next: (response) => {
        this.logs.set(response.items);
        this.totalCount.set(response.totalCount);
      },
      complete: () => this.loading.set(false),
      error: () => this.loading.set(false),
    });
  }

  applyFilters(): void {
    this.pageNumber.set(1);
    this.expandedIndex.set(null);
    this.load();
  }

  resetFilters(): void {
    this.logLevel.set('All');
    this.tag.set('');
    this.startDate.set('');
    this.endDate.set('');
    this.applyFilters();
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages()) {
      return;
    }

    this.pageNumber.set(page);
    this.expandedIndex.set(null);
    this.load();
  }

  toggleRow(index: number): void {
    this.expandedIndex.update((current) => (current === index ? null : index));
  }

  levelClass(level: string): string {
    return `log-viewer__level log-viewer__level--${level.toLowerCase()}`;
  }

  private buildQuery(): LogQuery {
    return {
      logLevel: this.logLevel(),
      tag: this.tag() || undefined,
      startDate: this.startDate() ? `${this.startDate()}T00:00:00Z` : undefined,
      endDate: this.endDate() ? `${this.endDate()}T23:59:59Z` : undefined,
      pageNumber: this.pageNumber(),
      pageSize: this.pageSize(),
    };
  }
}
