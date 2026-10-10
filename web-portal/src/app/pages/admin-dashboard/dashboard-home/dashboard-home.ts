import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { TranslatePipe } from '../../../core/pipes/translate.pipe';

import { StatCard } from '../../../components/molecules/stat-card/stat-card';
import {
  DataTable,
  DataTableColumn,
} from '../../../components/organisms/data-table/data-table';
import { RoutineCard } from '../../../components/organisms/routine-card/routine-card';
import { SearchFilter } from '../../../components/molecules/search-filter/search-filter';
import { DpoExport } from '../../../components/organisms/dpo-export/dpo-export';
import { AnalyticsSummary } from '../../../components/organisms/analytics-summary/analytics-summary';
import { Diet } from '../../../core/services/diet';
import { Routine } from '../../../core/services/routine';
import { DashboardStore } from '../../../core/stores/dashboard.store';
import { DailyMenu } from '../../../core/mocks/mock-diet.data';
import { WorkoutDay } from '../../../core/mocks/mock-routine.data';

@Component({
  selector: 'app-dashboard-home',
  imports: [
    RouterLink,
    StatCard,
    DataTable,
    RoutineCard,
    SearchFilter,
    DpoExport,
    AnalyticsSummary,
    MatProgressSpinnerModule,
    MatButtonModule,
    TranslatePipe,
  ],
  templateUrl: './dashboard-home.html',
  styleUrl: './dashboard-home.scss',
})
export class DashboardHome implements OnInit {
  private readonly diet = inject(Diet);
  private readonly routine = inject(Routine);
  readonly store = inject(DashboardStore);

  readonly menus = signal<DailyMenu[]>([]);
  readonly routines = signal<WorkoutDay[]>([]);
  readonly loading = signal(true);

  readonly routineColumns: DataTableColumn[] = [
    { key: 'weekday', label: 'history.day' },
    { key: 'focus', label: 'history.focus' },
    { key: 'exercises', label: 'history.exercises' },
  ];

  readonly dietColumns: DataTableColumn[] = [
    { key: 'date', label: 'history.date' },
    { key: 'meals', label: 'history.meals' },
    { key: 'totalCalories', label: 'history.calories' },
  ];

  readonly routineRows = computed(() =>
    this.routines().map((day) => ({
      weekday: day.weekday,
      focus: day.focus,
      exercises: `${day.exercises.length} exercises`,
    })),
  );

  readonly dietRows = computed(() =>
    this.menus().map((menu) => ({
      date: menu.date,
      meals: `${menu.meals.length} meals`,
      totalCalories: `${menu.totalCalories} kcal`,
    })),
  );

  readonly activeRoutines = computed(() => String(this.routines().length));
  readonly mealsCount = computed(() =>
    String(this.menus().reduce((total, menu) => total + menu.meals.length, 0)),
  );

  ngOnInit(): void {
    this.routine.getWeeklyRoutine().subscribe({
      next: (data) => this.routines.set(data),
      complete: () => this.loading.set(false),
    });
    this.diet.getDailyMenus().subscribe((data) => this.menus.set(data));
    this.store.load();
  }
}
