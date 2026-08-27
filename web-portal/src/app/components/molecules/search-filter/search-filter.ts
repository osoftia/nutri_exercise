import { Component, computed, output, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { MatButtonModule } from '@angular/material/button';
import { provideNativeDateAdapter } from '@angular/material/core';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-search-filter',
  imports: [MatFormFieldModule, MatInputModule, MatDatepickerModule, MatButtonModule],
  templateUrl: './search-filter.html',
  styleUrl: './search-filter.scss',
  providers: [provideNativeDateAdapter()],
})
export class SearchFilter {
  private readonly queryInput = new Subject<string>();

  readonly query = signal('');
  readonly from = signal<Date | null>(null);
  readonly to = signal<Date | null>(null);

  readonly queryChange = output<string>();
  readonly dateRangeChange = output<{ from: Date | null; to: Date | null }>();
  readonly clear = output<void>();

  readonly filtersActive = computed(
    () => this.query().trim() !== '' || this.from() !== null || this.to() !== null,
  );

  private readonly debounced = this.queryInput
    .pipe(debounceTime(300), distinctUntilChanged(), takeUntilDestroyed())
    .subscribe((value) => this.queryChange.emit(value));

  onQueryInput(value: string): void {
    this.query.set(value);
    this.queryInput.next(value);
  }

  onFromChange(value: Date | null): void {
    this.from.set(value);
    this.emitDateRange();
  }

  onToChange(value: Date | null): void {
    this.to.set(value);
    this.emitDateRange();
  }

  clearFilters(): void {
    this.query.set('');
    this.from.set(null);
    this.to.set(null);
    this.clear.emit();
  }

  private emitDateRange(): void {
    this.dateRangeChange.emit({ from: this.from(), to: this.to() });
  }
}