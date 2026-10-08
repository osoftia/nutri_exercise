import { Component, input, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { GenericExercise } from '../../../core/models/routine-board.model';
import { CustomButton } from '../../atoms/custom-button/custom-button';
import { FormInput } from '../../atoms/form-input/form-input';

@Component({
  selector: 'app-exercise-card',
  imports: [FormsModule, CustomButton, FormInput],
  templateUrl: './exercise-card.html',
  styleUrl: './exercise-card.scss',
})
export class ExerciseCard {
  readonly exercise = input.required<GenericExercise>();
  readonly selected = input(false);
  readonly toggleSelect = output<number>();
  readonly rename = output<{ id: number; name: string }>();

  readonly editing = signal(false);
  readonly draft = signal('');

  startEdit(): void {
    this.draft.set(this.exercise().name);
    this.editing.set(true);
  }

  cancelEdit(): void {
    this.editing.set(false);
  }

  saveEdit(): void {
    const name = this.draft().trim();
    if (name && name !== this.exercise().name) {
      this.rename.emit({ id: this.exercise().id, name });
    }
    this.editing.set(false);
  }
}
