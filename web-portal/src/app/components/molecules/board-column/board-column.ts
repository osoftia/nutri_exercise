import { Component, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CdkDrag, CdkDropList, CdkDragDrop } from '@angular/cdk/drag-drop';

import { DayOfWeek, GenericExercise, RoutineColumn } from '../../../core/models/routine-board.model';
import { WEEK_DAYS } from '../../../core/utils/routine-schedule.util';
import { ExerciseCard } from '../exercise-card/exercise-card';
import { CustomButton } from '../../atoms/custom-button/custom-button';
import { FormInput } from '../../atoms/form-input/form-input';

@Component({
  selector: 'app-board-column',
  imports: [FormsModule, CdkDropList, CdkDrag, ExerciseCard, CustomButton, FormInput],
  templateUrl: './board-column.html',
  styleUrl: './board-column.scss',
})
export class BoardColumn {
  readonly column = input.required<RoutineColumn>();
  readonly exercises = input.required<GenericExercise[]>();
  readonly connectedIds = input<string[]>([]);
  readonly selectedIds = input<ReadonlySet<number>>(new Set());
  readonly drop = output<CdkDragDrop<number[]>>();
  readonly toggleSelect = output<number>();
  readonly rename = output<{ id: number; name: string }>();
  readonly duplicate = output<string>();
  readonly dayChange = output<{ id: string; day: DayOfWeek }>();
  readonly zonesChange = output<{ id: string; zones: string[] }>();

  readonly days = WEEK_DAYS;
  readonly zoneDraft = signal('');

  onDayChange(day: DayOfWeek): void {
    if (day !== this.column().dayOfWeek) this.dayChange.emit({ id: this.column().id, day });
  }

  addZone(): void {
    const zone = this.zoneDraft().trim();
    if (!zone) return;
    this.zonesChange.emit({ id: this.column().id, zones: [...this.column().bodyZones, zone] });
    this.zoneDraft.set('');
  }
}
