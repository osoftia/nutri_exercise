import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CdkDrag, CdkDragDrop, CdkDropList, CdkDropListGroup } from '@angular/cdk/drag-drop';

import { RoutineBoardStore } from '../../../core/stores/routine-board.store';
import { WEEK_DAYS } from '../../../core/utils/routine-schedule.util';
import { DayOfWeek, MuscleGroup } from '../../../core/models/routine-board.model';
import { BoardColumn } from '../../molecules/board-column/board-column';
import { CustomButton } from '../../atoms/custom-button/custom-button';
import { FormInput } from '../../atoms/form-input/form-input';

@Component({
  selector: 'app-routine-board',
  imports: [FormsModule, CdkDropListGroup, CdkDropList, CdkDrag, BoardColumn, CustomButton, FormInput],
  templateUrl: './routine-board.html',
  styleUrl: './routine-board.scss',
})
export class RoutineBoard implements OnInit {
  readonly store = inject(RoutineBoardStore);
  readonly name = signal('');
  readonly muscleGroup = signal<MuscleGroup>('Chest');
  readonly groups: MuscleGroup[] = ['Chest', 'Back', 'Legs', 'Triceps', 'Biceps', 'Core', 'Shoulders', 'Glutes'];
  readonly dayFilters: (DayOfWeek | 'All')[] = ['All', ...WEEK_DAYS];
  readonly weekDays = WEEK_DAYS;
  readonly duplicateSource = signal<string | null>(null);
  readonly duplicateTargets = signal<ReadonlySet<DayOfWeek>>(new Set());

  ngOnInit(): void {
    this.store.load();
  }

  columnIds(): string[] {
    return this.store.visibleColumns().map((c) => c.id);
  }

  onColumnDrop(event: CdkDragDrop<unknown>): void {
    this.store.reorderColumns(event.previousIndex, event.currentIndex);
  }

  onCardDrop(event: CdkDragDrop<number[]>, columnId: string): void {
    if (event.previousContainer === event.container) {
      this.store.moveWithin(columnId, event.previousIndex, event.currentIndex);
      return;
    }
    this.store.transfer(event.previousContainer.id, event.container.id, event.previousIndex, event.currentIndex);
  }

  onRename(event: { id: number; name: string }): void {
    this.store.updateExercise(event.id, { name: event.name });
  }

  onAdd(): void {
    const name = this.name().trim();
    if (!name) return;
    this.store.createExercise({ name, muscleGroup: this.muscleGroup(), sets: 3, reps: '10', restSeconds: 60 });
    this.name.set('');
  }

  openDuplicate(sourceId: string): void {
    this.duplicateSource.set(sourceId);
    this.duplicateTargets.set(new Set());
  }

  toggleTarget(day: DayOfWeek): void {
    this.duplicateTargets.update((set) => {
      const next = new Set(set);
      if (next.has(day)) next.delete(day);
      else next.add(day);
      return next;
    });
  }

  confirmDuplicate(): void {
    const source = this.duplicateSource();
    const targets = [...this.duplicateTargets()];
    if (source && targets.length) this.store.duplicateColumnToDays(source, targets);
    this.duplicateSource.set(null);
    this.duplicateTargets.set(new Set());
  }

  cancelDuplicate(): void {
    this.duplicateSource.set(null);
    this.duplicateTargets.set(new Set());
  }
}
